import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/expense_repository.dart';
import 'expenses_event.dart';
import 'expenses_state.dart';

/// Business logic component for managing expenses.
///
/// Listens for [ExpensesEvent]s and emits [ExpensesState]s. It
/// coordinates loading expenses from the repository, responding to
/// month changes, and handling new expense additions.
class ExpensesBloc extends Bloc<ExpensesEvent, ExpensesState> {
  final ExpenseRepository repository;

  ExpensesBloc(this.repository) : super(ExpensesState.initial()) {
    on<ExpensesStarted>(_onStarted);
    on<ExpensesMonthChanged>(_onMonthChanged);
    on<ExpenseAdded>(_onExpenseAdded);
  }

  Future<void> _reload(DateTime month, Emitter<ExpensesState> emit) async {
    emit(state.copyWith(loading: true, month: month));

    final expenses = await repository.getExpensesForMonth(month);

    double total = 0;
    final categoryTotals = <String, double>{};
    for (final e in expenses) {
      total += e.amount;
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }

    emit(state.copyWith(
      loading: false,
      expenses: expenses,
      total: total,
      byCategory: categoryTotals,
    ));
  }

  Future<void> _onStarted(
      ExpensesStarted event, Emitter<ExpensesState> emit) async {
    await _reload(state.month, emit);
  }

  Future<void> _onMonthChanged(
      ExpensesMonthChanged event, Emitter<ExpensesState> emit) async {
    final targetMonth = DateTime(event.month.year, event.month.month, 1);
    await _reload(targetMonth, emit);
  }

  Future<void> _onExpenseAdded(
      ExpenseAdded event, Emitter<ExpensesState> emit) async {
    await repository.addExpense(event.expense);
    await _reload(state.month, emit);
  }
}
