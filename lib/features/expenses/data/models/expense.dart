/// Represents a single expense record.
///
/// Each expense contains the monetary [amount], a [currency] code,
/// [category] name, optional [note], [date] of the expense, optional
/// [paymentMethod], and creation timestamp [createdAt]. The [id] is
/// assigned by the database upon insertion.
class Expense {
  final int? id;
  final double amount;
  final String currency;
  final String category;
  final String? note;
  final DateTime date;
  final String? paymentMethod;
  final DateTime createdAt;

  const Expense({
    this.id,
    required this.amount,
    required this.currency,
    required this.category,
    required this.date,
    this.note,
    this.paymentMethod,
    required this.createdAt,
  });

  /// Returns a copy of this expense with updated fields.
  Expense copyWith({
    int? id,
    double? amount,
    String? currency,
    String? category,
    String? note,
    DateTime? date,
    String? paymentMethod,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts this expense to a map suitable for database insertion.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'category': category,
      'note': note,
      'date_ms': date.millisecondsSinceEpoch,
      'payment_method': paymentMethod,
      'created_at_ms': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Creates an expense from a database row.
  static Expense fromMap(Map<String, Object?> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      category: map['category'] as String,
      note: map['note'] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date_ms'] as int),
      paymentMethod: map['payment_method'] as String?,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['created_at_ms'] as int),
    );
  }
}
