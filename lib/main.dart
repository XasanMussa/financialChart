import 'package:deepseek_chart/sms_analyzer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';
import 'package:fl_chart/fl_chart.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SMS Transaction Analyzer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        cardColor: const Color(0xFF1D1E33),
      ),
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
    if (transactions.isEmpty)
      return const Center(child: Text('No transactions found'));

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

class DashboardScreen extends StatefulWidget {
  final List<Transaction> transactions;

  const DashboardScreen({super.key, required this.transactions});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDate = DateTime.now();

  double get totalIncome => widget.transactions
      .where((t) => !t.isExpense && _isSameMonth(t.date, _selectedDate))
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => widget.transactions
      .where((t) => t.isExpense && _isSameMonth(t.date, _selectedDate))
      .fold(0.0, (sum, t) => sum + t.amount);

  bool _isSameMonth(DateTime? date, DateTime selected) {
    return date != null &&
        date.month == selected.month &&
        date.year == selected.year;
  }

  @override
  Widget build(BuildContext context) {
    final profit = totalIncome - totalExpense;
    final formatter = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSummaryCards(
                      formatter, totalIncome, totalExpense, profit),
                  const SizedBox(height: 20),
                  _buildBarChart(),
                  const SizedBox(height: 20),
                  // _buildExpensePieChart(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
      NumberFormat formatter, double income, double expense, double profit) {
    return Row(
      children: [
        _SummaryCard(
          title: 'Income',
          value: formatter.format(income),
          color: Colors.green,
        ),
        _SummaryCard(
          title: 'Expense',
          value: formatter.format(expense),
          color: Colors.red,
        ),
        _SummaryCard(
          title: 'Profit',
          value: formatter.format(profit),
          color: profit >= 0 ? Colors.blue : Colors.orange,
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    return Card(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Monthly Comparison',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.green,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: false),
                  alignment: BarChartAlignment.spaceAround,
                  maxY: [totalIncome, totalExpense]
                          .reduce((a, b) => a > b ? a : b) *
                      1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles()),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text(
                          DateFormat.MMM().format(_selectedDate),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                            toY: totalIncome, color: Colors.green, width: 16)
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                            toY: totalExpense, color: Colors.red, width: 16)
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensePieChart() {
    final categoryMap = <String, double>{};
    for (var t in widget.transactions
        .where((t) => t.isExpense && _isSameMonth(t.date, _selectedDate))) {
      categoryMap.update(
        t.phoneNumber ?? 'Unknown',
        (value) => value + t.amount,
        ifAbsent: () => t.amount,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Expense Breakdown', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  sections: categoryMap.entries
                      .map((e) => PieChartSectionData(
                            color: _getRandomColor(e.key),
                            value: e.value,
                            title:
                                '${e.key.substring(0, 5)}\n${e.value.toStringAsFixed(0)}',
                            radius: 24,
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRandomColor(String seed) =>
      Colors.primaries[seed.hashCode % Colors.primaries.length];
}

// Keep all your existing classes (Transaction, TransactionCard, _PermissionDeniedMessage, _SummaryCard)
// from the previous code - they remain unchanged

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryCard(
      {required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(title, style: TextStyle(color: color, fontSize: 14)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
