import 'package:deepseek_chart/pages/dashboard_screen.dart';
import 'package:deepseek_chart/sms_analyzer.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';

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

    final status = await Permission.sms.request();
    if (!status.isGranted) {
      setState(() => _permissionDenied = true);
      return;
    }

    final messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      filter: SmsFilter.where(SmsColumn.ADDRESS).like('192'),
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

  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Analyzer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DashboardScreen(transactions: transactions),
              ),
            ),
          ),
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (transactions.isEmpty) {
      return const Center(child: Text('No transactions found'));
    }

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) =>
          TransactionCard(transaction: transactions[index]),
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
