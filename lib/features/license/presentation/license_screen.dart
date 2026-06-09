import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestionbudget/features/license/providers/license_provider.dart';

class LicenseScreen extends ConsumerStatefulWidget {
  const LicenseScreen({super.key});

  @override
  ConsumerState<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends ConsumerState<LicenseScreen> {
  final _controller = TextEditingController();
  String? _errorMessage;
  bool _loading = false;

  static const _kPrimary = Color(0xFF6C63FF);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Veuillez saisir votre code de licence.');
      return;
    }
    if (code.length != 21 || !code.startsWith('FINDUO-')) {
      setState(() => _errorMessage = 'Format invalide. Exemple : FINDUO-XXXX-XXXX-XXXX');
      return;
    }
    setState(() { _loading = true; _errorMessage = null; });

    final error = await ref
        .read(licenseActivationProvider.notifier)
        .activate(code);

    if (mounted) {
      setState(() {
        _loading = false;
        _errorMessage = error;
      });
    }
    // Si error == null le router redirige automatiquement
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              // ── Logo ────────────────────────────────────────
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withValues(alpha: .25),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/images/finduo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Titre ───────────────────────────────────────
              const Text(
                'Activer FinDuo',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Entrez votre code de licence pour\naccéder à l\'application.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 48),

              // ── Champ code ──────────────────────────────────
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                inputFormatters: [_LicenseFormatter()],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'FINDUO-XXXX-XXXX-XXXX',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    letterSpacing: 3,
                    color: const Color(0xFF94A3B8).withValues(alpha: .6),
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: _kPrimary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                        color: Color(0xFFEF4444), width: 1.5),
                  ),
                ),
                onSubmitted: (_) => _activate(),
              ),

              // ── Message d'erreur ────────────────────────────
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: .3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Bouton activer ──────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _activate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    disabledBackgroundColor:
                        _kPrimary.withValues(alpha: .5),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(
                          'Activer la licence',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),

              const SizedBox(height: 40),

              // ── Info bas ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: _kPrimary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'La licence est partagée avec votre partenaire. '
                        'Un seul code suffit pour le couple.',
                        style: TextStyle(
                          fontSize: 12,
                          color: _kPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LicenseFormatter extends TextInputFormatter {
  static const _prefix = 'FINDUO-';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Extrait uniquement la partie alphanumérique tapée par l'utilisateur
    String raw = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    // Supprime le préfixe FINDUO s'il a été saisi manuellement
    if (raw.startsWith('FINDUO')) raw = raw.substring(6);

    // Limite à 12 caractères (la partie variable : 3 × 4)
    if (raw.length > 12) raw = raw.substring(0, 12);

    if (raw.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Construit FINDUO-XXXX-XXXX-XXXX
    final buf = StringBuffer(_prefix);
    for (int i = 0; i < raw.length; i++) {
      if (i == 4 || i == 8) buf.write('-');
      buf.write(raw[i]);
    }

    final result = buf.toString();
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
