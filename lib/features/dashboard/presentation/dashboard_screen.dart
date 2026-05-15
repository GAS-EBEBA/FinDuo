import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gestionbudget/features/expenses/domain/expense_model.dart';
import 'package:gestionbudget/shared/providers/couple_provider.dart';
import 'package:gestionbudget/shared/providers/expenses_provider.dart';
import 'package:gestionbudget/shared/widgets/app_bottom_nav.dart';

const _kPrimary   = Color(0xFF6C63FF);
const _kPrimary2  = Color(0xFF8B85FF);
const _kBg        = Color(0xFFF5F7FA);
const _kCard      = Colors.white;
const _kTextDark  = Color(0xFF0F172A);
const _kTextGray  = Color(0xFF94A3B8);
const _kGreen     = Color(0xFF22C55E);
const _kOrange    = Color(0xFFF97316);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesStreamProvider);
    final budgetAsync   = ref.watch(budgetStreamProvider);
    final couple        = ref.watch(coupleProvider);
    final coupleId      = ref.watch(coupleFutureProvider).asData?.value;
    final partnerName   = ref.watch(partnerNameProvider).asData?.value;
    final budget        = budgetAsync.asData?.value ?? 0.0;

    return Scaffold(
      backgroundColor: _kBg,
      body: expensesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _kPrimary),
        ),
        error: (e, _) => _ErrorBody(message: e.toString()),
        data: (expenses) => _Body(
          expenses: expenses,
          userName: couple.userName ?? 'toi',
          partnerName: partnerName,
          budget: budget,
          coupleId: coupleId,
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

// ── Corps principal ────────────────────────────────────────────
class _Body extends StatelessWidget {
  final List<Expense> expenses;
  final String userName;
  final String? partnerName;
  final double budget;
  final String? coupleId;

  const _Body({
    required this.expenses,
    required this.userName,
    required this.partnerName,
    required this.budget,
    required this.coupleId,
  });

  static final _fmtNum = NumberFormat.decimalPattern('fr_FR');
  static String _f(double v) => '${_fmtNum.format(v.toInt())} FCFA';

  double get _totalMonth {
    final start = DateTime(DateTime.now().year, DateTime.now().month, 1);
    return expenses
        .where((e) => e.date.isAfter(start))
        .fold(0.0, (s, e) => s + e.amount);
  }

  double get _todayTotal {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return expenses
        .where((e) => e.date.isAfter(startOfDay))
        .fold(0.0, (s, e) => s + e.amount);
  }

  List<Expense> get _recent => expenses.take(5).toList();

  int get _daysLeft {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    return lastDay.day - now.day;
  }

  @override
  Widget build(BuildContext context) {
    final total     = _totalMonth;
    final remaining = (budget - total).clamp(0.0, double.infinity);
    final progress  = budget > 0 ? (total / budget).clamp(0.0, 1.0) : 0.0;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Header ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _Header(
            userName: userName,
            partnerName: partnerName,
            budget: budget,
            spent: total,
            remaining: remaining,
            progress: progress,
            daysLeft: _daysLeft,
            coupleId: coupleId,
          ),
        ),

        // ── Chips résumé ─────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                _SummaryChip(
                  icon: Icons.arrow_upward_rounded,
                  iconBg: _kOrange.withValues(alpha: .12),
                  iconColor: _kOrange,
                  label: 'Dépensé ce mois',
                  value: _f(total),
                ),
                const SizedBox(width: 12),
                _SummaryChip(
                  icon: Icons.today_rounded,
                  iconBg: _kPrimary.withValues(alpha: .1),
                  iconColor: _kPrimary,
                  label: "Aujourd'hui",
                  value: _f(_todayTotal),
                ),
              ],
            ),
          ),
        ),

        // ── Titre dépenses récentes ──────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dépenses récentes',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _kTextDark,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/history'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Voir tout',
                      style: TextStyle(
                        fontSize: 12,
                        color: _kPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Liste dépenses ───────────────────────────────────────
        if (_recent.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: .08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: _kPrimary,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune dépense pour le moment',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kTextDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Appuie sur + pour ajouter\nta première dépense',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: _kTextGray),
                  ),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _ExpenseTile(expense: _recent[i]),
              childCount: _recent.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ── Header ─────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String userName;
  final String? partnerName;
  final double budget;
  final double spent;
  final double remaining;
  final double progress;
  final int daysLeft;
  final String? coupleId;

  const _Header({
    required this.userName,
    required this.partnerName,
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.progress,
    required this.daysLeft,
    required this.coupleId,
  });

  static final _fmt = NumberFormat.decimalPattern('fr_FR');
  static String _f(double v) => '${_fmt.format(v.toInt())} F';

  String get _dateLabel {
    final now = DateTime.now();
    return DateFormat("EEEE d MMMM", 'fr_FR').format(now);
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _showBudgetDialog(BuildContext context) {
    if (coupleId == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => _BudgetDialog(
        initialBudget: budget,
        coupleId: coupleId!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusBarH = MediaQuery.of(context).padding.top;
    final overBudget = spent > budget && budget > 0;
    final barColor   = overBudget ? _kOrange : _kGreen;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B52EE), _kPrimary2],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, statusBarH + 16, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cap(_dateLabel),
                      style: const TextStyle(
                        color: Color(0xAAFFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bonjour ${_cap(userName)} 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Avatars du couple
                    _MiniAvatar(
                      initial: userName.isNotEmpty ? userName[0] : '?',
                      offset: 0,
                    ),
                    if (partnerName != null && partnerName!.isNotEmpty)
                      _MiniAvatar(
                        initial: partnerName![0],
                        offset: -8,
                      ),
                    const SizedBox(width: 12),
                    // Bouton settings
                    GestureDetector(
                      onTap: () => context.go('/settings'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .2),
                          ),
                        ),
                        child: const Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Carte budget ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Budget du mois',
                        style: TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showBudgetDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Modifier',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    budget == 0 ? 'Définir votre budget →' : _f(budget),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Barre de progression avec labels
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor:
                              Colors.white.withValues(alpha: .2),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _BudgetLabel(
                            icon: Icons.arrow_upward_rounded,
                            label: 'Dépensé',
                            value: _f(spent),
                            color: _kOrange,
                          ),
                          _BudgetLabel(
                            icon: Icons.savings_rounded,
                            label: 'Restant',
                            value: _f(remaining),
                            color: _kGreen,
                            alignRight: true,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Jours restants
                  if (budget > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$daysLeft jours restants ce mois',
                        style: const TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool alignRight;

  const _BudgetLabel({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!alignRight) ...[
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(
                  color: Color(0xAAFFFFFF), fontSize: 11),
            ),
            if (alignRight) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 11, color: color),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final String initial;
  final double offset;
  const _MiniAvatar({required this.initial, required this.offset});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(offset, 0),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .9),
          shape: BoxShape.circle,
          border: Border.all(color: _kPrimary, width: 2),
        ),
        child: Center(
          child: Text(
            initial.toUpperCase(),
            style: const TextStyle(
              color: _kPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Chip résumé ─────────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  const _SummaryChip({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: _kTextGray,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kTextDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tuile dépense ───────────────────────────────────────────────
class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  const _ExpenseTile({required this.expense});

  static final _fmtNum = NumberFormat.decimalPattern('fr_FR');

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône catégorie
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: expense.category.color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              expense.category.icon,
              color: expense.category.color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Nom + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.note?.isNotEmpty == true
                      ? expense.note!
                      : expense.category.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kTextDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('d MMM • HH:mm', 'fr_FR').format(expense.date),
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kTextGray,
                  ),
                ),
              ],
            ),
          ),

          // Montant + badge payeur
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${_fmtNum.format(expense.amount.toInt())} F',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kTextDark,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  expense.payerName,
                  style: const TextStyle(
                    fontSize: 10,
                    color: _kPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Erreur ──────────────────────────────────────────────────────
class _ErrorBody extends StatelessWidget {
  final String message;
  const _ErrorBody({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF97316).withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: Color(0xFFF97316), size: 34),
            ),
            const SizedBox(height: 16),
            const Text(
              'Impossible de charger\nles données',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kTextDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _kTextGray),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dialog budget ───────────────────────────────────────────────
class _BudgetDialog extends StatefulWidget {
  final double initialBudget;
  final String coupleId;
  const _BudgetDialog({required this.initialBudget, required this.coupleId});

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialBudget > 0
          ? widget.initialBudget.toInt().toString()
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount =
        double.tryParse(_controller.text.replaceAll(' ', ''));
    if (amount == null || amount <= 0) return;
    setState(() => _saving = true);
    await updateBudget(widget.coupleId, amount);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Budget mensuel',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Budget mensuel total du couple',
            style: TextStyle(color: _kTextGray, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              suffixText: 'FCFA',
              hintText: 'ex: 500 000',
              filled: true,
              fillColor: _kBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: _kPrimary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Annuler',
              style: TextStyle(color: _kTextGray)),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
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
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
