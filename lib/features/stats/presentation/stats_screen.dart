import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gestionbudget/features/expenses/domain/expense_model.dart';
import 'package:gestionbudget/features/goals/domain/goal_model.dart';
import 'package:gestionbudget/shared/providers/expenses_provider.dart';
import 'package:gestionbudget/shared/providers/goals_provider.dart';
import 'package:gestionbudget/shared/widgets/app_bottom_nav.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesStreamProvider);
    final goalsAsync = ref.watch(goalsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: expensesAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
          data: (expenses) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                goalsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (goals) => goals.isEmpty
                      ? const SizedBox.shrink()
                      : _ProjectsStats(goals: goals),
                ),
                StatsContent(
                  expenses: expenses,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}

class _ProjectsStats extends StatelessWidget {
  final List<Goal> goals;
  const _ProjectsStats({required this.goals});

  static final _fmt = NumberFormat.decimalPattern('fr_FR');
  static String _f(double v) => '${_fmt.format(v.toInt())} FCFA';

  @override
  Widget build(BuildContext context) {
    final totalTarget = goals.fold(0.0, (s, g) => s + g.targetAmount);
    final totalSaved = goals.fold(0.0, (s, g) => s + g.currentAmount);
    final overallPct = totalTarget > 0
        ? (totalSaved / totalTarget * 100).clamp(0.0, 100.0)
        : 0.0;
    final completed = goals.where((g) => g.progress >= 1.0).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Projets en cours',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${goals.length} projet${goals.length > 1 ? 's' : ''} · ${overallPct.toStringAsFixed(0)}% atteint',
            style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 10,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vue d\'ensemble',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatBadge(
                      label: 'Épargné',
                      value: _f(totalSaved),
                      color: const Color(0xFF66BB6A),
                    ),
                    const SizedBox(width: 10),
                    _StatBadge(
                      label: 'Objectif',
                      value: _f(totalTarget),
                      color: const Color(0xFF6C63FF),
                    ),
                    const SizedBox(width: 10),
                    _StatBadge(
                      label: 'Complétés',
                      value: '$completed / ${goals.length}',
                      color: const Color(0xFFFF7043),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: totalTarget > 0
                        ? (totalSaved / totalTarget).clamp(0.0, 1.0)
                        : 0.0,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFF3F4F6),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF6C63FF)),
                  ),
                ),
                const SizedBox(height: 20),
                ...goals.map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                    color: g.color,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(g.title,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1A1A2E))),
                              ),
                              Text(
                                '${(g.progress * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: g.color),
                              ),
                              const SizedBox(width: 8),
                              Text(_f(g.currentAmount),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9CA3AF))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: g.progress,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFF3F4F6),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(g.color),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBadge(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: color.withValues(alpha: 0.8))),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

class StatsContent extends StatelessWidget {
  final List<Expense> expenses;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const StatsContent({
    super.key,
    required this.expenses,
    this.shrinkWrap = false,
    this.physics,
  });

  static final _fmt = NumberFormat.decimalPattern('fr_FR');
  static String _f(double v) => '${_fmt.format(v.toInt())} FCFA';

  Map<ExpenseCategory, double> get _byCategory {
    final map = <ExpenseCategory, double>{};
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  Map<String, double> get _byDay {
    final now = DateTime.now();
    final map = <String, double>{};
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = DateFormat('E', 'fr_FR').format(d);
      final total = expenses.where((e) {
        return e.date.year == d.year &&
            e.date.month == d.month &&
            e.date.day == d.day;
      }).fold(0.0, (s, e) => s + e.amount);
      map[key] = total;
    }
    return map;
  }

  double get _total =>
      expenses.fold(0.0, (s, e) => s + e.amount);

  @override
  Widget build(BuildContext context) {
    final byCategory = _byCategory;
    final byDay = _byDay;
    final total = _total;
    final maxDay = byDay.values.isEmpty
        ? 1.0
        : byDay.values.reduce((a, b) => a > b ? a : b);

    return ListView(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        // ── Titre ───────────────────────────────────────────
        const Text(
          'Statistiques',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Total: ${_f(total)}',
          style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
        ),
        const SizedBox(height: 24),

        // ── Donut chart simplifié ──────────────────────────
        if (byCategory.isEmpty)
          const _EmptyCard(message: 'Aucune dépense à afficher')
        else ...[
          _Card(
            title: 'Dépenses par catégorie',
            child: Column(
              children: [
                // Donut simulé avec des arcs colorés
                SizedBox(
                  height: 160,
                  child: _DonutChart(
                    data: byCategory,
                    total: total,
                  ),
                ),
                const SizedBox(height: 20),
                // Légende
                ...byCategory.entries.map((entry) {
                  final pct = total > 0
                      ? (entry.value / total * 100)
                      : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: entry.key.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(entry.key.icon,
                            size: 16, color: entry.key.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key.displayName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _f(entry.value),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Barres 7 jours ───────────────────────────────
          _Card(
            title: 'Dépenses cette semaine',
            child: SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: byDay.entries.map((entry) {
                  final ratio =
                      maxDay > 0 ? entry.value / maxDay : 0.0;
                  return Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (entry.value > 0)
                            Text(
                              _fmt.format(entry.value.toInt()),
                              style: const TextStyle(
                                fontSize: 8,
                                color: Color(0xFF9CA3AF),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 600),
                              height: 120 * ratio,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF9C95FF),
                                    Color(0xFF6C63FF),
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Donut simplifié ─────────────────────────────────────────────
class _DonutChart extends StatelessWidget {
  final Map<ExpenseCategory, double> data;
  final double total;

  const _DonutChart({required this.data, required this.total});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DonutPainter(data: data, total: total),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Total',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
            Text(
              NumberFormat.compactCurrency(
                locale: 'fr_FR',
                symbol: '',
                decimalDigits: 0,
              ).format(total),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const Text(
              'FCFA',
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final Map<ExpenseCategory, double> data;
  final double total;

  _DonutPainter({required this.data, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 10;
    const strokeWidth = 22.0;
    const gapAngle = 0.05;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -1.57; // -π/2 (top)

    for (final entry in data.entries) {
      final sweep = (entry.value / total) * (2 * 3.14159) - gapAngle;
      paint.color = entry.key.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep.clamp(0.0, 2 * 3.14159),
        false,
        paint,
      );
      startAngle += sweep + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── Card réutilisable ───────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        ),
      ),
    );
  }
}
