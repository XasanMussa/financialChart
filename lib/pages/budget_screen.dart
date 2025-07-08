import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/budget_model.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final TextEditingController _budgetController = TextEditingController();
  double? _budgetAmount;
  double _spent = 0.0;
  bool _isLoading = true;
  Budget? _currentBudget;
  Map<String, double> _categoryTotals = {'Food': 0, 'Shopping': 0, 'Others': 0};
  List<Map<String, dynamic>> _latestTransactions = [];
  bool _showAllTransactions = false;

  @override
  void initState() {
    super.initState();
    _fetchBudgetAndSpent();
  }

  Future<void> _fetchBudgetAndSpent() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    final monthKey = "${now.year}-${now.month}";
    // Fetch budget
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .doc(monthKey)
        .get();
    if (doc.exists) {
      _currentBudget = Budget.fromMap(doc.data()!);
      _budgetAmount = _currentBudget!.amount;
      _budgetController.text = _budgetAmount!.toStringAsFixed(2);
    }
    // Fetch spent for the month and breakdown
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final txSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .where('isExpense', isEqualTo: true)
        .orderBy('date', descending: true)
        .get();
    double spent = 0.0;
    Map<String, double> catTotals = {'Food': 0, 'Shopping': 0, 'Others': 0};
    List<Map<String, dynamic>> allTx = [];
    for (var doc in txSnapshot.docs) {
      final data = doc.data();
      final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;
      spent += amt;
      final cat = categorizeTransaction(data);
      catTotals[cat] = (catTotals[cat] ?? 0) + amt;
      allTx.add(data);
    }
    setState(() {
      _spent = spent;
      _categoryTotals = catTotals;
      _latestTransactions = allTx;
      _isLoading = false;
    });
  }

  Future<void> _saveBudget() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    final monthKey = "${now.year}-${now.month}";
    final amount = double.tryParse(_budgetController.text) ?? 0.0;
    final budget = Budget(
      amount: amount,
      month: DateTime(now.year, now.month),
      spent: _spent,
      userId: user.uid,
    );
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .doc(monthKey)
        .set(budget.toMap());
    setState(() {
      _budgetAmount = amount;
      _currentBudget = budget;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Budget saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Budget'),
        backgroundColor: const Color(0xFF0A0E21),
      ),
      backgroundColor: const Color(0xFF0A0E21),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Budget Card
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D1E33),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _budgetController,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                            decoration: InputDecoration(
                              labelText: 'Set Monthly Budget',
                              labelStyle:
                                  const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: const Color(0xFF23243A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Colors.blue),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_budgetAmount != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Spent',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 14),
                                    ),
                                    Text(
                                      '${_spent.toStringAsFixed(2)} / ${_budgetAmount!.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    minHeight: 10,
                                    value: _budgetAmount! > 0
                                        ? (_spent / _budgetAmount!).clamp(0, 1)
                                        : 0,
                                    backgroundColor: Colors.grey[800],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      (_spent / (_budgetAmount ?? 1)) >= 0.9
                                          ? Colors.red
                                          : (_spent / (_budgetAmount ?? 1)) >=
                                                  0.5
                                              ? Colors.orange
                                              : Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveBudget,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              child: const Text('Save Budget'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Transactions Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Transactions',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(
                              _showAllTransactions
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.blue),
                          onPressed: () {
                            setState(() {
                              _showAllTransactions = !_showAllTransactions;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D1E33),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _showAllTransactions
                          ? ListView.builder(
                              itemCount: _latestTransactions.length,
                              itemBuilder: (context, idx) {
                                final tx = _latestTransactions[idx];
                                return Card(
                                  color: const Color(0xFF23243A),
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  child: ListTile(
                                    title: Text(
                                      tx['sender'] ?? 'Unknown',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      (tx['date'] is Timestamp)
                                          ? (tx['date'] as Timestamp)
                                              .toDate()
                                              .toString()
                                              .substring(0, 16)
                                          : '',
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                    trailing: Text(
                                      (tx['amount'] as num?)
                                              ?.toStringAsFixed(2) ??
                                          '',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView.builder(
                              itemCount: 7,
                              itemBuilder: (context, idx) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 8),
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800]?.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 32),
                    // Expense Breakdown Pie Chart
                    Text('Expense Breakdown',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: CustomPaint(
                        painter: _PieChartPainter(_categoryTotals),
                        child: Center(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Category summary
                    ..._categoryTotals.entries.map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _pieColor(e.key),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${e.key}:',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(width: 8),
                              Text(e.value.toStringAsFixed(2),
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
    );
  }

  Color _pieColor(String cat) {
    switch (cat) {
      case 'Food':
        return Colors.orange;
      case 'Shopping':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }
}

class _PieChartPainter extends CustomPainter {
  final Map<String, double> data;
  _PieChartPainter(this.data);
  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    if (total == 0) return;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    double start = -3.14 / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    for (final entry in data.entries) {
      final sweep = (entry.value / total) * 3.14 * 2;
      paint.color = _pieColor(entry.key);
      canvas.drawArc(rect, start, sweep, true, paint);
      start += sweep;
    }
  }

  Color _pieColor(String cat) {
    switch (cat) {
      case 'Food':
        return Colors.orange;
      case 'Shopping':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Helper: Merchant info for categories
const foodMerchants = [
  'QOOBEY DIGFEER CASHIER ONE',
  '902486',
  'ORANGE RESTAURANT.',
  '660315',
  'REAL COFFEE AND RESTAURANT CASHIER TWO',
  '733457',
  'QOOBEY CASHIER SEYBIYAANO 2',
  '717941',
  'BULSHO RESTAURANT',
  '616916',
  'Barcaga weyne',
  '701689',
  '1may coffe',
  '604720',
  'CAGAARWEYNE CHICKEN AND CHIPS',
  '710661',
  'Baar restaurant',
  '864954',
  'Jaziira Restaurant',
  '735764',
  'Qoobeey Restaurant',
  '702207',
  'asad restaurant',
  '702764',
  'fatxi restauran',
  '703808',
];
const shoppingMerchants = [
  'Hayat Market',
  '706154',
  'hayat market 2',
  '709535',
  'Midnimo Super Market',
  '700838',
  'Hayat Mall',
  '709510',
  'Barako Hyper Market',
  '735919',
  'Godol Market',
  '735994',
];
String normalize(String s) => s
    .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
    .replaceAll(RegExp(r'\\s+'), ' ')
    .trim();

bool allWordsInMessage(String keyword, String message) {
  final words = keyword.split(' ');
  for (final word in words) {
    if (word.isEmpty) continue;
    if (!message.contains(word)) return false;
  }
  return true;
}

List<String> extractMerchantNumbers(String message) {
  final matches = RegExp(r'\b\d{6}\b').allMatches(message);
  return matches.map((m) => m.group(0) ?? '').toList();
}

String categorizeTransaction(Map<String, dynamic> data) {
  final sender = (data['sender'] as String? ?? '').toLowerCase();
  final merchant = (data['merchant'] as String? ?? '').toLowerCase();
  final description = (data['description'] as String? ?? '').toLowerCase();
  final message = normalize(sender + ' ' + merchant + ' ' + description);
  final merchantNumbers = extractMerchantNumbers(message);
  // Check merchant numbers first
  for (final number in merchantNumbers) {
    if (foodMerchants.any((k) => k.length == 6 && k == number)) {
      return 'Food';
    }
    if (shoppingMerchants.any((k) => k.length == 6 && k == number)) {
      return 'Shopping';
    }
  }
  // Fallback to keyword matching
  for (final keyword in foodMerchants) {
    final normKeyword = normalize(keyword.toLowerCase());
    if (allWordsInMessage(normKeyword, message)) {
      return 'Food';
    }
  }
  for (final keyword in shoppingMerchants) {
    final normKeyword = normalize(keyword.toLowerCase());
    if (allWordsInMessage(normKeyword, message)) {
      return 'Shopping';
    }
  }
  return 'Others';
}
