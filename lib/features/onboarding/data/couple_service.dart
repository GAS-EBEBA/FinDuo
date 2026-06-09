import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final coupleServiceProvider = Provider<CoupleService>((ref) => CoupleService());

class CoupleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Caractères sans ambiguïté (pas de 0/O, 1/I)
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _generateCode() {
    final rand = Random.secure();
    return List.generate(6, (_) => _chars[rand.nextInt(_chars.length)]).join();
  }

  /// Crée un nouveau couple et retourne le code d'invitation.
  Future<String> createCouple({
    required String userId,
    required String displayName,
  }) async {
    final code = _generateCode();
    final coupleRef = _db.collection('couples').doc();

    await _db.runTransaction((tx) async {
      tx.set(coupleRef, {
        'creatorId': userId,
        'partnerId': null,
        'inviteCode': code,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.set(
        _db.collection('users').doc(userId),
        {'coupleId': coupleRef.id, 'displayName': displayName},
        SetOptions(merge: true),
      );
    });

    return code;
  }

  /// Rejoint un couple existant via le code d'invitation.
  Future<void> joinCouple({
    required String code,
    required String userId,
    required String displayName,
  }) async {
    final query = await _db
        .collection('couples')
        .where('inviteCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Code invalide.');
    }

    final coupleDoc = query.docs.first;
    if (coupleDoc['partnerId'] != null) {
      throw Exception('Ce code a déjà été utilisé.');
    }
    if (coupleDoc['creatorId'] == userId) {
      throw Exception('Tu ne peux pas rejoindre ton propre couple.');
    }

    await _db.runTransaction((tx) async {
      tx.update(coupleDoc.reference, {'partnerId': userId});
      tx.set(
        _db.collection('users').doc(userId),
        {'coupleId': coupleDoc.id, 'displayName': displayName},
        SetOptions(merge: true),
      );
    });
  }

  /// Crée un espace solo et assigne un coupleId à l'utilisateur.
  Future<void> setupSolo({
    required String userId,
    required String displayName,
  }) async {
    final spaceRef = _db.collection('couples').doc();

    await _db.runTransaction((tx) async {
      tx.set(spaceRef, {
        'creatorId': userId,
        'partnerId': null,
        'mode': 'solo',
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.set(
        _db.collection('users').doc(userId),
        {'coupleId': spaceRef.id, 'displayName': displayName, 'mode': 'solo'},
        SetOptions(merge: true),
      );
    });
  }

  /// Retourne le coupleId de l'utilisateur, ou null si pas encore lié.
  Future<String?> getCoupleId(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data()?['coupleId'] as String?;
  }
}
