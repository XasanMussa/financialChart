import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';

class Transaction {
  final bool isExpense;
  final double amount;
  final String? phoneNumber;
  final DateTime? date;
  final String originalMessage;
  final String category; // New field to specify category (eDahab or EVC)
  final String transactionID; // Unique ID for the transaction

  Transaction({
    required this.isExpense,
    required this.amount,
    this.phoneNumber,
    this.date,
    required this.originalMessage,
    required this.category, // Initialize category
    required this.transactionID, // Initialize transactionID
  });

  factory Transaction.fromSms(String message) {
    bool isExpense = message.toLowerCase().contains('u warejisay') ||
        message.toLowerCase().contains('wareejisay') ||
        message.toLowerCase().contains('ku shubtay');

    // Check if it's eDahab or EVC by looking for keywords or unique patterns in the message
    String category = '';

    if (message.contains('[-eDahab-Service-]')) {
      category = 'eDahab';
      if (message.toLowerCase().contains('ka heshay') ||
          message.toLowerCase().contains('ayaad ka heshay')) {
        return Transaction._fromMessage(message,
            isExpense: false, category: category);
      } else if (message.toLowerCase().contains('u warejisay') ||
          message.toLowerCase().contains('wareejisay')) {
        return Transaction._fromMessage(message,
            isExpense: true, category: category);
      }
    } else if (message.contains('[-EVCPlus-]')) {
      category = 'EVC';
      return Transaction._fromMessage(message,
          isExpense: isExpense, category: category);
    }

    return Transaction._fromMessage(message,
        isExpense: isExpense, category: 'EVC');
  }

  // Helper constructor to extract common fields and category
  static Transaction _fromMessage(String message,
      {required bool isExpense, required String category}) {
    final amountRegExp = RegExp(r'\$(\d+\.?\d*)|(\d+\.?\d*) Dollar');
    final amountMatch = amountRegExp.firstMatch(message);
    final amount = amountMatch != null
        ? double.parse(amountMatch.group(1) ?? amountMatch.group(2)!)
        : 0.0;

    // Updated phone number regex to ensure it captures all digits
    final phoneRegExp = RegExp(r'(\+?252\d{9})|(\d{9,10})');
    final phoneMatches = phoneRegExp.allMatches(message);
    String? phoneNumber;

    if (phoneMatches.isNotEmpty) {
      phoneNumber = phoneMatches.first.group(0);
      // Ensure the phone number is exactly 10 digits
      if (phoneNumber != null && phoneNumber.length > 10) {
        phoneNumber = phoneNumber.substring(phoneNumber.length - 10);
      }
    }

    final dateRegExp = RegExp(r'(\d{2}[-/]\d{2}[-/]\d{4}|\d{2}/\d{2}/\d{2})');
    final dateMatch = dateRegExp.firstMatch(message);
    DateTime? date;

    if (dateMatch != null) {
      try {
        if (dateMatch.group(0)!.contains("-")) {
          date = DateFormat('dd-MM-yyyy').parse(dateMatch.group(0)!);
        } else {
          date = DateFormat('dd/MM/yy').parse(dateMatch.group(0)!);
        }
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    // Generate the transactionID using a hash of the transaction details
    String transactionID =
        generateTransactionId(message, amount, phoneNumber, date, category);

    return Transaction(
      isExpense: isExpense,
      amount: amount,
      phoneNumber: phoneNumber,
      date: date,
      originalMessage: message,
      category: category,
      transactionID: transactionID,
    );
  }

  // Generate a unique transaction ID by hashing the relevant fields
  static String generateTransactionId(String message, double amount,
      String? phoneNumber, DateTime? date, String category) {
    var baseString = '$amount$phoneNumber${date?.toIso8601String()}$category';
    var bytes = utf8.encode(baseString); // Convert the string to bytes
    var digest = sha256.convert(bytes); // Generate the SHA-256 hash
    return digest.toString(); // Return the hash as a string
  }
}
