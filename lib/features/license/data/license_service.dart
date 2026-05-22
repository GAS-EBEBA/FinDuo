import 'package:cloud_firestore/cloud_firestore.dart';

class LicenseService {
  final _db = FirebaseFirestore.instance;

  /// Vérifie et active un code de licence pour un couple.
  /// Retourne null si succès, sinon un message d'erreur.
  Future<String?> activateLicense({
    required String code,
    required String coupleId,
  }) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return 'Veuillez saisir un code de licence.';

    final licDoc = await _db.collection('licenses').doc(normalized).get();

    if (!licDoc.exists) return 'Code invalide. Vérifiez et réessayez.';

    final data = licDoc.data()!;

    final isRevoked = data['isRevoked'] as bool? ?? false;
    if (isRevoked) return 'Cette licence a été révoquée.';

    final expiresAt = data['expiresAt'] as Timestamp?;
    if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
      return 'Cette licence est expirée.';
    }

    final activatedBy = data['activatedBy'] as String?;
    if (activatedBy != null && activatedBy != coupleId) {
      return 'Ce code est déjà utilisé par un autre couple.';
    }

    // Activation : enregistre sur la licence et sur le couple
    final batch = _db.batch();

    batch.update(licDoc.reference, {
      'activatedBy': coupleId,
      'activatedAt': FieldValue.serverTimestamp(),
    });

    batch.update(_db.collection('couples').doc(coupleId), {
      'licenseCode':      normalized,
      'licenseExpiresAt': expiresAt,
    });

    await batch.commit();
    return null;
  }

  /// Retourne true si le couple a une licence valide et non expirée.
  Future<bool> hasValidLicense(String coupleId) async {
    final doc = await _db.collection('couples').doc(coupleId).get();
    final data = doc.data();
    if (data == null) return false;
    final expiresAt = data['licenseExpiresAt'] as Timestamp?;
    if (expiresAt == null) return false;
    return expiresAt.toDate().isAfter(DateTime.now());
  }
}
