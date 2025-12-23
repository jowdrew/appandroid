import 'package:appandroid/core/utils/money.dart';
import 'package:appandroid/features/expenses/data/models/expense.dart';
import 'package:appandroid/features/expenses/data/repositories/expense_repository.dart';
import 'package:appandroid/features/expenses/presentation/bloc/expenses_bloc.dart';
import 'package:appandroid/features/expenses/presentation/bloc/expenses_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class FakeExpenseRepository implements ExpenseRepository {
  FakeExpenseRepository({List<Expense>? seed}) : _items = [...?seed];

  final List<Expense> _items;

  @override
  Future<void> init() async {}

  @override
  Future<int> addExpense(Expense expense) async {
    final nextId = _items.length + 1;
    _items.add(expense.copyWith(id: nextId));
    return nextId;
  }

  @override
  Future<List<Expense>> getExpensesForMonth(DateTime month) async {
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 1);

    final filtered = _items.where((e) {
      return !e.date.isBefore(from) && e.date.isBefore(to);
    }).toList();

    filtered.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  test('formatMoney uses PEN by default', () {
    expect(formatMoney(1234.5), '1.234,50\u00a0S/\u00a0');
  });

  test('ExpensesBloc aggregates totals for the active month', () async {
    final now = DateTime.now();
    final repository = FakeExpenseRepository(seed: [
      Expense(
        id: 1,
        amount: 42.5,
        currency: 'PEN',
        category: 'Comida',
        note: 'Almuerzo',
        date: DateTime(now.year, now.month, 10),
        paymentMethod: 'Efectivo',
        createdAt: DateTime(now.year, now.month, 10, 12),
      ),
      Expense(
        id: 2,
        amount: 18.25,
        currency: 'PEN',
        category: 'Transporte',
        note: 'Taxi',
        date: DateTime(now.year, now.month - 1, 28),
        paymentMethod: 'Yape',
        createdAt: DateTime(now.year, now.month - 1, 28, 9),
      ),
    ]);
    await repository.init();
    final bloc = ExpensesBloc(repository);

    addTearDown(() async {
      await bloc.close();
      await repository.dispose();
    });

    bloc.add(const ExpensesStarted());
    final initialState = await bloc.stream
        .firstWhere((s) => !s.loading)
        .timeout(const Duration(seconds: 2));

    expect(initialState.expenses.length, 1);
    expect(initialState.total, closeTo(42.5, 0.001));
    expect(initialState.byCategory['Comida'], closeTo(42.5, 0.001));

    final newExpense = Expense(
      amount: 18.25,
      currency: 'PEN',
      category: 'Transporte',
      note: 'Taxi',
      date: now,
      paymentMethod: 'Yape',
      createdAt: now,
    );

    bloc.add(ExpenseAdded(newExpense));
    final updatedState = await bloc.stream
        .firstWhere((s) => !s.loading && s.expenses.length == 2)
        .timeout(const Duration(seconds: 2));

    expect(updatedState.total, closeTo(60.75, 0.001));
    expect(updatedState.byCategory['Transporte'], closeTo(18.25, 0.001));
  });
}
