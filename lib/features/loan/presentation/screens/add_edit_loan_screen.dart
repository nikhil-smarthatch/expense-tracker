import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/loan_type.dart';
import '../providers/loan_providers.dart';

class AddEditLoanScreen extends ConsumerStatefulWidget {
  const AddEditLoanScreen({super.key});

  @override
  ConsumerState<AddEditLoanScreen> createState() => _AddEditLoanScreenState();
}

class _AddEditLoanScreenState extends ConsumerState<AddEditLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  LoanType _selectedType = LoanType.borrow;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final amount = double.parse(_amountController.text.trim());
    final note = _noteController.text.trim();

    try {
      await ref.read(loansProvider.notifier).addLoan(
        type: _selectedType,
        personName: _nameController.text.trim(),
        totalAmount: amount,
        date: _selectedDate,
        note: note.isEmpty ? null : note,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Loan record')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: SegmentedButton<LoanType>(
                  segments: const [
                    ButtonSegment(value: LoanType.borrow, label: Text('I Borrowed')),
                    ButtonSegment(value: LoanType.lend, label: Text('I Lent')),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (set) => setState(() => _selectedType = set.first),
                ),
              ),
              const SizedBox(height: 24),
              _Label('Person Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'e.g. John Doe'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              _Label('Amount (₹)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: '0.00', prefixText: '₹ '),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed <= 0) return 'Valid amount required';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _Label('Date'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 20, color: cs.primary),
                      const SizedBox(width: 12),
                      Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _Label('Note (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'Add an optional note...'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_rounded),
                  label: const Text('Save Record'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600));
}
