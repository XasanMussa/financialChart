import 'package:intl/intl.dart';

class Transaction {
  final bool isExpense;
  final double amount;
  final String? phoneNumber;
  final DateTime? date;
  final String originalMessage;
  final String category; // New field to specify category (eDahab or EVC)

  Transaction({
    required this.isExpense,
    required this.amount,
    this.phoneNumber,
    this.date,
    required this.originalMessage,
    required this.category, // Initialize category
  });

  factory Transaction.fromSms(String message) {
    bool isExpense = message.toLowerCase().contains('u warejisay') ||
        message.toLowerCase().contains('wareejisay') ||
        message.toLowerCase().contains('ku shubtay');

    // Check if it's eDahab or EVC by looking for keywords or unique patterns in the message
    String category = '';

    if (message.contains('[-eDahab-Service-]')) {
      category = 'eDahab';
      // eDahab specific logic
      if (message.toLowerCase().contains('ka heshay') ||
          message.toLowerCase().contains('ayaad ka heshay')) {
        // Income for eDahab
        return Transaction._fromMessage(message,
            isExpense: false, category: category);
      } else if (message.toLowerCase().contains('u warejisay') ||
          message.toLowerCase().contains('wareejisay')) {
        // Expense for eDahab
        return Transaction._fromMessage(message,
            isExpense: true, category: category);
      }
    } else if (message.contains('[-EVCPlus-]')) {
      category = 'EVC';
      // EVC specific logic
      return Transaction._fromMessage(message,
          isExpense: isExpense, category: category);
    }

    // If the category couldn't be determined, return a default (EVC)
    return Transaction._fromMessage(message,
        isExpense: isExpense, category: 'EVC');
  }

  // Helper constructor to extract common fields and category
  static Transaction _fromMessage(String message,
      {required bool isExpense, required String category}) {
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
      category: category, // Set the category
    );
  }
}
