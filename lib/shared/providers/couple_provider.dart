import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestionbudget/features/auth/data/auth_service.dart';

/// coupleId de l'utilisateur connecté (chargé une seule fois).
final coupleFutureProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return null;
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  return doc.data()?['coupleId'] as String?;
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

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
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
    }
  }

  void setPartner(String partnerId, String partnerName) {
    state = state.copyWith(partnerId: partnerId, partnerName: partnerName);
  }
}
