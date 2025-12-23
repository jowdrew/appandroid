import 'package:equatable/equatable.dart';

import '../../data/models/expense.dart';

/// Represents the state of the expenses dashboard and list.
class ExpensesState extends Equatable {
  /// Whether data is loading from the repository.
  final bool loading;

  /// The month currently being displayed. Represented by the
  /// first day of that month.
  final DateTime month;

  /// All expenses for the current [month] sorted by date.
  final List<Expense> expenses;

  /// The sum of all expenses for the current [month].
  final double total;

  /// Map of category names to their total amounts for the current [month].
  final Map<String, double> byCategory;

  const ExpensesState({
    required this.loading,
    required this.month,
    required this.expenses,
    required this.total,
    required this.byCategory,
  });

  /// Initial state with loading set to true for the current month.
  factory ExpensesState.initial() {
    final now = DateTime.now();
    return ExpensesState(
      loading: true,
      month: DateTime(now.year, now.month, 1),
      expenses: const [],
      total: 0,
      byCategory: const {},
    );
  }

  /// Creates a new state by copying the current one and replacing
  /// provided values.
  ExpensesState copyWith({
    bool? loading,
    DateTime? month,
    List<Expense>? expenses,
    double? total,
    Map<String, double>? byCategory,
  }) {
    return ExpensesState(
      loading: loading ?? this.loading,
      month: month ?? this.month,
      expenses: expenses ?? this.expenses,
      total: total ?? this.total,
      byCategory: byCategory ?? this.byCategory,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        month.year,
        month.month,
        expenses.length,
        total,
        byCategory.length,
      ];
}