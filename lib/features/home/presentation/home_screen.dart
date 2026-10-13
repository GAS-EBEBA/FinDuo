import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gestionbudget/features/auth/data/auth_service.dart';
import 'package:gestionbudget/shared/providers/couple_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _purple = Color(0xFF6C63FF);
  static const _ink = Color(0xFF172033);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(coupleProvider).userName?.trim();
    final firstName = name == null || name.isEmpty ? 'à vous' : name;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _purple.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: _purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'FinDuo',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.4,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Se déconnecter',
                        onPressed:
                            () => ref.read(authServiceProvider).signOut(),
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFF7E8798),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'Bonjour $firstName 👋',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.7,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Qu’aimeriez-vous prendre en main aujourd’hui ?',
                    style: TextStyle(
                      color: Color(0xFF778196),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 26),
                  _ChoiceCard(
                    eyebrow: 'FINANCES',
                    title: 'Organiser mon budget',
                    description:
                        'Suivez vos dépenses, votre budget et vos projets.',
                    icon: Icons.account_balance_wallet_rounded,
                    colors: const [Color(0xFF6558E8), Color(0xFF8978FF)],
                    onTap: () => context.go('/dashboard'),
                  ),
                  const SizedBox(height: 16),
                  _ChoiceCard(
                    eyebrow: 'BIEN-ÊTRE',
                    title: 'Me mettre en forme',
                    description:
                        'Bougez à votre rythme avec des exercices animés.',
                    icon: Icons.fitness_center_rounded,
                    colors: const [Color(0xFF0E9F87), Color(0xFF35C9A5)],
                    onTap: () => context.go('/fitness'),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE9ECF4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFFFF7B83),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'De petits pas réguliers peuvent faire une grande différence.',
                            style: TextStyle(
                              color: Color(0xFF697386),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: .22),
                blurRadius: 20,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 23),
              Text(
                eyebrow,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .78),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.3,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .88),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
