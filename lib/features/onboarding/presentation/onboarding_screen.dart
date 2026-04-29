import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestionbudget/features/onboarding/data/couple_service.dart';
import 'package:gestionbudget/shared/providers/couple_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _isLoading = false;
  bool _isJoining = false;
  String? _errorMessage;
  String? _generatedCode;

  final _codeController = TextEditingController();
  final _nameController = TextEditingController();

  static const _kPrimary = Color(0xFF6C63FF);

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createCouple() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Entre ton prénom');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final code = await ref.read(coupleServiceProvider).createCouple(
            userId: user.uid,
            displayName: name,
          );
      setState(() {
        _generatedCode = code;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _joinCouple() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Entre ton prénom');
      return;
    }
    if (code.length != 6) {
      setState(() => _errorMessage = 'Le code doit avoir 6 caractères');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await ref.read(coupleServiceProvider).joinCouple(
            code: code,
            userId: user.uid,
            displayName: name,
          );
      ref.invalidate(coupleFutureProvider);
      if (mounted) context.go('/dashboard');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_generatedCode != null) return _buildShareCodeScreen();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text('💑', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 24),
              Text(
                'Configurer votre couple',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lie ton compte à celui de ton/ta partenaire\npour partager vos dépenses',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5),
              ),
              const SizedBox(height: 36),
              _buildTextField(
                controller: _nameController,
                label: 'Ton prénom',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _ToggleButton(
                      label: 'Créer un couple',
                      icon: Icons.add_circle_outline,
                      selected: !_isJoining,
                      onTap: () => setState(() {
                        _isJoining = false;
                        _errorMessage = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ToggleButton(
                      label: 'Rejoindre',
                      icon: Icons.link,
                      selected: _isJoining,
                      onTap: () => setState(() {
                        _isJoining = true;
                        _errorMessage = null;
                      }),
                    ),
                  ),
                ],
              ),
              if (_isJoining) ...[
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _codeController,
                  label: "Code d'invitation (6 caractères)",
                  icon: Icons.vpn_key_outlined,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEBEB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                        color: Color(0xFFE24B4A), fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      _isLoading ? null : (_isJoining ? _joinCouple : _createCouple),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    disabledBackgroundColor: _kPrimary.withValues(alpha: 0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isJoining ? 'Rejoindre' : 'Créer le couple',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareCodeScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 24),
              Text(
                'Couple créé !',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900]),
              ),
              const SizedBox(height: 8),
              Text(
                'Partage ce code avec ton/ta partenaire\npour lier vos comptes',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5),
              ),
              const SizedBox(height: 40),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEDFE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _generatedCode!,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6C63FF),
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Color(0xFF6C63FF)),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: _generatedCode!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copié !')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ce code expire une fois utilisé par ton/ta partenaire',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    ref.invalidate(coupleFutureProvider);
                    context.go('/dashboard');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Continuer vers le tableau de bord',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  ref.invalidate(coupleFutureProvider);
                  context.go('/dashboard');
                },
                child: Text(
                  "En attendre que mon/ma partenaire se connecte",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[50],
        counterText: '',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEEDFE) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF6C63FF) : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? const Color(0xFF6C63FF) : Colors.grey[400],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                    ? const Color(0xFF6C63FF)
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
