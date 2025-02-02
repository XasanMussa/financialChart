import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Transaction Analyzer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TransactionScreen(),
    );
  }
}

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final Telephony telephony = Telephony.instance;
  List<Transaction> transactions = [];
  bool _isLoading = false;
  bool _permissionDenied = false;

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _permissionDenied = false;
    });

    // Check and request SMS permission
    final status = await Permission.sms.request();
    if (!status.isGranted) {
      setState(() => _permissionDenied = true);
      return;
    }

    // Query SMS messages
    final messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      filter: SmsFilter.where(SmsColumn.ADDRESS).like('192'), // Fixed filter
    );
    final parsed = messages
        .map((msg) => Transaction.fromSms(msg.body ?? ''))
        .where((t) => t.amount > 0)
        .toList();

    setState(() {
      transactions = parsed;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Analyzer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_permissionDenied) {
      return _PermissionDeniedMessage(onRetry: _loadTransactions);
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transactions.isEmpty) {
      return const Center(child: Text('No transactions found'));
    }

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return TransactionCard(transaction: transaction);
      },
    );
  }
}

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
    // Determine transaction type
    final isExpense = message.toLowerCase().contains('uwareejisay');

    // Amount extraction
    final amountRegExp = RegExp(r'\$(\d+\.?\d*)');
    final amountMatch = amountRegExp.firstMatch(message);
    final amount =
        amountMatch != null ? double.parse(amountMatch.group(1)!) : 0.0;

    // Phone number extraction
    final phoneRegExp = RegExp(r'(\+?252\d{9})|(\d{9})');
    final phoneMatches = phoneRegExp.allMatches(message);
    final phoneNumber =
        phoneMatches.isNotEmpty ? phoneMatches.first.group(0) : null;

    // Date extraction
    final dateRegExp = RegExp(r'(\d{2}/\d{2}/\d{2} \d{2}:\d{2}:\d{2})');
    final dateMatch = dateRegExp.firstMatch(message);
    DateTime? date;

    if (dateMatch != null) {
      try {
        date = DateFormat('dd/MM/yy HH:mm:ss').parse(dateMatch.group(0)!);
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

class TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const TransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transaction.isExpense ? 'EXPENSE' : 'INCOME',
                  style: TextStyle(
                    color: transaction.isExpense ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '\$${transaction.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (transaction.phoneNumber != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Phone: ${transaction.phoneNumber}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            if (transaction.date != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(transaction.date!)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            Text(
              transaction.originalMessage,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionDeniedMessage extends StatelessWidget {
  final VoidCallback onRetry;

  const _PermissionDeniedMessage({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'SMS permission required to analyze transactions',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.security),
            label: const Text('Grant Permission'),
            onPressed: () async {
              await openAppSettings();
              onRetry();
            },
          ),
        ],
      ),
    );
  }
}
