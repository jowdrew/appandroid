import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/expense.dart';

/// Bottom sheet allowing the user to quickly enter a new expense.
///
/// Provides a numeric text field for the amount, dropdowns for category
/// and currency, a text field for notes, a date picker, and a final
/// save button. Returns an [AddExpenseResult] when the user taps
/// "Guardar" or null if cancelled.
class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  // Predefined categories for quick selection. In a future version
  // categories could be managed by the user and stored in the DB.
  final List<String> _categories = const [
    'Comida',
    'Transporte',
    'Casa',
    'Ocio',
    'Salud',
    'Compras',
    'Otros',
  ];

  String _selectedCategory = 'Comida';
  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = 'PEN';
  String? _selectedPaymentMethod;

  final List<String> _paymentMethods = const [
    'Efectivo',
    'Tarjeta',
    'Yape',
    'Plin',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Adjust bottom padding to account for the keyboard.
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + viewInsets),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Registrar gasto',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Monto',
              prefixText: _selectedCurrency == 'PEN' ? 'S/\u00a0' : '\$\u00a0',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) =>
                setState(() => _selectedCategory = v ?? _selectedCategory),
            decoration: const InputDecoration(
              labelText: 'Categoría',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Nota (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          // Row containing date picker and currency selection
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020, 1, 1),
                      lastDate: DateTime(2100, 12, 31),
                      initialDate: _selectedDate,
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCurrency,
                  items: const [
                    DropdownMenuItem(value: 'PEN', child: Text('PEN')),
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Moneda',
                  ),
                  onChanged: (v) => setState(
                      () => _selectedCurrency = v ?? _selectedCurrency),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Payment method selector (optional)
          DropdownButtonFormField<String>(
            initialValue: _selectedPaymentMethod,
            items: _paymentMethods
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => _selectedPaymentMethod = v),
            decoration: const InputDecoration(
              labelText: 'Método de pago (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final raw = _amountController.text.trim().replaceAll(',', '.');
                final amount = double.tryParse(raw);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingresa un monto válido.')),
                  );
                  return;
                }
                Navigator.pop(
                  context,
                  AddExpenseResult(
                    amount: amount,
                    currency: _selectedCurrency,
                    category: _selectedCategory,
                    note: _noteController.text.trim().isEmpty
                        ? null
                        : _noteController.text.trim(),
                    date: _selectedDate,
                    paymentMethod: _selectedPaymentMethod,
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Container object used to return values from the bottom sheet.
class AddExpenseResult {
  final double amount;
  final String currency;
  final String category;
  final String? note;
  final DateTime date;
  final String? paymentMethod;

  const AddExpenseResult({
    required this.amount,
    required this.currency,
    required this.category,
    required this.note,
    required this.date,
    this.paymentMethod,
  });

  /// Converts the result into an [Expense] model. The creation
  /// timestamp is set to the current time.
  Expense toExpense() {
    return Expense(
      amount: amount,
      currency: currency,
      category: category,
      note: note,
      date: date,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
    );
  }
}
