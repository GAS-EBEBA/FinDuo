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

  ExpenseCategory _category = ExpenseCategory.nourriture;
  DateTime _date = DateTime.now();
  bool _isLoading = false;

  static const _primary = Color(0xFF5B52EE);
  static const _secondary = Color(0xFF7C73F6);
  static const _bg = Color(0xFFF4F6FB);
  static const _card = Colors.white;
  static const _dark = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE5EAF3);

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = raw.isEmpty ? null : double.tryParse(raw);
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
      final coupleId = await ref.read(coupleFutureProvider.future);
      final creatorName = (couple.userName?.isNotEmpty ?? false)
          ? couple.userName!
          : 'Moi';

      await ref
          .read(addExpenseProvider.notifier)
          .addExpense(
            Expense(
              id: '',
              amount: amount,
              category: _category,
              payerName: creatorName,
              creatorName: creatorName,
              date: _date,
              note: _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
              userId: couple.userId!,
              coupleId: coupleId,
            ),
          );

      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primary,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _formatAmount(String value) {
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      _amountController.value = const TextEditingValue(text: '');
      return;
    }
    final formatted = NumberFormat('#,###', 'fr_FR').format(int.parse(clean));
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String get _formattedDate => DateFormat('d MMMM yyyy', 'fr_FR').format(_date);

  String get _amountPreview {
    final raw = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) return '0 F';
    return '${NumberFormat('#,###', 'fr_FR').format(int.parse(raw))} F';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      bottomNavigationBar: _buildBottomAction(),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              _buildHeroCard(),
              const SizedBox(height: 18),
              _buildMetaStrip(),
              const SizedBox(height: 18),
              _buildSectionCard(
                title: 'Catégorie',
                subtitle:
                    'Choisis le type de dépense pour mieux suivre le budget.',
                child: _buildCategoryGrid(),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Note',
                subtitle: 'Ajoute un petit contexte si nécessaire.',
                child: _buildNoteField(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go('/dashboard'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: _dark,
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouvelle dépense',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _dark,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Enregistre une sortie en quelques secondes.',
                style: TextStyle(
                  fontSize: 13,
                  color: _muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: .24),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _category.color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _category.color.withValues(alpha: .18),
                  ),
                ),
                child: Icon(_category.icon, color: _category.color, size: 30),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _category.displayName,
                  style: TextStyle(
                    color: _category.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Montant',
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: _dark,
              letterSpacing: -1,
            ),
            decoration: const InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 42,
                fontWeight: FontWeight.w900,
              ),
              border: InputBorder.none,
              isCollapsed: true,
            ),
            onChanged: _formatAmount,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'FCFA',
                  style: TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ajoute le montant exact pour garder un historique propre.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaStrip() {
    return Row(
      children: [
        Expanded(
          child: _buildMetaCard(
            icon: Icons.calendar_month_rounded,
            label: 'Date',
            value: _formattedDate,
            color: _primary,
            onTap: _pickDate,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetaCard(
            icon: _category.icon,
            label: 'Aperçu',
            value: _amountPreview,
            color: _category.color,
          ),
        ),
      ],
    );
  }

  Widget _buildMetaCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: .04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _dark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: .04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: _muted, height: 1.4),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ExpenseCategory.values.map((cat) {
            final isSelected = _category == cat;
            return GestureDetector(
              onTap: () => setState(() => _category = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: itemWidth,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? cat.color.withValues(alpha: .1) : _bg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? cat.color : _border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cat.color.withValues(
                          alpha: isSelected ? .18 : .1,
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(cat.icon, color: cat.color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cat.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? cat.color : _dark,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: cat.color,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildNoteField() {
    return TextField(
      controller: _noteController,
      maxLines: 4,
      maxLength: 150,
      style: const TextStyle(fontSize: 14, color: _dark, height: 1.5),
      decoration: InputDecoration(
        hintText: 'Ex: Courses du week-end, taxi pour le bureau...',
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        filled: true,
        fillColor: _bg,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: _primary.withValues(alpha: .8),
            width: 1.5,
          ),
        ),
        counterStyle: const TextStyle(
          color: _muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 20,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'Montant saisi',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  _amountPreview,
                  style: TextStyle(
                    color: _category.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primary, _secondary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: .28),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _save,
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Ajouter la dépense',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
