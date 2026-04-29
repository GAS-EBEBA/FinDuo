import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gestionbudget/features/expenses/domain/expense_model.dart';
import 'package:gestionbudget/features/goals/domain/goal_model.dart';
import 'package:gestionbudget/features/goals/domain/planned_expense_model.dart';
import 'package:gestionbudget/features/stats/presentation/stats_screen.dart';
import 'package:gestionbudget/shared/providers/couple_provider.dart';
import 'package:gestionbudget/shared/providers/expenses_provider.dart';
import 'package:gestionbudget/shared/providers/goals_provider.dart';
import 'package:gestionbudget/shared/widgets/app_bottom_nav.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  static const _primary = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coupleId = ref.watch(coupleFutureProvider).asData?.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Planification',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: _primary,
              unselectedLabelColor: const Color(0xFF9CA3AF),
              indicatorColor: _primary,
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              tabs: const [
                Tab(text: 'Projets'),
                Tab(text: 'Planifiées'),
                Tab(text: 'Statistiques'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GoalsTab(coupleId: coupleId),
          _PlannedTab(coupleId: coupleId),
          const _StatsTab(),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}

// ── Onglet Projets ─────────────────────────────────────────────

class _GoalsTab extends ConsumerWidget {
  final String? coupleId;
  const _GoalsTab({required this.coupleId});

  static const _primary = Color(0xFF6C63FF);
  static final _fmt = NumberFormat.decimalPattern('fr_FR');
  static String _f(double v) => '${_fmt.format(v.toInt())} FCFA';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsStreamProvider);

    return goalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (goals) => Stack(
        children: [
          goals.isEmpty
              ? const _EmptyState(
                  icon: Icons.flag_rounded,
                  title: 'Aucun projet',
                  subtitle:
                      'Crée votre premier projet\net commencez à épargner !',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  children: [
                    _SummaryCard(
                      leftLabel: 'Épargné',
                      leftValue: _f(goals.fold(0.0, (s, g) => s + g.currentAmount)),
                      centerLabel: 'Objectif total',
                      centerValue: _f(goals.fold(0.0, (s, g) => s + g.targetAmount)),
                      rightLabel: 'Restant',
                      rightValue: _f(goals
                          .fold(0.0, (s, g) => s + g.remaining)
                          .clamp(0, double.infinity)),
                    ),
                    const SizedBox(height: 16),
                    ...goals.map((g) => _GoalCard(
                          goal: g,
                          onAddFunds: () => showDialog<void>(
                            context: context,
                            builder: (_) => _AddFundsDialog(goal: g),
                          ),
                          onDelete: () => ref
                              .read(goalsProvider.notifier)
                              .deleteGoal(g.id),
                        )),
                  ],
                ),
          Positioned(
            bottom: 16,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: coupleId == null
                  ? null
                  : () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            _AddGoalDialog(coupleId: coupleId!),
                      ),
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouveau projet',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Onglet Planifiées ──────────────────────────────────────────

class _PlannedTab extends ConsumerWidget {
  final String? coupleId;
  const _PlannedTab({required this.coupleId});

  static const _primary = Color(0xFF6C63FF);
  static final _fmt = NumberFormat.decimalPattern('fr_FR');
  static String _f(double v) => '${_fmt.format(v.toInt())} FCFA';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannedAsync = ref.watch(plannedExpensesStreamProvider);

    return plannedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (planned) => Stack(
        children: [
          planned.isEmpty
              ? const _EmptyState(
                  icon: Icons.calendar_today_rounded,
                  title: 'Aucune dépense planifiée',
                  subtitle:
                      'Planifiez vos dépenses à venir\npour mieux anticiper.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  children: [
                    _SummaryCard(
                      leftLabel: 'Planifiées',
                      leftValue: '${planned.length}',
                      centerLabel: 'Total prévu',
                      centerValue: _f(
                          planned.fold(0.0, (s, e) => s + e.amount)),
                      rightLabel: 'Prochaine',
                      rightValue: planned.isNotEmpty
                          ? DateFormat('d MMM', 'fr_FR')
                              .format(planned.first.plannedDate)
                          : '--',
                    ),
                    const SizedBox(height: 16),
                    ...planned.map((p) => _PlannedCard(
                          expense: p,
                          onDelete: () => ref
                              .read(plannedExpensesProvider.notifier)
                              .delete(p.id),
                        )),
                  ],
                ),
          Positioned(
            bottom: 16,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: coupleId == null
                  ? null
                  : () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            _AddPlannedExpenseDialog(coupleId: coupleId!),
                      ),
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Planifier',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carte récap ────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String leftLabel, leftValue;
  final String centerLabel, centerValue;
  final String rightLabel, rightValue;

  const _SummaryCard({
    required this.leftLabel,
    required this.leftValue,
    required this.centerLabel,
    required this.centerValue,
    required this.rightLabel,
    required this.rightValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9C95FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _SummaryItem(label: leftLabel, value: leftValue)),
          Container(
              width: 1,
              height: 36,
              color: Colors.white.withValues(alpha: 0.3)),
          Expanded(
              child:
                  _SummaryItem(label: centerLabel, value: centerValue)),
          Container(
              width: 1,
              height: 36,
              color: Colors.white.withValues(alpha: 0.3)),
          Expanded(
              child: _SummaryItem(label: rightLabel, value: rightValue)),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label, value;
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8))),
        const SizedBox(height: 4),
        Text(value,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ],
    );
  }
}

// ── Carte projet ───────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onAddFunds;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.onAddFunds,
    required this.onDelete,
  });

  static final _fmt = NumberFormat.decimalPattern('fr_FR');
  static String _f(double v) => '${_fmt.format(v.toInt())} FCFA';

  @override
  Widget build(BuildContext context) {
    final daysLeft = goal.targetDate
        ?.difference(DateTime.now())
        .inDays;

    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF5350),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child:
            const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: goal.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.flag_rounded,
                      color: goal.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      if (goal.description != null &&
                          goal.description!.isNotEmpty)
                        Text(
                          goal.description!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF)),
                        ),
                    ],
                  ),
                ),
                if (daysLeft != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: daysLeft < 30
                          ? const Color(0xFFFF7043)
                              .withValues(alpha: 0.1)
                          : const Color(0xFF66BB6A)
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      daysLeft < 0 ? 'Échu' : '$daysLeft j',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: daysLeft < 30
                            ? const Color(0xFFFF7043)
                            : const Color(0xFF66BB6A),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFF3F4F6),
                valueColor:
                    AlwaysStoppedAnimation<Color>(goal.color),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_f(goal.currentAmount)} épargnés',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280)),
                ),
                Text(
                  _f(goal.targetAmount),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddFunds,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Alimenter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: goal.color,
                  side: BorderSide(
                      color: goal.color.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Carte dépense planifiée ────────────────────────────────────

class _PlannedCard extends StatelessWidget {
  final PlannedExpense expense;
  final VoidCallback onDelete;

  const _PlannedCard({required this.expense, required this.onDelete});

  static final _fmt = NumberFormat.decimalPattern('fr_FR');

  @override
  Widget build(BuildContext context) {
    final daysLeft =
        expense.plannedDate.difference(DateTime.now()).inDays;
    final isPast = daysLeft < 0;

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF5350),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child:
            const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: expense.category.color
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(expense.category.icon,
                  color: expense.category.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 11,
                          color: isPast
                              ? const Color(0xFFEF5350)
                              : const Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('d MMM yyyy', 'fr_FR')
                            .format(expense.plannedDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: isPast
                              ? const Color(0xFFEF5350)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                      if (!isPast) ...[
                        const SizedBox(width: 6),
                        Text(
                          'dans $daysLeft j',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6C63FF)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_fmt.format(expense.amount.toInt())} FCFA',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  expense.category.displayName,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Onglet Statistiques ────────────────────────────────────────

class _StatsTab extends ConsumerWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesStreamProvider);
    final goalsAsync = ref.watch(goalsStreamProvider);

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (expenses) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stats projets ──────────────────────────────
            goalsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (goals) => goals.isEmpty
                  ? const SizedBox.shrink()
                  : _ProjectsStats(goals: goals),
            ),
            // ── Stats dépenses ─────────────────────────────
            StatsContent(
              expenses: expenses,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
            ),
          ],
        ),
      ),
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
          // Carte résumé
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
                // Barre globale
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
                // Barres par projet
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
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  g.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                              ),
                              Text(
                                '${(g.progress * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: g.color,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _f(g.currentAmount),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: g.progress,
                              minHeight: 6,
                              backgroundColor:
                                  const Color(0xFFF3F4F6),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.8))),
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

// ── État vide ──────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color:
                  const Color(0xFF6C63FF).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 36, color: const Color(0xFF6C63FF)),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                  height: 1.5)),
        ],
      ),
    );
  }
}

// ── Dialog : Nouveau projet ────────────────────────────────────

class _AddGoalDialog extends ConsumerStatefulWidget {
  final String coupleId;
  const _AddGoalDialog({required this.coupleId});

  @override
  ConsumerState<_AddGoalDialog> createState() =>
      _AddGoalDialogState();
}

class _AddGoalDialogState extends ConsumerState<_AddGoalDialog> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _targetDate;
  int _colorIndex = 0;
  bool _saving = false;

  static const _colors = [
    Color(0xFF6C63FF),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFFF7043),
    Color(0xFFAB47BC),
    Color(0xFFEF5350),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(
        _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (title.isEmpty || amount == null || amount <= 0) return;

    setState(() => _saving = true);
    try {
      await ref.read(goalsProvider.notifier).addGoal(Goal(
            id: '',
            title: title,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            targetAmount: amount,
            currentAmount: 0,
            targetDate: _targetDate,
            coupleId: widget.coupleId,
            colorValue: _colors[_colorIndex].toARGB32(),
          ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Nouveau projet',
          style:
              TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DialogField(
                controller: _titleCtrl,
                hint: 'Nom du projet',
                icon: Icons.flag_rounded),
            const SizedBox(height: 10),
            _DialogField(
                controller: _amountCtrl,
                hint: 'Montant cible (FCFA)',
                icon: Icons.savings_rounded,
                keyboard: TextInputType.number),
            const SizedBox(height: 10),
            _DialogField(
                controller: _descCtrl,
                hint: 'Description (optionnel)',
                icon: Icons.notes_rounded),
            const SizedBox(height: 14),
            // Date cible
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now()
                      .add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now()
                      .add(const Duration(days: 365 * 5)),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(
                          primary: Color(0xFF6C63FF)),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  setState(() => _targetDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 16,
                        color: Color(0xFF6C63FF)),
                    const SizedBox(width: 10),
                    Text(
                      _targetDate == null
                          ? 'Date cible (optionnel)'
                          : DateFormat('d MMM yyyy', 'fr_FR')
                              .format(_targetDate!),
                      style: TextStyle(
                        fontSize: 14,
                        color: _targetDate == null
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Couleur
            const Text('Couleur',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                _colors.length,
                (i) => GestureDetector(
                  onTap: () => setState(() => _colorIndex = i),
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _colors[i],
                      shape: BoxShape.circle,
                      border: _colorIndex == i
                          ? Border.all(
                              color: Colors.white, width: 2)
                          : null,
                      boxShadow: _colorIndex == i
                          ? [
                              BoxShadow(
                                  color: _colors[i]
                                      .withValues(alpha: 0.5),
                                  blurRadius: 6)
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _saving ? null : () => Navigator.pop(context),
          child: const Text('Annuler',
              style: TextStyle(color: Color(0xFF9CA3AF))),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Créer'),
        ),
      ],
    );
  }
}

// ── Dialog : Alimenter un projet ───────────────────────────────

class _AddFundsDialog extends ConsumerStatefulWidget {
  final Goal goal;
  const _AddFundsDialog({required this.goal});

  @override
  ConsumerState<_AddFundsDialog> createState() =>
      _AddFundsDialogState();
}

class _AddFundsDialogState extends ConsumerState<_AddFundsDialog> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(
        _ctrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (amount == null || amount <= 0) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(goalsProvider.notifier)
          .addFunds(widget.goal.id, amount);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.goal.remaining;
    final fmt = NumberFormat.decimalPattern('fr_FR');

    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Alimenter « ${widget.goal.title} »',
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Restant : ${fmt.format(remaining.toInt())} FCFA',
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 14),
          _DialogField(
            controller: _ctrl,
            hint: 'Montant à ajouter (FCFA)',
            icon: Icons.add_rounded,
            keyboard: TextInputType.number,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed:
              _saving ? null : () => Navigator.pop(context),
          child: const Text('Annuler',
              style: TextStyle(color: Color(0xFF9CA3AF))),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.goal.color,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Ajouter'),
        ),
      ],
    );
  }
}

// ── Dialog : Nouvelle dépense planifiée ───────────────────────

class _AddPlannedExpenseDialog extends ConsumerStatefulWidget {
  final String coupleId;
  const _AddPlannedExpenseDialog({required this.coupleId});

  @override
  ConsumerState<_AddPlannedExpenseDialog> createState() =>
      _AddPlannedExpenseDialogState();
}

class _AddPlannedExpenseDialogState
    extends ConsumerState<_AddPlannedExpenseDialog> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.nourriture;
  DateTime _plannedDate =
      DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(
        _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (title.isEmpty || amount == null || amount <= 0) return;

    setState(() => _saving = true);
    try {
      await ref.read(plannedExpensesProvider.notifier).add(
            PlannedExpense(
              id: '',
              title: title,
              amount: amount,
              category: _category,
              plannedDate: _plannedDate,
              coupleId: widget.coupleId,
              note: _noteCtrl.text.trim().isEmpty
                  ? null
                  : _noteCtrl.text.trim(),
            ),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Dépense planifiée',
          style:
              TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DialogField(
                controller: _titleCtrl,
                hint: 'Titre',
                icon: Icons.label_rounded),
            const SizedBox(height: 10),
            _DialogField(
                controller: _amountCtrl,
                hint: 'Montant (FCFA)',
                icon: Icons.payments_rounded,
                keyboard: TextInputType.number),
            const SizedBox(height: 14),
            // Catégorie
            const Text('Catégorie',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                children: ExpenseCategory.values.map((cat) {
                  final sel = _category == cat;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? cat.color
                                .withValues(alpha: 0.15)
                            : const Color(0xFFF8F9FA),
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                          color: sel
                              ? cat.color
                              : const Color(0xFFE5E7EB),
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon,
                              color: sel
                                  ? cat.color
                                  : const Color(0xFFB0B8C1),
                              size: 14),
                          const SizedBox(width: 4),
                          Text(cat.displayName,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: sel
                                      ? cat.color
                                      : const Color(
                                          0xFF6B7280))),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Date prévue
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _plannedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now()
                      .add(const Duration(days: 365 * 3)),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(
                          primary: Color(0xFF6C63FF)),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  setState(() => _plannedDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 16,
                        color: Color(0xFF6C63FF)),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('d MMM yyyy', 'fr_FR')
                          .format(_plannedDate),
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1A2E)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            _DialogField(
                controller: _noteCtrl,
                hint: 'Note (optionnel)',
                icon: Icons.notes_rounded),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _saving ? null : () => Navigator.pop(context),
          child: const Text('Annuler',
              style: TextStyle(color: Color(0xFF9CA3AF))),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Planifier'),
        ),
      ],
    );
  }
}

// ── Champ générique dialog ─────────────────────────────────────

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboard;
  final bool autofocus;

  const _DialogField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboard = TextInputType.text,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      autofocus: autofocus,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        prefixIcon:
            Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
        hintText: hint,
        hintStyle: const TextStyle(
            color: Color(0xFFB0B8C1), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color(0xFF6C63FF), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
