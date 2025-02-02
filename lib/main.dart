import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Financial Dashboard',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        cardColor: const Color(0xFF1D1E33),
      ),
      home: FinancialDashboard(),
    );
  }
}

class FinancialDashboard extends StatelessWidget {
  final List<Expense> expenses = [
    Expense('Food', 500, DateTime(2023, 5, 1)),
    Expense('Transport', 300, DateTime(2023, 5, 5)),
    Expense('Rent', 1200, DateTime(2023, 5, 10)),
    Expense('Utilities', 250, DateTime(2023, 5, 15)),
    Expense('Entertainment', 150, DateTime(2023, 5, 20)),
  ];

  final List<Income> incomes = [
    Income('Salary', 3000, DateTime(2023, 5, 1)),
    Income('Freelance', 800, DateTime(2023, 5, 15)),
    Income('Investment', 200, DateTime(2023, 5, 25)),
  ];

  FinancialDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final totalIncome = incomes.fold(0.0, (sum, item) => sum + item.amount);
    final totalExpense = expenses.fold(0.0, (sum, item) => sum + item.amount);
    final profit = totalIncome - totalExpense;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSummaryCards(totalIncome, totalExpense, profit),
                  const SizedBox(height: 20),
                  _buildBarChart(),
                  const SizedBox(height: 20),
                  _buildCashFlowChart(),
                  const SizedBox(height: 20),
                  _buildExpensePieChart(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(double income, double expense, double profit) {
    final formatter = NumberFormat.currency(symbol: '\$');
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
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Monthly Comparison', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 3000,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text(
                          DateFormat.MMM()
                              .format(DateTime(2023, value.toInt())),
                        ),
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 5,
                      barRods: [
                        BarChartRodData(
                          toY: totalIncomeByMonth(5),
                          color: Colors.green,
                          width: 16,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 5,
                      barRods: [
                        BarChartRodData(
                          toY: totalExpenseByMonth(5),
                          color: Colors.red,
                          width: 16,
                        ),
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

  Widget _buildCashFlowChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cash Flow', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(enabled: true),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateCashFlowSpots(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      belowBarData: BarAreaData(show: false),
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
    return Card(
      elevation: 4,
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
                  centerSpaceRadius: 80,
                  sections: _generatePieChartSections(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartSections() {
    final categoryMap = <String, double>{};
    for (var expense in expenses) {
      categoryMap.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final colors = [
      Colors.red,
      Colors.orange,
      Colors.blue,
      Colors.green,
      Colors.purple
    ];
    int colorIndex = 0;

    return categoryMap.entries.map((entry) {
      return PieChartSectionData(
        color: colors[colorIndex++ % colors.length],
        value: entry.value,
        title: '${entry.key}\n${entry.value.toStringAsFixed(0)}',
        radius: 24,
        titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
      );
    }).toList();
  }

  List<FlSpot> _generateCashFlowSpots() {
    // This is a simplified example - you should implement your own cash flow calculation
    return List.generate(
        30, (index) => FlSpot(index.toDouble(), (index * 100).toDouble()));
  }

  double totalIncomeByMonth(int month) {
    return incomes
        .where((income) => income.date.month == month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double totalExpenseByMonth(int month) {
    return expenses
        .where((expense) => expense.date.month == month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }
}

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

class Expense {
  final String category;
  final double amount;
  final DateTime date;

  Expense(this.category, this.amount, this.date);
}

class Income {
  final String source;
  final double amount;
  final DateTime date;

  Income(this.source, this.amount, this.date);
}
