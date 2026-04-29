import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gestionbudget/core/constants/app_colors.dart';
import 'package:gestionbudget/core/constants/app_strings.dart';
import 'package:gestionbudget/features/expenses/domain/expense_model.dart';
import 'package:gestionbudget/shared/providers/expenses_provider.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final _budgetController = TextEditingController(text: '500 000');
  double _monthlyBudget = 500000.0;

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _onBudgetChanged(String value) {
    final clean = value.replaceAll(RegExp(r'[\s  ]'), '');
    final parsed = double.tryParse(clean) ?? 0.0;
    setState(() => _monthlyBudget = parsed);
    if (clean.isNotEmpty) {
      final formatted = NumberFormat('#,###', 'fr_FR').format(parsed);
      _budgetController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  double _calculateTotalThisMonth(List<Expense> expenses) {
    final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    return expenses
        .where((e) => e.date.isAfter(startOfMonth))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.budget),
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
        data: (expenses) {
          final totalThisMonth = _calculateTotalThisMonth(expenses);
          final remaining = _monthlyBudget - totalThisMonth;
          final usedPercentage =
              _monthlyBudget > 0 ? totalThisMonth / _monthlyBudget : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Champ budget
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.monthlyBudget,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          style:
                              Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                          decoration: InputDecoration(
                            hintText: '0',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixText: 'FCFA',
                          ),
                          onChanged: _onBudgetChanged,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Barre de progression
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppStrings.used,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${NumberFormat('#,###', 'fr_FR').format(totalThisMonth)} FCFA',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: usedPercentage.clamp(0.0, 1.0),
                          backgroundColor: AppColors.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            usedPercentage > 0.8
                                ? AppColors.danger
                                : AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppStrings.remaining,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '${NumberFormat('#,###', 'fr_FR').format(remaining)} FCFA',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: remaining < 0
                                        ? AppColors.danger
                                        : AppColors.secondary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Message d'alerte
                _BudgetAlert(usedPercentage: usedPercentage),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BudgetAlert extends StatelessWidget {
  final double usedPercentage;
  const _BudgetAlert({required this.usedPercentage});

  @override
  Widget build(BuildContext context) {
    final pct = (usedPercentage * 100).toStringAsFixed(0);

    if (usedPercentage > 1.0) {
      return const _AlertCard(
        message: 'Attention, vous avez dépassé le budget mensuel !',
        icon: Icons.warning,
        color: AppColors.danger,
      );
    }
    if (usedPercentage > 0.8) {
      return _AlertCard(
        message: 'Attention, vous avez utilisé $pct% du budget mensuel !',
        icon: Icons.warning,
        color: AppColors.danger,
      );
    }
    if (usedPercentage > 0.5) {
      return _AlertCard(
        message: 'Vous avez utilisé $pct% du budget mensuel.',
        icon: Icons.info,
        color: Colors.orange,
      );
    }
    return _AlertCard(
      message: "Excellent ! Vous êtes dans les clous avec $pct% utilisé.",
      icon: Icons.check_circle,
      color: AppColors.secondary,
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const _AlertCard({
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: color)),
            ),
          ],
        ),
      ),
    );
  }
}
