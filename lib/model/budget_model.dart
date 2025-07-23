import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final double amount;
  final DateTime month;
  final double spent;
  final String userId;
  final bool notified50;
  final bool notified90;
  final bool notified100;

  Budget({
    required this.amount,
    required this.month,
    required this.spent,
    required this.userId,
    this.notified50 = false,
    this.notified90 = false,
    this.notified100 = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'month': month,
      'spent': spent,
      'userId': userId,
      'notified50': notified50,
      'notified90': notified90,
      'notified100': notified100,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      amount: (map['amount'] as num).toDouble(),
      month: (map['month'] as Timestamp).toDate(),
      spent: (map['spent'] as num).toDouble(),
      userId: map['userId'] as String,
      notified50: map['notified50'] as bool? ?? false,
      notified90: map['notified90'] as bool? ?? false,
      notified100: map['notified100'] as bool? ?? false,
    );
  }

  Budget copyWith({
    double? amount,
    DateTime? month,
    double? spent,
    String? userId,
    bool? notified50,
    bool? notified90,
    bool? notified100,
  }) {
    return Budget(
      amount: amount ?? this.amount,
      month: month ?? this.month,
      spent: spent ?? this.spent,
      userId: userId ?? this.userId,
      notified50: notified50 ?? this.notified50,
      notified90: notified90 ?? this.notified90,
      notified100: notified100 ?? this.notified100,
    );
  }
}
