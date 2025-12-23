import 'package:sqflite/sqflite.dart';

import '../db/app_db.dart';
import '../models/expense.dart';

/// Repository layer for accessing and manipulating expenses.
///
/// Encapsulates the SQLite interactions so that the rest of the
/// application can work with plain Dart objects. In future
/// iterations this class can be extended to synchronize with a
/// remote backend or expose reactive streams.
class ExpenseRepository {
  final AppDb _db = AppDb();
  Database? _database;

  /// Initializes the underlying database. Must be called before
  /// performing any operations.
  Future<void> init() async {
    _database = await _db.database;
  }

  /// Adds a new expense to the database.
  Future<int> addExpense(Expense expense) async {
    final db = _database ?? await _db.database;
    return db.insert('expenses', expense.toMap());
  }

  /// Retrieves all expenses for a given month. Expenses are
  /// returned in descending order by date and creation time.
  Future<List<Expense>> getExpensesForMonth(DateTime month) async {
    final db = _database ?? await _db.database;

    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 1);

    final rows = await db.query(
      'expenses',
      where: 'date_ms >= ? AND date_ms < ?',
      whereArgs: [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
      orderBy: 'date_ms DESC, created_at_ms DESC',
    );

    return rows.map(Expense.fromMap).toList();
  }

  /// Closes the database.
  Future<void> dispose() async {
    await _db.close();
  }
}