import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gestionbudget/features/expenses/domain/expense_model.dart';
import 'package:gestionbudget/features/goals/domain/goal_model.dart';
import 'package:gestionbudget/features/goals/domain/planned_expense_model.dart';
import 'package:gestionbudget/shared/providers/couple_provider.dart';
import 'package:gestionbudget/shared/providers/goals_provider.dart';
import 'package:gestionbudget/shared/widgets/app_bottom_nav.dart';

Color _statusColor(ProjectStatus status, Color fallback) => switch (status) {
  ProjectStatus.planning => const Color(0xFFF59E0B),
  ProjectStatus.active => fallback,
  ProjectStatus.paused => const Color(0xFF64748B),
  ProjectStatus.completed => const Color(0xFF22C55E),
};

IconData _statusIcon(ProjectStatus status) => switch (status) {
  ProjectStatus.planning => Icons.design_services_rounded,
  ProjectStatus.active => Icons.play_circle_rounded,
  ProjectStatus.paused => Icons.pause_circle_rounded,
  ProjectStatus.completed => Icons.check_circle_rounded,
};

void _showGoalDetail(BuildContext context, Goal goal) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => goal.type == GoalType.project
        ? _GoalDetailSheet(initialGoal: goal)
        : _PlanningGoalDetailSheet(goal: goal),
  );
}

void _showStatusPicker(BuildContext context, WidgetRef ref, Goal goal) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Changer le statut',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ProjectStatus.values.map((status) {
          final selected = goal.status == status;
          final color = _statusColor(status, goal.color);
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            onTap: () {
              ref.read(goalsProvider.notifier).updateProjectStatus(goal.id, status);
              Navigator.pop(ctx);
            },
            leading: Icon(_statusIcon(status), color: color, size: 20),
            title: Text(
              status.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                color: selected ? color : const Color(0xFF374151),
              ),
            ),
            trailing: selected
                ? Icon(Icons.check_rounded, color: color, size: 18)
                : null,
          );
        }).toList(),
      ),
    ),
  );
}

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
          'Projets',
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
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: _primary,
              unselectedLabelColor: const Color(0xFF9CA3AF),
              indicatorColor: _primary,
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              tabs: const [
                Tab(text: 'Gestion'),
                Tab(text: 'Planification'),
                Tab(text: 'Planifiées'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GoalsTab(coupleId: coupleId, goalType: GoalType.project),
          _GoalsTab(coupleId: coupleId, goalType: GoalType.planning),
          _PlannedTab(coupleId: coupleId),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}

// ── Onglet Projets ─────────────────────────────────────────────

class _GoalsTab extends ConsumerWidget {
  final String? coupleId;
  final GoalType goalType;
  const _GoalsTab({required this.coupleId, required this.goalType});

  static const _primary = Color(0xFF6C63FF);
  static final _fmt = NumberFormat.decimalPattern('fr_FR');
  static String _f(double v) => '${_fmt.format(v.toInt())} FCFA';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = goalType == GoalType.project
        ? ref.watch(projectManagementGoalsStreamProvider)
        : ref.watch(planningGoalsStreamProvider);
    final archivedAsync = ref.watch(archivedGoalsStreamProvider);
    final isProjectTab = goalType == GoalType.project;

    return goalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (goals) {
        final archived = (archivedAsync.asData?.value ?? [])
            .where((goal) => goal.type == goalType)
            .toList();
        final compactFab = MediaQuery.of(context).size.width < 390;
        return Stack(
          children: [
            goals.isEmpty && archived.isEmpty
                ? _EmptyState(
                    icon: isProjectTab
                        ? Icons.account_tree_rounded
                        : Icons.savings_rounded,
                    title: isProjectTab
                        ? 'Aucun projet en gestion'
                        : 'Aucune planification',
                    subtitle: isProjectTab
                        ? 'Crée un projet en cours\npour suivre budget, délais et étapes.'
                        : 'Crée votre premier projet d’épargne\net commencez à alimenter l’objectif.',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    children: [
                      if (goals.isNotEmpty) ...[
                        _SummaryCard(
                          leftLabel: isProjectTab ? 'Budget total' : 'Épargné',
                          leftValue: _f(
                            goals.fold(
                              0.0,
                              (s, g) =>
                                  s +
                                  (isProjectTab
                                      ? g.targetAmount
                                      : g.currentAmount),
                            ),
                          ),
                          centerLabel: isProjectTab
                              ? 'Coût engagé'
                              : 'Objectif total',
                          centerValue: _f(
                            goals.fold(
                              0.0,
                              (s, g) =>
                                  s +
                                  (isProjectTab
                                      ? g.spentAmount
                                      : g.targetAmount),
                            ),
                          ),
                          rightLabel: isProjectTab ? 'Étapes' : 'Restant',
                          rightValue: isProjectTab
                              ? '${goals.fold<int>(0, (s, g) => s + g.tasks.length)}'
                              : _f(
                                  goals
                                      .fold(0.0, (s, g) => s + g.remaining)
                                      .clamp(0, double.infinity),
                                ),
                        ),
                        const SizedBox(height: 16),
                        ...goals.map(
                          (g) => isProjectTab
                              ? _GoalCard(
                                  goal: g,
                                  onAddFunds: () => showDialog<void>(
                                    context: context,
                                    builder: (_) => _AddFundsDialog(goal: g),
                                  ),
                                  onDelete: () => ref
                                      .read(goalsProvider.notifier)
                                      .deleteGoal(g.id),
                                )
                              : _PlanningGoalCard(
                                  goal: g,
                                  onAddFunds: () => showDialog<void>(
                                    context: context,
                                    builder: (_) => _AddFundsDialog(goal: g),
                                  ),
                                  onDelete: () => ref
                                      .read(goalsProvider.notifier)
                                      .deleteGoal(g.id),
                                ),
                        ),
                      ],
                      // ── Section archivés ──────────────────────
                      if (archived.isNotEmpty)
                        _ArchivedSection(archived: archived),
                    ],
                  ),
            Positioned(
              bottom: 16,
              right: 20,
              child: compactFab
                  ? FloatingActionButton(
                      onPressed: coupleId == null
                          ? null
                          : () => showDialog<void>(
                              context: context,
                              builder: (_) => _AddGoalDialog(
                                coupleId: coupleId!,
                                goalType: goalType,
                              ),
                            ),
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      child: const Icon(Icons.add_rounded),
                    )
                  : FloatingActionButton.extended(
                      onPressed: coupleId == null
                          ? null
                          : () => showDialog<void>(
                              context: context,
                              builder: (_) => _AddGoalDialog(
                                coupleId: coupleId!,
                                goalType: goalType,
                              ),
                            ),
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        isProjectTab
                            ? 'Nouveau projet'
                            : 'Nouvelle planification',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
            ),
          ],
        );
      },
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
      data: (planned) {
        final compactFab = MediaQuery.of(context).size.width < 390;
        return Stack(
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
                          planned.fold(0.0, (s, e) => s + e.amount),
                        ),
                        rightLabel: 'Prochaine',
                        rightValue: planned.isNotEmpty
                            ? DateFormat(
                                'd MMM',
                                'fr_FR',
                              ).format(planned.first.plannedDate)
                            : '--',
                      ),
                      const SizedBox(height: 16),
                      ...planned.map(
                        (p) => _PlannedCard(
                          expense: p,
                          onDelete: () => ref
                              .read(plannedExpensesProvider.notifier)
                              .delete(p.id),
                        ),
                      ),
                    ],
                  ),
            Positioned(
              bottom: 16,
              right: 20,
              child: compactFab
                  ? FloatingActionButton(
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
                      child: const Icon(Icons.add_rounded),
                    )
                  : FloatingActionButton.extended(
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
                      label: const Text(
                        'Planifier',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
            ),
          ],
        );
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
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
          child: compact
              ? Column(
                  children: [
                    _SummaryItem(label: leftLabel, value: leftValue),
                    _summaryDivider(),
                    _SummaryItem(label: centerLabel, value: centerValue),
                    _summaryDivider(),
                    _SummaryItem(label: rightLabel, value: rightValue),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _SummaryItem(label: leftLabel, value: leftValue),
                    ),
                    _summaryDivider(vertical: true),
                    Expanded(
                      child: _SummaryItem(
                        label: centerLabel,
                        value: centerValue,
                      ),
                    ),
                    _summaryDivider(vertical: true),
                    Expanded(
                      child: _SummaryItem(label: rightLabel, value: rightValue),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _summaryDivider({bool vertical = false}) {
    return Container(
      width: vertical ? 1 : double.infinity,
      height: vertical ? 36 : 1,
      margin: vertical
          ? const EdgeInsets.symmetric(horizontal: 8)
          : const EdgeInsets.symmetric(vertical: 10),
      color: Colors.white.withValues(alpha: 0.3),
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
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
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
    final daysLeft = goal.targetDate?.difference(DateTime.now()).inDays;
    final statusColor = _statusColor(goal.status, goal.color);
    final taskSummary = goal.tasks.isEmpty
        ? 'Aucune étape'
        : '${goal.completedTasks}/${goal.tasks.length} étapes';

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
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => _showGoalDetail(context, goal),
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
                offset: Offset(0, 2),
              ),
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
                    child: Icon(
                      Icons.flag_rounded,
                      color: goal.color,
                      size: 22,
                    ),
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
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _statusIcon(goal.status),
                                    size: 12,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    goal.status.label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (daysLeft != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: daysLeft < 30
                                      ? const Color(
                                          0xFFFF7043,
                                        ).withValues(alpha: 0.1)
                                      : const Color(
                                          0xFF66BB6A,
                                        ).withValues(alpha: 0.1),
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
                        if (goal.description != null &&
                            goal.description!.isNotEmpty)
                          Text(
                            goal.description!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '${_f(goal.spentAmount)} dépensés • $taskSummary',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
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
                  valueColor: AlwaysStoppedAnimation<Color>(goal.color),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${_f(goal.currentAmount)} épargnés',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_f(goal.spentAmount)} / ${_f(goal.targetAmount)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (goal.progress >= 1.0)
                // ── Projet terminé ─────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF22C55E).withValues(alpha: .3),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: Color(0xFF22C55E),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Terminé',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // ── Projet en cours ────────────────────────────
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: goal.color.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: goal.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            goal.tasks.isEmpty
                                ? 'À structurer'
                                : 'Pilotage actif',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: goal.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onAddFunds,
                      icon: const Icon(Icons.add_rounded, size: 15),
                      label: const Text('Alimenter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: goal.color,
                        side: BorderSide(
                          color: goal.color.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
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
    final daysLeft = expense.plannedDate.difference(DateTime.now()).inDays;
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
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: expense.category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                expense.category.icon,
                color: expense.category.color,
                size: 22,
              ),
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
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 11,
                        color: isPast
                            ? const Color(0xFFEF5350)
                            : const Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat(
                          'd MMM yyyy',
                          'fr_FR',
                        ).format(expense.plannedDate),
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
                            color: Color(0xFF6C63FF),
                          ),
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
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section archivés ──────────────────────────────────────────

class _ArchivedSection extends ConsumerStatefulWidget {
  final List<Goal> archived;
  const _ArchivedSection({required this.archived});

  @override
  ConsumerState<_ArchivedSection> createState() => _ArchivedSectionState();
}

class _PlanningGoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onAddFunds;
  final VoidCallback onDelete;

  const _PlanningGoalCard({
    required this.goal,
    required this.onAddFunds,
    required this.onDelete,
  });

  static final _fmt = NumberFormat.decimalPattern('fr_FR');
  static String _f(double v) => '${_fmt.format(v.toInt())} FCFA';

  @override
  Widget build(BuildContext context) {
    final daysLeft = goal.targetDate?.difference(DateTime.now()).inDays;

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
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => _showGoalDetail(context, goal),
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
                offset: Offset(0, 2),
              ),
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
                    child: Icon(
                      Icons.savings_rounded,
                      color: goal.color,
                      size: 22,
                    ),
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
                        if (goal.description?.isNotEmpty == true)
                          Text(
                            goal.description!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (daysLeft != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: daysLeft < 30
                            ? const Color(0xFFFF7043).withValues(alpha: 0.1)
                            : const Color(0xFF66BB6A).withValues(alpha: 0.1),
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
                  valueColor: AlwaysStoppedAnimation<Color>(goal.color),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_f(goal.currentAmount)} épargnés',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: goal.color.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      goal.progress >= 1
                          ? 'Objectif atteint'
                          : 'Épargne en cours',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: goal.color,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onAddFunds,
                    icon: const Icon(Icons.add_rounded, size: 15),
                    label: const Text('Alimenter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: goal.color,
                      side: BorderSide(
                        color: goal.color.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchivedSectionState extends ConsumerState<_ArchivedSection> {
  bool _expanded = false;

  static final _fmt = NumberFormat.decimalPattern('fr_FR');
  static String _f(double v) => '${_fmt.format(v.toInt())} FCFA';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Titre repliable ──────────────────────────────────
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Projets archivés (${widget.archived.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        // ── Liste dépliée ────────────────────────────────────
        if (_expanded) ...[
          const SizedBox(height: 8),
          ...widget.archived.map(
            (g) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF94A3B8).withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                        Text(
                          '${_f(g.currentAmount)} / ${_f(g.targetAmount)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bouton réactiver
                  GestureDetector(
                    onTap: () =>
                        ref.read(goalsProvider.notifier).unarchiveGoal(g.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Réactiver',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
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
              color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: const Color(0xFF6C63FF)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dialog : Nouveau projet ────────────────────────────────────

class _AddGoalDialog extends ConsumerStatefulWidget {
  final String coupleId;
  final GoalType goalType;
  const _AddGoalDialog({required this.coupleId, required this.goalType});

  @override
  ConsumerState<_AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends ConsumerState<_AddGoalDialog> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _spentCtrl = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _targetDate;
  int _colorIndex = 0;
  ProjectStatus _status = ProjectStatus.planning;
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
    _spentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(
      _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    final spentAmount =
        double.tryParse(_spentCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (title.isEmpty || amount == null || amount <= 0) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(goalsProvider.notifier)
          .addGoal(
            Goal(
              id: '',
              title: title,
              description: _descCtrl.text.trim().isEmpty
                  ? null
                  : _descCtrl.text.trim(),
              targetAmount: amount,
              currentAmount: 0,
              spentAmount: widget.goalType == GoalType.project
                  ? spentAmount
                  : 0,
              startDate: widget.goalType == GoalType.project
                  ? _startDate
                  : null,
              targetDate: _targetDate,
              coupleId: widget.coupleId,
              colorValue: _colors[_colorIndex].toARGB32(),
              status: widget.goalType == GoalType.project
                  ? _status
                  : ProjectStatus.planning,
              type: widget.goalType,
            ),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Nouveau projet',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DialogField(
              controller: _titleCtrl,
              hint: 'Nom du projet',
              icon: Icons.flag_rounded,
            ),
            const SizedBox(height: 10),
            _DialogField(
              controller: _amountCtrl,
              hint: widget.goalType == GoalType.project
                  ? 'Budget cible (FCFA)'
                  : 'Montant cible (FCFA)',
              icon: widget.goalType == GoalType.project
                  ? Icons.account_balance_wallet_rounded
                  : Icons.savings_rounded,
              keyboard: TextInputType.number,
            ),
            if (widget.goalType == GoalType.project) ...[
              const SizedBox(height: 10),
              _DialogField(
                controller: _spentCtrl,
                hint: 'Coût déjà engagé (optionnel)',
                icon: Icons.payments_rounded,
                keyboard: TextInputType.number,
              ),
            ],
            const SizedBox(height: 10),
            _DialogField(
              controller: _descCtrl,
              hint: 'Description (optionnel)',
              icon: Icons.notes_rounded,
            ),
            if (widget.goalType == GoalType.project) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF6C63FF),
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() => _startDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.play_circle_outline_rounded,
                        size: 16,
                        color: Color(0xFF6C63FF),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Début : ${DateFormat('d MMM yyyy', 'fr_FR').format(_startDate)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ] else
              const SizedBox(height: 14),
            // Date cible
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      _targetDate ?? _startDate.add(const Duration(days: 30)),
                  firstDate: widget.goalType == GoalType.project
                      ? _startDate
                      : DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF6C63FF),
                      ),
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
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: Color(0xFF6C63FF),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _targetDate == null
                          ? 'Date cible (optionnel)'
                          : DateFormat(
                              'd MMM yyyy',
                              'fr_FR',
                            ).format(_targetDate!),
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
            if (widget.goalType == GoalType.project) ...[
              const SizedBox(height: 14),
              const Text(
                'Statut',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ProjectStatus.values.map((status) {
                  final selected = _status == status;
                  final color = _statusColor(status, _colors[_colorIndex]);
                  return GestureDetector(
                    onTap: () => setState(() => _status = status),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withValues(alpha: .12)
                            : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected ? color : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon(status), size: 14, color: color),
                          const SizedBox(width: 6),
                          Text(
                            status.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? color : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],
            // Couleur
            const Text(
              'Couleur',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: _colorIndex == i
                          ? [
                              BoxShadow(
                                color: _colors[i].withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
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
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text(
            'Annuler',
            style: TextStyle(color: Color(0xFF9CA3AF)),
          ),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
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
  ConsumerState<_AddFundsDialog> createState() => _AddFundsDialogState();
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
      _ctrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (amount == null || amount <= 0) return;
    setState(() => _saving = true);
    try {
      await ref.read(goalsProvider.notifier).addFunds(widget.goal.id, amount);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.goal.remaining;
    final fmt = NumberFormat.decimalPattern('fr_FR');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Alimenter « ${widget.goal.title} »',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Restant : ${fmt.format(remaining.toInt())} FCFA',
            style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
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
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text(
            'Annuler',
            style: TextStyle(color: Color(0xFF9CA3AF)),
          ),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.goal.color,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
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
  DateTime _plannedDate = DateTime.now().add(const Duration(days: 7));
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
      _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (title.isEmpty || amount == null || amount <= 0) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(plannedExpensesProvider.notifier)
          .add(
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Dépense planifiée',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DialogField(
              controller: _titleCtrl,
              hint: 'Titre',
              icon: Icons.label_rounded,
            ),
            const SizedBox(height: 10),
            _DialogField(
              controller: _amountCtrl,
              hint: 'Montant (FCFA)',
              icon: Icons.payments_rounded,
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 14),
            // Catégorie
            const Text(
              'Catégorie',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ExpenseCategory.values.map((cat) {
                    final sel = _category == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _category = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? cat.color.withValues(alpha: 0.15)
                              : const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel ? cat.color : const Color(0xFFE5E7EB),
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat.icon,
                              color: sel ? cat.color : const Color(0xFFB0B8C1),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cat.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: sel
                                    ? cat.color
                                    : const Color(0xFF6B7280),
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
            const SizedBox(height: 14),
            // Date prévue
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _plannedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF6C63FF),
                      ),
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
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: Color(0xFF6C63FF),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('d MMM yyyy', 'fr_FR').format(_plannedDate),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            _DialogField(
              controller: _noteCtrl,
              hint: 'Note (optionnel)',
              icon: Icons.notes_rounded,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text(
            'Annuler',
            style: TextStyle(color: Color(0xFF9CA3AF)),
          ),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Planifier'),
        ),
      ],
    );
  }
}

// ── Fiche détail planification ─────────────────────────────────

class _PlanningGoalDetailSheet extends ConsumerWidget {
  final Goal goal;
  const _PlanningGoalDetailSheet({required this.goal});

  static final _fmt = NumberFormat.decimalPattern('fr_FR');
  static final _fmtDt = DateFormat('d MMM yyyy • HH:mm', 'fr_FR');
  static String _f(double v) => '${_fmt.format(v.toInt())} FCFA';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(fundingHistoryProvider(goal.id));
    final remaining = goal.remaining;

    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      maxChildSize: 0.9,
      minChildSize: 0.42,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: goal.color.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.savings_rounded,
                    color: goal.color,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (goal.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          goal.description!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _DetailStat(
                        label: 'Objectif',
                        value: _f(goal.targetAmount),
                        color: const Color(0xFF0F172A),
                      ),
                      _DetailStat(
                        label: 'Épargné',
                        value: _f(goal.currentAmount),
                        color: goal.color,
                      ),
                      _DetailStat(
                        label: 'Restant',
                        value: _f(remaining),
                        color: const Color(0xFFF97316),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: goal.progress,
                      minHeight: 8,
                      backgroundColor: goal.color.withValues(alpha: .12),
                      valueColor: AlwaysStoppedAnimation<Color>(goal.color),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${(goal.progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: goal.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (goal.targetDate != null) ...[
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Échéance',
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat(
                        'd MMM yyyy',
                        'fr_FR',
                      ).format(goal.targetDate!),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Historique des alimentations',
              child: historyAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Erreur: $e'),
                ),
                data: (entries) => entries.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Aucune alimentation enregistrée pour le moment.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      )
                    : Column(
                        children: entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: goal.color.withValues(alpha: .1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.arrow_downward_rounded,
                                    color: goal.color,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _fmtDt.format(e.date),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                Text(
                                  '+${_f(e.amount)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: goal.color,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fiche détail gestion de projet ─────────────────────────────

class _GoalDetailSheet extends ConsumerWidget {
  final Goal initialGoal;
  const _GoalDetailSheet({required this.initialGoal});

  static final _fmt = NumberFormat.decimalPattern('fr_FR');
  static final _fmtDt = DateFormat('d MMM yyyy • HH:mm', 'fr_FR');
  static String _f(double v) => '${_fmt.format(v.toInt())} FCFA';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(goalStreamProvider(initialGoal.id)).asData?.value ?? initialGoal;
    final historyAsync = ref.watch(fundingHistoryProvider(goal.id));
    final surplus = (goal.currentAmount - goal.targetAmount).clamp(
      0.0,
      double.infinity,
    );
    final remaining = goal.remaining;
    final statusColor = _statusColor(goal.status, goal.color);
    final timelineStart = goal.startDate ?? goal.targetDate ?? DateTime.now();
    final timelineEnd =
        goal.targetDate ??
        (goal.tasks.isNotEmpty
            ? goal.tasks
                  .map((task) => task.endDate)
                  .reduce((a, b) => a.isAfter(b) ? a : b)
            : timelineStart.add(const Duration(days: 30)));
    final totalTimelineDays = (timelineEnd.difference(timelineStart).inDays + 1)
        .clamp(1, 5000);

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      maxChildSize: 0.92,
      minChildSize: 0.55,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: goal.color.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.flag_rounded, color: goal.color, size: 25),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (goal.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          goal.description!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                GestureDetector(
                  onTap: () => _showStatusPicker(context, ref, goal),
                  child: _StatusPill(
                    label: goal.status.label,
                    color: statusColor,
                    icon: _statusIcon(goal.status),
                    tappable: true,
                  ),
                ),
                _MetaPill(
                  icon: Icons.savings_rounded,
                  label: '${(goal.progress * 100).toStringAsFixed(0)}% financé',
                ),
                _MetaPill(
                  icon: Icons.account_tree_rounded,
                  label: goal.tasks.isEmpty
                      ? 'Aucune étape'
                      : '${goal.completedTasks}/${goal.tasks.length} étapes',
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _DetailStat(
                        label: 'Budget',
                        value: _f(goal.targetAmount),
                        color: const Color(0xFF0F172A),
                      ),
                      _DetailStat(
                        label: 'Épargné',
                        value: _f(goal.currentAmount),
                        color: goal.color,
                      ),
                      _DetailStat(
                        label: 'Dépensé',
                        value: _f(goal.spentAmount),
                        color: const Color(0xFFF97316),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _DetailStat(
                        label: 'À financer',
                        value: _f(remaining),
                        color: const Color(0xFF2563EB),
                      ),
                      _DetailStat(
                        label: 'Budget restant',
                        value: _f(goal.budgetRemaining),
                        color: const Color(0xFF16A34A),
                      ),
                      _DetailStat(
                        label: 'Surplus',
                        value: surplus > 0 ? '+${_f(surplus)}' : '—',
                        color: surplus > 0
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Pilotage',
              trailing: TextButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _EditProjectDialog(goal: goal),
                ),
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Mettre à jour'),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _TimelineMetric(
                          icon: Icons.play_arrow_rounded,
                          label: 'Début',
                          value: goal.startDate == null
                              ? 'Non défini'
                              : DateFormat(
                                  'd MMM yyyy',
                                  'fr_FR',
                                ).format(goal.startDate!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TimelineMetric(
                          icon: Icons.event_rounded,
                          label: 'Échéance',
                          value: goal.targetDate == null
                              ? 'Non définie'
                              : DateFormat(
                                  'd MMM yyyy',
                                  'fr_FR',
                                ).format(goal.targetDate!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _TimelineMetric(
                          icon: Icons.schedule_rounded,
                          label: 'Temps écoulé',
                          value:
                              '${(goal.timeProgress * 100).toStringAsFixed(0)}%',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TimelineMetric(
                          icon: Icons.fact_check_rounded,
                          label: 'Étapes faites',
                          value: goal.tasks.isEmpty
                              ? '0'
                              : '${goal.completedTasks}/${goal.tasks.length}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ProgressLabel(
                    label: 'Progression financière',
                    value: goal.progress,
                    color: goal.color,
                  ),
                  const SizedBox(height: 10),
                  _ProgressLabel(
                    label: 'Consommation du budget',
                    value: goal.spendingProgress,
                    color: const Color(0xFFF97316),
                  ),
                  const SizedBox(height: 10),
                  _ProgressLabel(
                    label: 'Avancement des étapes',
                    value: goal.taskProgress,
                    color: const Color(0xFF16A34A),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Mini diagramme de Gantt',
              trailing: TextButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _AddTaskDialog(goal: goal),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Étape'),
              ),
              child: goal.tasks.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Ajoute des étapes avec dates de début et de fin pour suivre le planning.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                    )
                  : Column(
                      children: () {
                        final todayOffset = DateTime.now()
                            .difference(timelineStart)
                            .inDays
                            .toDouble()
                            .clamp(0.0, totalTimelineDays.toDouble());
                        return goal.tasks.map((task) {
                          final startOffset = task.startDate
                              .difference(timelineStart)
                              .inDays
                              .clamp(0, totalTimelineDays - 1);
                          final duration = (task.endDate
                                      .difference(task.startDate)
                                      .inDays +
                                  1)
                              .clamp(1, totalTimelineDays);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _GanttTaskRow(
                              task: task,
                              color: goal.color,
                              totalDays: totalTimelineDays.toDouble(),
                              startOffset: startOffset.toDouble(),
                              duration: duration.toDouble(),
                              todayOffset: todayOffset,
                              onToggle: () async {
                                final tasks = goal.tasks
                                    .map(
                                      (item) => item.id == task.id
                                          ? item.copyWith(
                                              isDone: !item.isDone,
                                            )
                                          : item,
                                    )
                                    .toList();
                                await ref
                                    .read(goalsProvider.notifier)
                                    .saveTasks(goal.id, tasks);
                              },
                              onDelete: () async {
                                final tasks = goal.tasks
                                    .where((t) => t.id != task.id)
                                    .toList();
                                await ref
                                    .read(goalsProvider.notifier)
                                    .saveTasks(goal.id, tasks);
                              },
                            ),
                          );
                        }).toList();
                      }(),
                    ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Historique des alimentations',
              child: historyAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Erreur: $e'),
                ),
                data: (entries) => entries.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Aucune alimentation enregistrée pour le moment.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      )
                    : Column(
                        children: entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: goal.color.withValues(alpha: .1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.arrow_downward_rounded,
                                    color: goal.color,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _fmtDt.format(e.date),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                Text(
                                  '+${_f(e.amount)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: goal.color,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      goal.isArchived
                          ? 'Réactiver ce projet ?'
                          : 'Archiver ce projet ?',
                    ),
                    content: Text(
                      goal.isArchived
                          ? 'Le projet sera de nouveau visible et actif.'
                          : 'Le projet sera masqué de la liste active. Vous pouvez le réactiver à tout moment.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: goal.isArchived
                              ? const Color(0xFF6C63FF)
                              : const Color(0xFF64748B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(goal.isArchived ? 'Réactiver' : 'Archiver'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  if (goal.isArchived) {
                    await ref
                        .read(goalsProvider.notifier)
                        .unarchiveGoal(goal.id);
                  } else {
                    await ref.read(goalsProvider.notifier).archiveGoal(goal.id);
                  }
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: goal.isArchived
                      ? const Color(0xFF6C63FF).withValues(alpha: .08)
                      : const Color(0xFF64748B).withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: goal.isArchived
                        ? const Color(0xFF6C63FF).withValues(alpha: .3)
                        : const Color(0xFF64748B).withValues(alpha: .3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      goal.isArchived
                          ? Icons.unarchive_rounded
                          : Icons.inventory_2_outlined,
                      size: 16,
                      color: goal.isArchived
                          ? const Color(0xFF6C63FF)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      goal.isArchived
                          ? 'Réactiver ce projet'
                          : 'Archiver ce projet',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: goal.isArchived
                            ? const Color(0xFF6C63FF)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 340;
              if (!compact) {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (trailing != null) ...[trailing!],
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(height: 8),
                    trailing!,
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool tappable;

  const _StatusPill({
    required this.label,
    required this.color,
    required this.icon,
    this.tappable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
        border: tappable
            ? Border.all(color: color.withValues(alpha: .3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          if (tappable) ...[
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded, size: 14, color: color),
          ],
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TimelineMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressLabel extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ProgressLabel({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 7,
            backgroundColor: color.withValues(alpha: .12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _GanttTaskRow extends StatelessWidget {
  final ProjectTask task;
  final Color color;
  final double totalDays;
  final double startOffset;
  final double duration;
  final double todayOffset;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _GanttTaskRow({
    required this.task,
    required this.color,
    required this.totalDays,
    required this.startOffset,
    required this.duration,
    required this.todayOffset,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final leftFlex = ((startOffset / totalDays) * 1000).round().clamp(0, 1000);
    final barFlex = ((duration / totalDays) * 1000).round().clamp(1, 1000);
    final rightFlex = (1000 - leftFlex - barFlex).clamp(0, 1000);
    final todayFraction = (todayOffset / totalDays).clamp(0.0, 1.0);
    final barColor = task.isDone ? const Color(0xFF22C55E) : color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: Icon(
                task.isDone
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: task.isDone ? const Color(0xFF22C55E) : color,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: task.isDone
                      ? const Color(0xFF64748B)
                      : const Color(0xFF0F172A),
                  decoration: task.isDone
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${DateFormat('d MMM', 'fr_FR').format(task.startDate)} – ${DateFormat('d MMM', 'fr_FR').format(task.endDate)}',
              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: Color(0xFFCBD5E1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            // Fond + barre de progression
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  if (leftFlex > 0) Spacer(flex: leftFlex),
                  Flexible(
                    flex: barFlex,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  if (rightFlex > 0) Spacer(flex: rightFlex),
                ],
              ),
            ),
            // Marqueur "Aujourd'hui"
            if (todayFraction > 0.0 && todayFraction < 1.0)
              FractionallySizedBox(
                widthFactor: todayFraction,
                alignment: Alignment.centerLeft,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 2,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _EditProjectDialog extends ConsumerStatefulWidget {
  final Goal goal;

  const _EditProjectDialog({required this.goal});

  @override
  ConsumerState<_EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends ConsumerState<_EditProjectDialog> {
  late final TextEditingController _budgetCtrl;
  late final TextEditingController _spentCtrl;
  late ProjectStatus _status;
  late DateTime _startDate;
  late DateTime? _targetDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _budgetCtrl = TextEditingController(
      text: widget.goal.targetAmount.toInt().toString(),
    );
    _spentCtrl = TextEditingController(
      text: widget.goal.spentAmount.toInt().toString(),
    );
    _status = widget.goal.status;
    _startDate = widget.goal.startDate ?? DateTime.now();
    _targetDate = widget.goal.targetDate;
  }

  @override
  void dispose() {
    _budgetCtrl.dispose();
    _spentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final budget = double.tryParse(
      _budgetCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    final spent =
        double.tryParse(_spentCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (budget == null || budget <= 0) return;
    setState(() => _saving = true);
    await ref.read(goalsProvider.notifier).updateGoal(widget.goal.id, {
      'targetAmount': budget,
      'spentAmount': spent,
      'startDate': Timestamp.fromDate(_startDate),
      'targetDate': _targetDate != null
          ? Timestamp.fromDate(_targetDate!)
          : null,
      'status': _status.name,
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Mettre à jour le projet'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(
              controller: _budgetCtrl,
              hint: 'Budget cible',
              icon: Icons.account_balance_wallet_rounded,
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 10),
            _DialogField(
              controller: _spentCtrl,
              hint: 'Coût déjà engagé',
              icon: Icons.payments_rounded,
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 10),
            _DateTile(
              icon: Icons.play_arrow_rounded,
              label: 'Début',
              value: _startDate,
              onPick: (picked) => setState(() => _startDate = picked),
            ),
            const SizedBox(height: 10),
            _DateTile(
              icon: Icons.event_rounded,
              label: 'Échéance',
              value: _targetDate,
              firstDate: _startDate,
              onPick: (picked) => setState(() => _targetDate = picked),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProjectStatus.values.map((status) {
                final selected = _status == status;
                final color = _statusColor(status, widget.goal.color);
                return GestureDetector(
                  onTap: () => setState(() => _status = status),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withValues(alpha: .12)
                          : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected ? color : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(status), size: 14, color: color),
                        const SizedBox(width: 6),
                        Text(
                          status.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected ? color : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}

class _AddTaskDialog extends ConsumerStatefulWidget {
  final Goal goal;

  const _AddTaskDialog({required this.goal});

  @override
  ConsumerState<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends ConsumerState<_AddTaskDialog> {
  final _titleCtrl = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.goal.startDate ?? DateTime.now();
    _endDate = _startDate.add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    final task = ProjectTask(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      startDate: _startDate,
      endDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
    );
    await ref.read(goalsProvider.notifier).saveTasks(widget.goal.id, [
      ...widget.goal.tasks,
      task,
    ]);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Ajouter une étape'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(
              controller: _titleCtrl,
              hint: 'Nom de l’étape',
              icon: Icons.account_tree_rounded,
            ),
            const SizedBox(height: 10),
            _DateTile(
              icon: Icons.play_arrow_rounded,
              label: 'Début de l’étape',
              value: _startDate,
              onPick: (picked) => setState(() => _startDate = picked),
            ),
            const SizedBox(height: 10),
            _DateTile(
              icon: Icons.flag_rounded,
              label: 'Fin de l’étape',
              value: _endDate,
              firstDate: _startDate,
              onPick: (picked) => setState(() => _endDate = picked),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Ajouter'),
        ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime? value;
  final DateTime? firstDate;
  final ValueChanged<DateTime> onPick;

  const _DateTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onPick,
    this.firstDate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? firstDate ?? DateTime.now(),
          firstDate:
              firstDate ?? DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: Color(0xFF6C63FF)),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF6C63FF)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$label : ${value == null ? 'Non définie' : DateFormat('d MMM yyyy', 'fr_FR').format(value!)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: value == null
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF1A1A2E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _DetailStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
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
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB0B8C1), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}
