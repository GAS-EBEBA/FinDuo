import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestionbudget/features/auth/data/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isCreatingAccount = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  static const _kPrimary = Color(0xFF6C63FF);
  static const _kError = Color(0xFFE24B4A);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    _clearError();
    setState(() => _isLoading = true);

    try {
      final service = ref.read(authServiceProvider);
      if (_isCreatingAccount) {
        await service.createAccount(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await service.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      // Le routeur gère la navigation selon l'état auth + couple
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyFirebaseError(e.code));
    } catch (e) {
      _setError('Erreur réseau ou configuration : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearError() => setState(() => _errorMessage = null);
  void _setError(String msg) {
    if (mounted) setState(() => _errorMessage = msg);
  }

  String _friendlyFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun compte trouvé pour cet email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'weak-password':
        return 'Mot de passe trop faible (6 caractères min).';
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessaie plus tard.';
      case 'network-request-failed':
        return 'Vérifie ta connexion internet.';
      default:
        return 'Erreur Firebase ($code) — vérifie que Email/Mot de passe est activé dans la console Firebase.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const _AppLogo(),
                    const SizedBox(height: 24),
                    _buildHeadline(),
                    const SizedBox(height: 48),
                    _InputField(
                      controller: _emailController,
                      label: 'Adresse email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email requis';
                        if (!v.contains('@')) return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _InputField(
                      controller: _passwordController,
                      label: 'Mot de passe',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 18,
                          color: Colors.grey[400],
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Mot de passe requis';
                        if (_isCreatingAccount && v.length < 6) {
                          return '6 caractères minimum';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleEmailAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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
                                _isCreatingAccount
                                    ? 'Créer le compte'
                                    : 'Se connecter',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => setState(() {
                        _isCreatingAccount = !_isCreatingAccount;
                        _clearError();
                      }),
                      child: Text(
                        _isCreatingAccount
                            ? 'Déjà un compte ? Se connecter'
                            : "Pas encore de compte ? Créer un compte",
                        style: const TextStyle(
                          fontSize: 13,
                          color: _kPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorBanner(_errorMessage!),
                    ],
                    const SizedBox(height: 32),
                    Text(
                      "En continuant, tu acceptes les\nconditions d'utilisation",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[400], height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeadline() {
    return Column(
      children: [
        Text(
          'Notre Budget',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.grey[900],
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Gérez vos dépenses à deux\nen toute simplicité',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.grey[500], height: 1.5),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kError.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: _kError),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  fontSize: 13, color: _kError, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Widgets réutilisables
// ─────────────────────────────────────────────

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF9C95FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.account_balance_wallet_rounded,
          color: Colors.white,
          size: 38,
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[50],
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE24B4A)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFE24B4A), width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 12),
      ),
    );
  }
}
