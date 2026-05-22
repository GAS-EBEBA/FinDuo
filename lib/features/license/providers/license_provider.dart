import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestionbudget/features/license/data/license_service.dart';
import 'package:gestionbudget/shared/providers/couple_provider.dart';

final licenseServiceProvider = Provider((_) => LicenseService());

/// Stream qui émet true si le couple a une licence active, false sinon.
final licenseStreamProvider = StreamProvider<bool>((ref) {
  final coupleId = ref.watch(coupleFutureProvider).asData?.value;
  if (coupleId == null) return Stream.value(false);

  return FirebaseFirestore.instance
      .collection('couples')
      .doc(coupleId)
      .snapshots()
      .map((doc) {
        final data = doc.data();
        if (data == null) return false;
        final expiresAt = data['licenseExpiresAt'] as Timestamp?;
        if (expiresAt == null) return false;
        return expiresAt.toDate().isAfter(DateTime.now());
      });
});

/// Notifier pour l'activation d'une licence (saisie du code).
final licenseActivationProvider =
    AsyncNotifierProvider<LicenseActivationNotifier, void>(
        LicenseActivationNotifier.new);

class LicenseActivationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String?> activate(String code) async {
    final coupleId = ref.read(coupleFutureProvider).asData?.value;
    if (coupleId == null) return 'Couple introuvable.';
    state = const AsyncValue.loading();
    String? error;
    state = await AsyncValue.guard(() async {
      error = await ref
          .read(licenseServiceProvider)
          .activateLicense(code: code, coupleId: coupleId);
      if (error != null) throw Exception(error);
    });
    return error;
  }
}
