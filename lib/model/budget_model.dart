import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final double amount;
  final DateTime month;
  final double spent;
  final String userId;

  Budget({
    required this.amount,
    required this.month,
    required this.spent,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'month': Timestamp.fromDate(month),
      'spent': spent,
      'userId': userId,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      amount: (map['amount'] as num).toDouble(),
      month: (map['month'] as Timestamp).toDate(),
      spent: (map['spent'] as num).toDouble(),
      userId: map['userId'] as String,
    );
  }
}
