import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gestionbudget/features/expenses/domain/expense_model.dart';
import 'package:gestionbudget/shared/providers/expenses_provider.dart';
import 'package:gestionbudget/shared/widgets/app_bottom_nav.dart';

enum _Filter { tous, mois, semaine }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _Filter _filter = _Filter.tous;
  String _search = '';

  static const _primary = Color(0xFF6C63FF);

  List<Expense> _applyFilter(List<Expense> all) {
    final now = DateTime.now();
    List<Expense> result;
    switch (_filter) {
      case _Filter.mois:
        final start = DateTime(now.year, now.month, 1);
        result = all.where((e) => e.date.isAfter(start)).toList();
      case _Filter.semaine:
        final start = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeek = DateTime(start.year, start.month, start.day);
        result = all.where((e) => e.date.isAfter(startOfWeek)).toList();
      case _Filter.tous:
        result = all;
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      result = result.where((e) {
        return e.category.displayName.toLowerCase().contains(q) ||
            (e.note?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: const Text(
                'Historique',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Barre de recherche ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
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
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une dépense…',
                    hintStyle: const TextStyle(
                      color: Color(0xFFB0B8C1),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFFB0B8C1),
                      size: 22,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Filtres ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _Filter.values.map((f) {
                  final labels = {
                    _Filter.tous: 'Tous',
                    _Filter.mois: 'Ce mois',
                    _Filter.semaine: 'Semaine',
                  };
                  final selected = _filter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? _primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: selected
                                ? _primary.withValues(alpha: 0.25)
                                : const Color(0x08000000),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        labels[f]!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Liste ───────────────────────────────────────────
            Expanded(
              child: expensesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Erreur: $e')),
                data: (all) {
                  final expenses = _applyFilter(all);
                  if (expenses.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucune dépense trouvée',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
                  final grouped = _group(expenses);
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: grouped.length,
                    itemBuilder: (context, i) {
                      final entry =
                          grouped.entries.elementAt(i);
                      return _Group(
                        label: entry.key,
                        expenses: entry.value,
                        onDelete: (id) async {
                          try {
                            await ref
                                .read(addExpenseProvider.notifier)
                                .deleteExpense(id);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur: $e')),
                              );
                            }
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Map<String, List<Expense>> _group(List<Expense> expenses) {
    final grouped = <String, List<Expense>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final e in expenses) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      String key;
      if (d == today) {
        key = "Aujourd'hui";
      } else if (d == today.subtract(const Duration(days: 1))) {
        key = 'Hier';
      } else {
        key = DateFormat('EEEE d MMMM', 'fr_FR').format(e.date);
      }
      grouped.putIfAbsent(key, () => []).add(e);
    }
    final sorted = grouped.keys.toList()..sort((a, b) {
      // Aujourd'hui et Hier d'abord
      if (a == "Aujourd'hui") return -1;
      if (b == "Aujourd'hui") return 1;
      if (a == 'Hier') return -1;
      if (b == 'Hier') return 1;
      return b.compareTo(a);
    });
    return {for (final k in sorted) k: grouped[k]!};
  }
}

class _Group extends StatelessWidget {
  final String label;
  final List<Expense> expenses;
  final void Function(String id) onDelete;

  const _Group({
    required this.label,
    required this.expenses,
    required this.onDelete,
  });

  static final _fmt = NumberFormat.decimalPattern('fr_FR');

  double get _total => expenses.fold(0.0, (s, e) => s + e.amount);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              Text(
                '${_fmt.format(_total.toInt())} FCFA',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
        ...expenses.map((e) => _Tile(expense: e, onDelete: () => onDelete(e.id))),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;

  const _Tile({required this.expense, required this.onDelete});

  static final _fmt = NumberFormat.decimalPattern('fr_FR');

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEF5350),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 22),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 6,
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

            // Titre + date
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
                    DateFormat('d MMM yyyy • HH:mm', 'fr_FR')
                        .format(expense.date),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),

            // Montant
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
                  'Par ${expense.payerName}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
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
