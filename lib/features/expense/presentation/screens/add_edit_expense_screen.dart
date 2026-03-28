import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';
import '../providers/expense_providers.dart';
import '../widgets/category_chip.dart';

class AddEditExpenseScreen extends ConsumerStatefulWidget {
  const AddEditExpenseScreen({super.key, this.existingExpense});

  /// If editing, pass the existing expense; null means adding new.
  final Expense? existingExpense;

  @override
  ConsumerState<AddEditExpenseScreen> createState() =>
      _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late ExpenseCategory _selectedCategory;
  late DateTime _selectedDate;
  bool _isSaving = false;
  
  bool _isIncome = false;
  String? _receiptPath;

  bool get _isEditing => widget.existingExpense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existingExpense;
    _selectedCategory = e?.category ?? ExpenseCategory.food;
    _selectedDate = e?.date ?? DateTime.now();
    _isIncome = e?.isIncome ?? false;
    _receiptPath = e?.receiptPath;

    if (e != null) {
      _amountController.text = e.amount.toStringAsFixed(2);
      _noteController.text = e.note ?? '';
    }
  }

  @override
  void dispose() {
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

  Future<void> _pickReceipt() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 800,
      );
      if (image == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final name = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final savedImage = await File(image.path).copy('${directory.path}/$name');

      setState(() {
        _receiptPath = savedImage.path;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error attaching receipt: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final amount = double.parse(_amountController.text.trim());
    final note = _noteController.text.trim();

    try {
      if (_isEditing) {
        final updated = widget.existingExpense!.copyWith(
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
          note: note.isEmpty ? null : note,
          clearNote: note.isEmpty,
          isIncome: _isIncome,
          receiptPath: _receiptPath,
          clearReceipt: _receiptPath == null,
        );
        await ref.read(expensesProvider.notifier).updateExpense(updated);
      } else {
        await ref.read(expensesProvider.notifier).addExpense(
              amount: amount,
              category: _selectedCategory,
              date: _selectedDate,
              note: note.isEmpty ? null : note,
              isIncome: _isIncome,
              receiptPath: _receiptPath,
            );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Transaction'),
                    content: const Text('Delete this transaction?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel')),
                      FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: cs.error),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirmed == true && mounted) {
                  await ref
                      .read(expensesProvider.notifier)
                      .deleteExpense(widget.existingExpense!.id);
                  if (mounted) Navigator.of(context).pop();
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Toggle
              Center(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Expense'), icon: Icon(Icons.arrow_upward_rounded)),
                    ButtonSegment(value: true, label: Text('Income'), icon: Icon(Icons.arrow_downward_rounded)),
                  ],
                  selected: {_isIncome},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      _isIncome = newSelection.first;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Amount Field
              _Label('Amount (₹)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: !_isEditing,
                decoration: const InputDecoration(
                  hintText: '0.00',
                  prefixText: '₹ ',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null) return 'Enter a valid number';
                  if (parsed <= 0) return 'Amount must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Category Selection
              _Label('Category'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExpenseCategory.values
                    .map((category) => CategoryChip(
                          category: category,
                          isSelected: _selectedCategory == category,
                          onTap: () =>
                              setState(() => _selectedCategory = category),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),

              // Date Picker
              _Label('Date'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 20, color: cs.primary),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down_rounded,
                          color: cs.onSurface.withOpacity(0.5)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Note Field
              _Label('Note (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  hintText: 'Add a short description...',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),

              // Receipt Attachment
              _Label('Receipt Attachment'),
              const SizedBox(height: 8),
              if (_receiptPath != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_receiptPath!),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle),
                      color: Colors.red,
                      onPressed: () => setState(() => _receiptPath = null),
                    ),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: _pickReceipt,
                  icon: const Icon(Icons.add_a_photo_rounded),
                  label: const Text('Attach Receipt'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_isEditing ? 'Save Changes' : 'Add Transaction'),
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
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
