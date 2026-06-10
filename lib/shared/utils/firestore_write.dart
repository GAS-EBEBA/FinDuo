import 'dart:async';

/// Exécute une écriture Firestore en mode optimiste.
/// - Hors ligne (isOnline = false) : Firestore commite localement de façon
///   synchrone — on ne bloque pas en attendant le serveur (fire-and-forget).
/// - En ligne : attend la confirmation serveur avec un timeout de sécurité.
Future<void> guardedWrite(bool isOnline, Future<void> Function() write) async {
  if (!isOnline) {
    write(); // Commit local immédiat garanti par la persistance Firestore
    return;
  }
  try {
    await write().timeout(const Duration(seconds: 20));
  } on TimeoutException {
    // Réseau lent mais commit local déjà effectué — pas d'erreur à remonter
  }
}
