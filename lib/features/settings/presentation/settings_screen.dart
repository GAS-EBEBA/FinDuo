import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestionbudget/features/auth/data/auth_service.dart';
import 'package:gestionbudget/shared/providers/couple_provider.dart';
import 'package:gestionbudget/shared/widgets/app_bottom_nav.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _danger = Color(0xFFEF5350);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couple = ref.watch(coupleProvider);
    final userName = couple.userName ?? 'Moi';
    final partnerName = couple.partnerName;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            // ── Titre ─────────────────────────────────────────
            const Text(
              'Paramètres',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 24),

            // ── Carte couple ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6C63FF), Color(0xFF9C95FF)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _ProfileAvatar(
                    initial: userName[0].toUpperCase(),
                    name: userName,
                    label: 'Moi',
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 1,
                    height: 56,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 16),
                  _ProfileAvatar(
                    initial: partnerName != null
                        ? partnerName[0].toUpperCase()
                        : '?',
                    name: partnerName ?? 'En attente…',
                    label: 'Partenaire',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Section Préférences ───────────────────────────
            _SectionLabel(label: 'Préférences'),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.currency_exchange_rounded,
                  iconColor: const Color(0xFF42A5F5),
                  title: 'Devise',
                  trailing: const Text(
                    'FCFA',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  onTap: () {},
                ),
                const _Divider(),
                _SwitchTile(
                  icon: Icons.notifications_rounded,
                  iconColor: const Color(0xFFFF7043),
                  title: 'Notifications',
                  value: true,
                  onChanged: (_) {},
                ),
                const _Divider(),
                _SwitchTile(
                  icon: Icons.dark_mode_rounded,
                  iconColor: const Color(0xFF78909C),
                  title: 'Mode sombre',
                  value: false,
                  onChanged: (_) {},
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Section Compte ────────────────────────────────
            _SectionLabel(label: 'Compte'),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.security_rounded,
                  iconColor: const Color(0xFF66BB6A),
                  title: 'Sécurité',
                  onTap: () {},
                ),
                const _Divider(),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xFFAB47BC),
                  title: 'À propos',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Déconnexion ───────────────────────────────────
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  iconColor: _danger,
                  title: 'Se déconnecter',
                  titleColor: _danger,
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        title: const Text('Se déconnecter ?'),
                        content: const Text(
                          'Tu devras te reconnecter pour accéder à l\'application.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              'Déconnexion',
                              style: TextStyle(color: _danger),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref.read(authServiceProvider).signOut();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}

// ── Widgets internes ────────────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  final String initial;
  final String name;
  final String label;

  const _ProfileAvatar({
    required this.initial,
    required this.name,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 11,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF9CA3AF),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: titleColor ?? const Color(0xFF1A1A2E),
                ),
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFD1D5DB),
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF6C63FF),
            activeTrackColor: const Color(0xFF6C63FF).withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 66,
      endIndent: 0,
      color: Color(0xFFF3F4F6),
    );
  }
}
