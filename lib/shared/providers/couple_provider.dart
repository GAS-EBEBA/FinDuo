import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestionbudget/features/auth/data/auth_service.dart';

/// coupleId de l'utilisateur connecté (chargé une seule fois).
/// Tente d'abord le serveur, puis le cache local si hors ligne.
final coupleFutureProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return null;

  final userRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid);

  try {
    final doc = await userRef.get();
    return doc.data()?['coupleId'] as String?;
  } catch (_) {
    // Hors ligne ou réseau indisponible : lecture depuis le cache uniquement
    try {
      final doc = await userRef.get(const GetOptions(source: Source.cache));
      return doc.data()?['coupleId'] as String?;
    } catch (_) {
      return null;
    }
  }
});

/// Nom du partenaire, récupéré en temps réel depuis Firestore.
final partnerNameProvider = StreamProvider<String?>((ref) {
  final coupleId   = ref.watch(coupleFutureProvider).asData?.value;
  final currentUid = ref.watch(coupleProvider.select((s) => s.userId));
  if (coupleId == null || currentUid == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('couples')
      .doc(coupleId)
      .snapshots()
      .asyncMap((coupleDoc) async {
        final data = coupleDoc.data();
        if (data == null) return null;
        final creatorId  = data['creatorId'] as String?;
        final partnerId  = data['partnerId'] as String?;
        final partnerUid = creatorId == currentUid ? partnerId : creatorId;
        if (partnerUid == null) return null;
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(partnerUid)
            .get();
        return userDoc.data()?['displayName'] as String?;
      });
});

/// Budget mensuel du couple, en temps réel depuis Firestore.
final budgetStreamProvider = StreamProvider<double>((ref) {
  final coupleId = ref.watch(coupleFutureProvider).asData?.value;
  if (coupleId == null) return Stream.value(0.0);

  return FirebaseFirestore.instance
      .collection('couples')
      .doc(coupleId)
      .snapshots()
      .map((doc) => (doc.data()?['budget'] as num?)?.toDouble() ?? 0.0);
});

/// Met à jour le budget mensuel dans Firestore.
Future<void> updateBudget(String coupleId, double amount) =>
    FirebaseFirestore.instance
        .collection('couples')
        .doc(coupleId)
        .update({'budget': amount});

final coupleProvider = NotifierProvider<CoupleNotifier, CoupleState>(
  CoupleNotifier.new,
);

class CoupleState {
  final String? userId;
  final String? partnerId;
  final String? userName;
  final String? partnerName;

  const CoupleState({
    this.userId,
    this.partnerId,
    this.userName,
    this.partnerName,
  });

  CoupleState copyWith({
    String? userId,
    String? partnerId,
    String? userName,
    String? partnerName,
  }) {
    return CoupleState(
      userId: userId ?? this.userId,
      partnerId: partnerId ?? this.partnerId,
      userName: userName ?? this.userName,
      partnerName: partnerName ?? this.partnerName,
    );
  }
}

class CoupleNotifier extends Notifier<CoupleState> {
  @override
  CoupleState build() {
    final sub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
    ref.onDispose(sub.cancel);

    // Recharge le nom et le partenaire quand coupleId change (ex: après onboarding)
    ref.listen(coupleFutureProvider, (previous, next) {
      next.whenData((coupleId) {
        if (coupleId != null && state.userId != null) {
          _loadUserName(state.userId!);
          _loadPartner(coupleId, state.userId!);
        }
      });
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Charge le nom depuis Firestore plutôt que depuis Auth
      _loadUserName(user.uid);
      return CoupleState(
        userId: user.uid,
        userName: user.displayName ?? user.email?.split('@').first ?? 'Moi',
      );
    }
    return const CoupleState();
  }

  void _onAuthChanged(User? user) {
    if (user == null) {
      state = const CoupleState();
    } else {
      state = CoupleState(
        userId: user.uid,
        userName: user.displayName ?? user.email?.split('@').first ?? 'Moi',
      );
      // Charge le nom et le partenaire quand l'utilisateur change
      _loadUserName(user.uid);
      _loadPartnerForUser(user.uid);
    }
  }

  Future<void> _loadUserName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final userData = userDoc.data();
      if (userData == null) return;
      
      // Récupère le displayName ou utilise un fallback
      String displayName = (userData['displayName'] as String?)?.trim() ?? '';
      if (displayName.isEmpty) {
        // Fallback à l'email
        final email = userData['email'] as String?;
        displayName = email?.split('@').first ?? 'Moi';
      }
      
      if (displayName.isNotEmpty) {
        state = state.copyWith(userName: displayName);
      }
    } catch (_) {}
  }

  Future<void> _loadPartnerForUser(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final coupleId = userDoc.data()?['coupleId'] as String?;
      if (coupleId != null) {
        await _loadPartner(coupleId, userId);
      }
    } catch (_) {}
  }

  Future<void> _loadPartner(String coupleId, String currentUserId) async {
    try {
      final coupleDoc = await FirebaseFirestore.instance
          .collection('couples')
          .doc(coupleId)
          .get();
      final data = coupleDoc.data();
      if (data == null) return;

      final creatorId = data['creatorId'] as String?;
      final partnerId = data['partnerId'] as String?;

      // Détermine qui est le partenaire
      final partnerUid = creatorId == currentUserId ? partnerId : creatorId;
      if (partnerUid == null) return;

      // Charge le nom du partenaire
      final partnerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(partnerUid)
          .get();
      
      final partnerData = partnerDoc.data();
      if (partnerData == null) return;
      
      // Récupère le displayName ou utilise un fallback
      String partnerName = (partnerData['displayName'] as String?)?.trim() ?? '';
      if (partnerName.isEmpty) {
        // Fallback à l'email
        final email = partnerData['email'] as String?;
        partnerName = email?.split('@').first ?? 'Partenaire';
      }

      state = state.copyWith(partnerId: partnerUid, partnerName: partnerName);
    } catch (_) {}
  }

  void setPartner(String partnerId, String partnerName) {
    state = state.copyWith(partnerId: partnerId, partnerName: partnerName);
  }
}
