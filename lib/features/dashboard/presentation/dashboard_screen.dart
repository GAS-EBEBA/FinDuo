import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gestionbudget/features/expenses/domain/expense_model.dart';
import 'package:gestionbudget/shared/providers/couple_provider.dart';
import 'package:gestionbudget/shared/providers/expenses_provider.dart';
import 'package:gestionbudget/shared/widgets/app_bottom_nav.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesStreamProvider);
    final budgetAsync = ref.watch(budgetStreamProvider);
    final couple = ref.watch(coupleProvider);
    final coupleId = ref.watch(coupleFutureProvider).asData?.value;

    final budget = budgetAsync.asData?.value ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        bottom: false,
        child: expensesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      size: 48, color: Color(0xFF9CA3AF)),
                  const SizedBox(height: 12),
                  const Text(
                    'Impossible de charger les données',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
          ),
          data: (expenses) => _Body(
            expenses: expenses,
            userName: couple.userName ?? 'toi',
            partnerName: couple.partnerName,
            budget: budget,
            coupleId: coupleId,
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

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

  static final _fmt =
      NumberFormat.decimalPattern('fr_FR');
  static String _f(double v) => '${_fmt.format(v.toInt())} FCFA';

  double get _totalMonth {
    final start = DateTime(DateTime.now().year, DateTime.now().month, 1);
    return expenses
        .where((e) => e.date.isAfter(start))
        .fold(0.0, (s, e) => s + e.amount);
  }

  List<Expense> get _recent => expenses.take(5).toList();

  @override
  Widget build(BuildContext context) {
    final total = _totalMonth;
    final remaining = budget - total;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header + Gradient Card ──────────────────────
              _GradientCard(
                userName: userName,
                partnerName: partnerName,
                budget: budget,
                spent: total,
                remaining: remaining,
                coupleId: coupleId,
              ),
              const SizedBox(height: 24),

              // ── Stats rapides ───────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _StatChip(
                      label: 'Dépensé',
                      value: _f(total),
                      color: const Color(0xFFFF7043),
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      label: 'Restant',
                      value: _f(remaining.clamp(0, budget)),
                      color: const Color(0xFF66BB6A),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Dépenses récentes ───────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dépenses récentes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/history'),
                      child: const Text(
                        'Voir tout',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6C63FF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        // ── Liste des dépenses ────────────────────────────
        if (_recent.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Aucune dépense\nAjoute ta première dépense !',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _ExpenseTile(expense: _recent[index]),
              childCount: _recent.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ── Carte gradient violet ──────────────────────────────────────
class _GradientCard extends StatelessWidget {
  final String userName;
  final String? partnerName;
  final double budget;
  final double spent;
  final double remaining;
  final String? coupleId;

  const _GradientCard({
    required this.userName,
    required this.partnerName,
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.coupleId,
  });

  static final _fmt = NumberFormat.decimalPattern('fr_FR');
  static String _f(double v) => '${_fmt.format(v.toInt())} FCFA';

  Future<void> _showBudgetDialog(BuildContext context) {
    if (coupleId == null) return Future.value();
    return showDialog<void>(
      context: context,
      builder: (_) => _BudgetDialog(
        initialBudget: budget,
        coupleId: coupleId!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: EdgeInsets.zero,
      child: Stack(
        children: [
          // Fond avec courbe en bas
          ClipPath(
            clipper: _CardClipper(),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6C63FF), Color(0xFF9C95FF)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: salutation + avatar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour ${_capitalize(userName)} 👋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Votre budget du mois',
                            style: TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.go('/settings'),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.settings_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Montant principal
                  Row(
                    children: [
                      const Text(
                        'Budget du mois',
                        style: TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showBudgetDialog(context),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    budget == 0 ? 'Définir le budget →' : _f(budget),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Solde de ce mois-ci',
                    style: const TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Barre de progression
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Avatars du couple + dépenses
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Avatars
                      Row(
                        children: [
                          _Avatar(
                            initial: userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : '?',
                            offset: 0,
                          ),
                          if (partnerName != null && partnerName!.isNotEmpty)
                            _Avatar(
                              initial: partnerName![0].toUpperCase(),
                              offset: -10,
                            ),
                        ],
                      ),
                      Text(
                        'Dépensé: ${_f(spent)}',
                        style: const TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _CardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
      size.width / 2, size.height + 20,
      size.width, size.height - 30,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _Avatar extends StatelessWidget {
  final String initial;
  final double offset;

  const _Avatar({required this.initial, required this.offset});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(offset, 0),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
              color: Color(0xFF6C63FF),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Chip stat rapide ───────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tuile dépense ──────────────────────────────────────────────
class _ExpenseTile extends StatelessWidget {
  final Expense expense;

  const _ExpenseTile({required this.expense});

  static final _fmt = NumberFormat.decimalPattern('fr_FR');

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          // Icône catégorie
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('d MMM, HH:mm', 'fr_FR').format(expense.date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),

          // Montant + payeur
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_fmt.format(expense.amount.toInt())} FCFA',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6C63FF),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                expense.payerName,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Dialog budget ──────────────────────────────────────────────
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
    final amount = double.tryParse(_controller.text.replaceAll(' ', ''));
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
        'Définir le budget',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Budget mensuel total du couple',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              suffixText: 'FCFA',
              hintText: 'ex: 500000',
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
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
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
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
