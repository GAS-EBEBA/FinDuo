import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

const _kPrimary = Color(0xFF6C63FF);
const _kBg      = Color(0xFFF5F7FA);
const _kDark    = Color(0xFF0F172A);
const _kGray    = Color(0xFF94A3B8);
const _kGreen   = Color(0xFF22C55E);
const _kOrange  = Color(0xFFF97316);
const _kRed     = Color(0xFFEF4444);

// ── Provider liste des licences ────────────────────────────────
final _licensesProvider = StreamProvider<List<_LicenseData>>((ref) {
  return FirebaseFirestore.instance
      .collection('licenses')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(_LicenseData.fromDoc).toList());
});

class _LicenseData {
  final String code;
  final DateTime expiresAt;
  final bool isRevoked;
  final String? activatedBy;
  final DateTime? activatedAt;
  final DateTime createdAt;

  const _LicenseData({
    required this.code,
    required this.expiresAt,
    required this.isRevoked,
    this.activatedBy,
    this.activatedAt,
    required this.createdAt,
  });

  factory _LicenseData.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return _LicenseData(
      code:        doc.id,
      expiresAt:   (d['expiresAt'] as Timestamp).toDate(),
      isRevoked:   d['isRevoked'] as bool? ?? false,
      activatedBy: d['activatedBy'] as String?,
      activatedAt: (d['activatedAt'] as Timestamp?)?.toDate(),
      createdAt:   (d['createdAt']  as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  bool get isUnlimited => expiresAt.year >= 2090;
  bool get isExpired   => !isUnlimited && expiresAt.isBefore(DateTime.now());
  bool get isActive   => !isRevoked && !isExpired;
  bool get isUsed     => activatedBy != null;
}

// ── Écran principal ────────────────────────────────────────────
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final licensesAsync = ref.watch(_licensesProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Admin — Licences',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Générer une licence',
            onPressed: () => _showGenerateDialog(context),
          ),
        ],
      ),
      body: licensesAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: _kPrimary)),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (licenses) {
          final active  = licenses.where((l) => l.isActive).length;
          final expired = licenses.where((l) => l.isExpired && !l.isRevoked).length;
          final revoked = licenses.where((l) => l.isRevoked).length;

          return Column(
            children: [
              // ── Bandeau stats ──────────────────────────────
              Container(
                color: _kPrimary,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    _StatBadge(label: 'Actives',  value: active,  color: _kGreen),
                    const SizedBox(width: 10),
                    _StatBadge(label: 'Expirées', value: expired, color: _kOrange),
                    const SizedBox(width: 10),
                    _StatBadge(label: 'Révoquées',value: revoked, color: _kRed),
                    const Spacer(),
                    _StatBadge(label: 'Total', value: licenses.length, color: Colors.white70),
                  ],
                ),
              ),

              // ── Liste ──────────────────────────────────────
              Expanded(
                child: licenses.isEmpty
                    ? const Center(
                        child: Text('Aucune licence générée.',
                            style: TextStyle(color: _kGray)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: licenses.length,
                        itemBuilder: (ctx, i) =>
                            _LicenseTile(license: licenses[i]),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle licence',
            style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => _showGenerateDialog(context),
      ),
    );
  }

  void _showGenerateDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _GenerateDialog(),
    );
  }
}

// ── Tuile licence ──────────────────────────────────────────────
class _LicenseTile extends StatelessWidget {
  final _LicenseData license;
  const _LicenseTile({required this.license});

  static final _fmt = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String statusLabel;
    if (license.isRevoked) {
      statusColor = _kRed;
      statusLabel = 'Révoquée';
    } else if (license.isExpired) {
      statusColor = _kOrange;
      statusLabel = 'Expirée';
    } else {
      statusColor = _kGreen;
      statusLabel = 'Active';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Code + status
            Row(
              children: [
                Expanded(
                  child: Text(
                    license.code,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _kDark,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Détails
            Row(
              children: [
                _InfoChip(
                  icon: license.expiresAt.year >= 2090
                      ? Icons.all_inclusive_rounded
                      : Icons.calendar_today_rounded,
                  text: license.expiresAt.year >= 2090
                      ? 'Illimitée'
                      : 'Expire le ${_fmt.format(license.expiresAt)}',
                  color: license.expiresAt.year >= 2090 ? _kPrimary : _kGray,
                ),
                const SizedBox(width: 10),
                _InfoChip(
                  icon: license.isUsed
                      ? Icons.person_rounded
                      : Icons.person_outline_rounded,
                  text: license.isUsed ? 'Utilisée' : 'Disponible',
                  color: license.isUsed ? _kPrimary : _kGray,
                ),
              ],
            ),

            // Actions
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Copier
                _ActionButton(
                  icon: Icons.copy_rounded,
                  label: 'Copier',
                  color: _kPrimary,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: license.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copié !'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // Révoquer / Réactiver
                if (!license.isExpired)
                  _ActionButton(
                    icon: license.isRevoked
                        ? Icons.check_circle_outline_rounded
                        : Icons.block_rounded,
                    label: license.isRevoked ? 'Réactiver' : 'Révoquer',
                    color: license.isRevoked ? _kGreen : _kRed,
                    onTap: () => _toggleRevoke(context, license),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleRevoke(
      BuildContext context, _LicenseData license) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(license.isRevoked ? 'Réactiver la licence ?' : 'Révoquer la licence ?'),
        content: Text(
          license.isRevoked
              ? 'Le couple pourra de nouveau accéder à l\'application.'
              : 'Le couple sera immédiatement bloqué.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: _kGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: license.isRevoked ? _kGreen : _kRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(license.isRevoked ? 'Réactiver' : 'Révoquer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('licenses')
          .doc(license.code)
          .update({'isRevoked': !license.isRevoked});
    }
  }
}

// ── Dialog génération ──────────────────────────────────────────
class _GenerateDialog extends StatefulWidget {
  const _GenerateDialog();

  @override
  State<_GenerateDialog> createState() => _GenerateDialogState();
}

class _GenerateDialogState extends State<_GenerateDialog> {
  int _months = 1;
  bool _generating = false;
  String? _generatedCode;

  static const _durations = [
    (label: '1 mois',    months: 1),
    (label: '3 mois',    months: 3),
    (label: '6 mois',    months: 6),
    (label: '1 an',      months: 12),
    (label: '2 ans',     months: 24),
    (label: 'Illimitée', months: -1),
  ];

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    String block() =>
        List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
    return 'FINDUO-${block()}-${block()}-${block()}';
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    final code = _generateCode();
    final now  = DateTime.now();
    final exp  = _months == -1
        ? DateTime(2099, 12, 31)
        : DateTime(now.year, now.month + _months, now.day);

    await FirebaseFirestore.instance.collection('licenses').doc(code).set({
      'expiresAt':      Timestamp.fromDate(exp),
      'isRevoked':      false,
      'activatedBy':    null,
      'activatedAt':    null,
      'createdAt':      FieldValue.serverTimestamp(),
      'durationMonths': _months,
    });

    setState(() { _generatedCode = code; _generating = false; });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();
    final isUnlimited = _months == -1;
    final exp = isUnlimited
        ? DateTime(2099, 12, 31)
        : DateTime(now.year, now.month + _months, now.day);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Nouvelle licence',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      content: SizedBox(
        width: 320,
        child: _generatedCode == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Durée de validité',
                      style: TextStyle(fontSize: 13, color: _kGray)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _durations.map((d) {
                      final selected = d.months == _months;
                      return GestureDetector(
                        onTap: () => setState(() => _months = d.months),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? _kPrimary
                                : _kPrimary.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            d.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : _kPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_rounded,
                            size: 16, color: _kGray),
                        const SizedBox(width: 8),
                        Text(
                          isUnlimited
                              ? '∞  N\'expire jamais'
                              : 'Expire le ${fmt.format(exp)}',
                          style: const TextStyle(
                              fontSize: 13, color: _kDark),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: _kGreen, size: 48),
                  const SizedBox(height: 12),
                  const Text('Licence créée !',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: _kDark)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: .06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _kPrimary.withValues(alpha: .2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _generatedCode!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _kPrimary,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded,
                              color: _kPrimary, size: 20),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: _generatedCode!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Code copié !'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isUnlimited ? '∞  N\'expire jamais' : 'Expire le ${fmt.format(exp)}',
                    style: const TextStyle(fontSize: 12, color: _kGray),
                  ),
                ],
              ),
      ),
      actions: _generatedCode == null
          ? [
              TextButton(
                onPressed: _generating
                    ? null
                    : () => Navigator.pop(context),
                child: const Text('Annuler',
                    style: TextStyle(color: _kGray)),
              ),
              ElevatedButton(
                onPressed: _generating ? null : _generate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _generating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Générer',
                        style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]
          : [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Fermer',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
    );
  }
}

// ── Widgets utilitaires ────────────────────────────────────────
class _StatBadge extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatBadge(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoChip(
      {required this.icon,
      required this.text,
      this.color = _kGray});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(text,
            style:
                TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }
}
