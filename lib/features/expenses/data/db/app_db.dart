import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Provides access to the local SQLite database used to store expenses.
///
/// This class encapsulates the logic for creating and opening the
/// database, including the schema definition for the `expenses` table.
class AppDb {
  static const _dbName = 'expense_app.db';
  static const _dbVersion = 1;

  Database? _db;

  /// Lazily opens or returns the existing database instance.
  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;

    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, _dbName);

    _db = await openDatabase(
      fullPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        // Create the expenses table with basic columns.
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            currency TEXT NOT NULL,
            category TEXT NOT NULL,
            note TEXT,
            date_ms INTEGER NOT NULL,
            payment_method TEXT,
            created_at_ms INTEGER NOT NULL
          );
        ''');

        await db
            .execute('CREATE INDEX idx_expenses_date ON expenses(date_ms);');
        await db.execute(
            'CREATE INDEX idx_expenses_category ON expenses(category);');
      },
    );

    return _db!;
  }

  /// Closes the database when no longer needed.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
