import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/savings_goal.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/savings_goal_providers.dart';

class AddEditGoalScreen extends ConsumerStatefulWidget {
  const AddEditGoalScreen({super.key, this.existingGoal});

  final SavingsGoal? existingGoal;

  @override
  ConsumerState<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends ConsumerState<AddEditGoalScreen> {
  static const List<String> _goalCategories = [
    'Emergency Fund',
    'Vacation',
    'House',
    'Education',
    'Car',
    'Business',
    'Retirement',
    'Other',
  ];
  static const List<String> _goalPriorities = ['high', 'medium', 'low'];

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _targetAmountController;

  late String _selectedCategory;
  late String _selectedPriority;
  bool _hasDeadline = false;
  late DateTime _selectedDeadline;
  bool _isSaving = false;

  bool get _isEditing => widget.existingGoal != null;
  // Use a late final to ensure it's initialized but not changed later.

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _targetAmountController = TextEditingController()
      ..addListener(() {
        // Rebuild to update the required monthly savings info
        if (mounted) setState(() {});
      });
    final goal = widget.existingGoal;
    if (goal != null) {
      _titleController.text = goal.title;
      _descriptionController.text = goal.description;
      _targetAmountController.text = goal.targetAmount.toStringAsFixed(2);
      _selectedCategory = goal.category;
      _selectedPriority = goal.priority;
      _hasDeadline = goal.deadline != null;
      _selectedDeadline =
          goal.deadline ?? DateTime.now().add(const Duration(days: 30));
    } else {
      // Default values for a new goal
      _selectedCategory = _goalCategories.first;
      _selectedPriority = 'medium';
      _hasDeadline = false; // Start without a deadline by default.
      _selectedDeadline = DateTime.now()
          .add(const Duration(days: 365)); // Default to 1 year from now.
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    // Prevent assertion error if initialDate is slightly before firstDate
    final firstDate = _selectedDeadline.isBefore(now) ? _selectedDeadline : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 3650)), // 10 years
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final targetAmount = double.parse(_targetAmountController.text.trim());

      if (_isEditing) {
        final updated = widget.existingGoal!.copyWith(
          title: title,
          description: description,
          targetAmount: targetAmount,
          category: _selectedCategory,
          priority: _selectedPriority,
          deadline: _hasDeadline ? _selectedDeadline : null,
          currentAmount: widget.existingGoal!.currentAmount,
          completedDate: widget.existingGoal!.completedDate,
        );
        await ref
            .read(savingsGoalNotifierProvider.notifier)
            .updateGoal(updated);
      } else {
        await ref.read(savingsGoalNotifierProvider.notifier).addGoal(
              title: title,
              description: description,
              targetAmount: targetAmount,
              category: _selectedCategory,
              priority: _selectedPriority,
              deadline: _hasDeadline ? _selectedDeadline : null,
            );
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  double? _calculateRequiredMonthlySavings() {
    final targetAmount = double.tryParse(_targetAmountController.text.trim());
    if (!_hasDeadline || targetAmount == null || targetAmount <= 0) return null;

    final now = DateTime.now();
    if (!_selectedDeadline.isAfter(now)) {
      return null; // Deadline must be in the future
    }

    final differenceInDays = _selectedDeadline.difference(now).inDays;
    if (differenceInDays <= 0) return null;

    // Using 30.44 as the average number of days in a month
    final months = differenceInDays / 30.44;
    if (months <= 0) return null;

    final currentAmount = _isEditing ? widget.existingGoal!.currentAmount : 0.0;
    final remainingAmount = targetAmount - currentAmount;

    if (remainingAmount <= 0) return 0.0;

    return remainingAmount / months;
  }

  Future<void> _deleteGoalAndPop() async {
    if (!mounted) return;
    await ref
        .read(savingsGoalNotifierProvider.notifier)
        .deleteGoal(widget.existingGoal!.id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Savings Goal' : 'Create Savings Goal'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Goal'),
                    content: const Text('Delete this savings goal?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style:
                            FilledButton.styleFrom(backgroundColor: cs.error),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await _deleteGoalAndPop();
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
              // Title
              _buildLabel('Goal Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  hintText: 'e.g., Emergency Fund, Vacation, House',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
                autofocus: !_isEditing,
              ),
              const SizedBox(height: 24),

              // Description
              _buildLabel('Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                enabled: !_isSaving,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  hintText: 'Why do you need this goal?',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),

              // Target Amount
              _buildLabel('Target Amount (₹)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _targetAmountController,
                enabled: !_isSaving,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0',
                  prefixText: '${AppConstants.currencySymbol} ',
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

              // Category
              _buildLabel('Category'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select category',
                ),
                items: _goalCategories
                    .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                disabledHint: Text(_selectedCategory),
              ),
              const SizedBox(height: 24),

              // Priority
              _buildLabel('Priority'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedPriority,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select priority',
                ),
                items: _goalPriorities
                    .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p[0].toUpperCase() + p.substring(1))))
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedPriority = value);
                        }
                      },
                disabledHint: Text(_selectedPriority),
              ),
              const SizedBox(height: 24),

              // Deadline toggle
              SwitchListTile(
                title: const Text('Set a deadline?'),
                subtitle: const Text('Add target completion date'),
                value: _hasDeadline,
                activeThumbColor: cs.primary,
                onChanged: _isSaving
                    ? null
                    : (val) => setState(() {
                          _hasDeadline = val;
                        }),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),

              if (_hasDeadline) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: _isSaving ? null : _selectDate,
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
                          DateFormat('MMM dd, yyyy').format(_selectedDeadline),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_drop_down_rounded,
                            color: cs.onSurface.withValues(alpha: 0.5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMonthlySavingsInfo(),
              ],
              const SizedBox(height: 32),

              // Save button
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
                  label: Text(_isEditing ? 'Save Changes' : 'Create Goal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlySavingsInfo() {
    final requiredMonthly = _calculateRequiredMonthlySavings();
    if (requiredMonthly == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primaryContainer),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Required Monthly Savings',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${AppConstants.currencySymbol}${requiredMonthly.toStringAsFixed(0)} / month',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
