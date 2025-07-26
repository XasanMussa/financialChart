import 'package:personal_finance_tracker/model/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const TransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                transaction.isExpense
                    ? 'EXPENSE (${transaction.category})'
                    : 'INCOME (${transaction.category})',
                style: TextStyle(
                  color: transaction.isExpense ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '\$${transaction.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Colors.blueGrey),
          if (transaction.phoneNumber != null &&
              transaction.phoneNumber!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Phone: ${transaction.phoneNumber}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          if (transaction.date != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(transaction.date!)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          Text(
            transaction.originalMessage,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
