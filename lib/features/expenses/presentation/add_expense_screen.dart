import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gestionbudget/features/expenses/domain/expense_model.dart';
import 'package:gestionbudget/shared/providers/couple_provider.dart';
import 'package:gestionbudget/shared/providers/expenses_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  Payer _payer = Payer.moi;
  ExpenseCategory _category = ExpenseCategory.nourriture;
  DateTime _date = DateTime.now();
  bool _isLoading = false;

  static const _primary = Color(0xFF6C63FF);

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _amountController.text.replaceAll(' ', '').replaceAll(' ', '');
    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un montant valide')),
      );
      return;
    }

    final couple = ref.read(coupleProvider);
    if (couple.userId == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(addExpenseProvider.notifier).addExpense(
            Expense(
              id: '',
              amount: amount,
              category: _category,
              payer: _payer,
              date: _date,
              note: _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
              userId: couple.userId!,
            ),
          );
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final couple = ref.watch(coupleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.go('/dashboard'),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: Color(0xFF1A1A2E)),
          ),
        ),
        title: const Text(
          'Ajouter une dépense',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Saisie du montant ─────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        _category.icon,
                        size: 44,
                        color: _primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  IntrinsicWidth(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                      decoration: const InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD1D5DB),
                        ),
                        suffix: Text(
                          ' FCFA',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: (v) {
                        final clean = v.replaceAll(RegExp(r'[^0-9]'), '');
                        if (clean.isEmpty) return;
                        final formatted =
                            NumberFormat('#,###', 'fr_FR').format(int.parse(clean));
                        _amountController.value = TextEditingValue(
                          text: formatted,
                          selection:
                              TextSelection.collapsed(offset: formatted.length),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Catégorie ─────────────────────────────────────
            const Text(
              'Catégorie',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ExpenseCategory.values.map((cat) {
                  final sel = _category == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 12),
                      width: 68,
                      decoration: BoxDecoration(
                        color: sel
                            ? cat.color.withValues(alpha: 0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: sel ? cat.color : const Color(0xFFE5E7EB),
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(cat.icon,
                              color: sel ? cat.color : const Color(0xFFB0B8C1),
                              size: 24),
                          const SizedBox(height: 6),
                          Text(
                            cat.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: sel
                                  ? cat.color
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // ── Qui a payé ? ──────────────────────────────────
            const Text(
              'Payé par',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _PayerButton(
                  label: couple.userName ?? 'Moi',
                  initial: (couple.userName ?? 'M')[0].toUpperCase(),
                  isSelected: _payer == Payer.moi,
                  color: _primary,
                  onTap: () => setState(() => _payer = Payer.moi),
                ),
                const SizedBox(width: 12),
                _PayerButton(
                  label: couple.partnerName ?? 'Elle',
                  initial: (couple.partnerName ?? 'E')[0].toUpperCase(),
                  isSelected: _payer == Payer.elle,
                  color: const Color(0xFFAB47BC),
                  onTap: () => setState(() => _payer = Payer.elle),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Date ──────────────────────────────────────────
            const Text(
              'Date',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate:
                      DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: _primary,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 18, color: _primary),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_date),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Note ─────────────────────────────────────────
            const Text(
              'Note (optionnel)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ajoute une note…',
                hintStyle:
                    const TextStyle(color: Color(0xFFB0B8C1), fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 32),

            // ── Bouton Ajouter ────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: _primary.withValues(alpha: 0.5),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Ajouter',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayerButton extends StatelessWidget {
  final String label;
  final String initial;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _PayerButton({
    required this.label,
    required this.initial,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE5E7EB),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? color : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? color : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
