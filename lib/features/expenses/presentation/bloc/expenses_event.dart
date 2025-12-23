import 'package:equatable/equatable.dart';

import '../../data/models/expense.dart';

/// Base type for all expense events handled by the [ExpensesBloc].
abstract class ExpensesEvent extends Equatable {
  const ExpensesEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered when the app first loads or when a refresh is requested.
class ExpensesStarted extends ExpensesEvent {
  const ExpensesStarted();
}

/// Triggered when the user navigates to a different month in the
/// dashboard. Contains the target month (year and month values).
class ExpensesMonthChanged extends ExpensesEvent {
  final DateTime month;
  const ExpensesMonthChanged(this.month);

  @override
  List<Object?> get props => [month.year, month.month];
}

/// Triggered after a new expense has been created via the UI.
class ExpenseAdded extends ExpensesEvent {
  final Expense expense;
  const ExpenseAdded(this.expense);

  @override
  List<Object?> get props => [expense.amount, expense.category, expense.date];
}