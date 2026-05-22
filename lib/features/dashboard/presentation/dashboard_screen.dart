import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gestionbudget/features/expenses/domain/expense_model.dart';
import 'package:gestionbudget/shared/providers/couple_provider.dart';
import 'package:gestionbudget/shared/providers/expenses_provider.dart';
import 'package:gestionbudget/shared/widgets/app_bottom_nav.dart';

const _kPrimary = Color(0xFF5B52EE);
const _kBg       = Color(0xFFF5F7FA);
const _kCard     = Colors.white;
const _kDark     = Color(0xFF0F172A);
const _kGray     = Color(0xFF94A3B8);
const _kGreen    = Color(0xFF22C55E);
const _kOrange   = Color(0xFFF97316);

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
      body: SafeArea(
        bottom: false,
        child: expensesAsync.when(
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
    final overBudget = total > budget && budget > 0;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Header gradient ──────────────────────────────────────
        SliverToBoxAdapter(
          child: _Header(
            userName: userName,
            partnerName: partnerName,
            budget: budget,
            spent: total,
            remaining: remaining,
            progress: progress,
            daysLeft: _daysLeft,
            todayTotal: _todayTotal,
            coupleId: coupleId,
            overBudget: overBudget,
          ),
        ),

        // ── Actions rapides ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Actions rapides',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kDark,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _QuickAction(
                      icon: Icons.history_rounded,
                      label: 'Historique',
                      onTap: () => context.go('/history'),
                    ),
                    _QuickAction(
                      icon: Icons.bar_chart_rounded,
                      label: 'Stats',
                      onTap: () => context.go('/stats'),
                    ),
                    _QuickAction(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Budget',
                      onTap: () => context.go('/budget'),
                    ),
                    _QuickAction(
                      icon: Icons.flag_rounded,
                      label: 'Objectifs',
                      onTap: () => context.go('/goals'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Titre transactions récentes ──────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dépenses récentes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kDark,
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
                      color: _kDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Appuie sur + pour ajouter\nta première dépense',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: _kGray),
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
  final double todayTotal;
  final String? coupleId;
  final bool overBudget;

  const _Header({
    required this.userName,
    required this.partnerName,
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.progress,
    required this.daysLeft,
    required this.todayTotal,
    required this.coupleId,
    required this.overBudget,
  });

  static final _fmt = NumberFormat.decimalPattern('fr_FR');
  static String _f(double v) => '${_fmt.format(v.toInt())} F';

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
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
    final barColor = overBudget ? _kOrange : _kGreen;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4C44D4), Color(0xFF7B75F0)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        children: [
          // ── Barre top : avatar | salutation | settings ────────
          Row(
            children: [
              // Avatar utilisateur
              _Avatar(initial: userName.isNotEmpty ? userName[0] : '?'),
              const SizedBox(width: 12),
              // Salutation centrée
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$_greeting !',
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      _cap(userName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Bouton paramètres (droite)
              GestureDetector(
                onTap: () => context.go('/settings'),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Zone solde / budget ───────────────────────────────
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Budget du mois',
              style: TextStyle(
                color: Color(0xCCFFFFFF),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              budget == 0 ? 'Définir un budget →' : _f(budget),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              budget == 0
                  ? 'Appuie sur Modifier pour définir ton budget'
                  : 'Restant : ${_f(remaining)}',
              style: const TextStyle(
                color: Color(0xAAFFFFFF),
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: .2),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_f(spent)} dépensé',
                style: const TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontSize: 11,
                ),
              ),
              if (budget > 0)
                Text(
                  '$daysLeft j restants',
                  style: const TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 11,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Deux boutons d'action ─────────────────────────────
          Row(
            children: [
              Expanded(
                child: _HeaderButton(
                  icon: Icons.add_rounded,
                  label: 'Ajouter',
                  onTap: () => context.go('/add-expense'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeaderButton(
                  icon: Icons.edit_outlined,
                  label: 'Modifier budget',
                  onTap: () => _showBudgetDialog(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Avatar ─────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String initial;
  const _Avatar({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .22),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: .4), width: 2),
      ),
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Bouton dans le header ──────────────────────────────────────
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: .25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action rapide ──────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: _kPrimary, size: 26),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kDark,
            ),
          ),
        ],
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
                    color: _kDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('d MMM • HH:mm', 'fr_FR').format(expense.date),
                  style: const TextStyle(fontSize: 11, color: _kGray),
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
                  color: _kDark,
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
                color: _kOrange.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: _kOrange, size: 34),
            ),
            const SizedBox(height: 16),
            const Text(
              'Impossible de charger\nles données',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _kGray),
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
            style: TextStyle(color: _kGray, fontSize: 13),
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
          child: const Text('Annuler', style: TextStyle(color: _kGray)),
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
