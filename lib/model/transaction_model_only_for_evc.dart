import 'package:intl/intl.dart';

class Transaction {
  final bool isExpense;
  final double amount;
  final String? phoneNumber;
  final DateTime? date;
  final String originalMessage;

  Transaction({
    required this.isExpense,
    required this.amount,
    this.phoneNumber,
    this.date,
    required this.originalMessage,
  });

  factory Transaction.fromSms(String message) {
    // Determine transaction type for EVC and eDahab
    final isExpense = message.toLowerCase().contains('u warejisay') ||
        message.toLowerCase().contains('wareejisay') ||
        message.toLowerCase().contains('ku shubtay');

    // Check for eDahab-specific keywords to identify income or expense
    if (message.toLowerCase().contains('ka heshay') ||
        message.toLowerCase().contains('ayaad ka heshay')) {
      // If eDahab message contains "Ka Heshay" or "Ayaad Ka Heshay", it's an income
      return Transaction._fromMessage(message, isExpense: false);
    } else if (message.toLowerCase().contains('u warejisay') ||
        message.toLowerCase().contains('wareejisay')) {
      // If eDahab message contains "u warejisay", it's an expense
      return Transaction._fromMessage(message, isExpense: true);
    }

    // Default to EVC behavior for unhandled cases (assuming it's expense)
    return Transaction._fromMessage(message, isExpense: isExpense);
  }

  // Helper constructor to extract common fields
  static Transaction _fromMessage(String message, {required bool isExpense}) {
    // Amount extraction for both EVC and eDahab
    final amountRegExp = RegExp(r'\$(\d+\.?\d*)|(\d+\.?\d*) Dollar');
    final amountMatch = amountRegExp.firstMatch(message);
    final amount = amountMatch != null
        ? double.parse(amountMatch.group(1) ?? amountMatch.group(2)!)
        : 0.0;

    // Phone number extraction for both EVC and eDahab
    final phoneRegExp = RegExp(r'(\+?252\d{9})|(\d{9})');
    final phoneMatches = phoneRegExp.allMatches(message);
    final phoneNumber =
        phoneMatches.isNotEmpty ? phoneMatches.first.group(0) : null;

    // Date extraction: eDahab uses dd-MM-yyyy, EVC uses dd/MM/yy format
    final dateRegExp = RegExp(r'(\d{2}[-/]\d{2}[-/]\d{4}|\d{2}/\d{2}/\d{2})');
    final dateMatch = dateRegExp.firstMatch(message);
    DateTime? date;

    if (dateMatch != null) {
      try {
        if (dateMatch.group(0)!.contains("-")) {
          // eDahab date format
          date = DateFormat('dd-MM-yyyy').parse(dateMatch.group(0)!);
        } else {
          // EVC date format
          date = DateFormat('dd/MM/yy').parse(dateMatch.group(0)!);
        }
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    return Transaction(
      isExpense: isExpense,
      amount: amount,
      phoneNumber: phoneNumber,
      date: date,
      originalMessage: message,
    );
  }
}
