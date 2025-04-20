// import 'package:personal_finance_tracker/sms_analyzer.dart';
import 'package:personal_finance_tracker/model/transaction_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final List<Transaction> transactions;

  const DashboardScreen({super.key, required this.transactions});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

enum TimeFilter { lastWeek, lastMonth, custom }

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeFilter _selectedFilter = TimeFilter.lastMonth;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  final List<int> _availableYears = List.generate(
    5,
    (index) => DateTime.now().year - index,
  );

  List<Transaction> get filteredTransactions {
    return widget.transactions.where((t) {
      if (t.date == null) return false;

      switch (_selectedFilter) {
        case TimeFilter.lastWeek:
          final lastWeek = DateTime.now().subtract(const Duration(days: 7));
          return t.date!.isAfter(lastWeek);

        case TimeFilter.lastMonth:
          final lastMonth = DateTime.now().subtract(const Duration(days: 30));
          return t.date!.isAfter(lastMonth);

        case TimeFilter.custom:
          return t.date!.year == _selectedYear &&
              t.date!.month == _selectedMonth;
      }
    }).toList();
  }

  double get totalIncome => filteredTransactions
      .where((t) => !t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => filteredTransactions
      .where((t) => t.isExpense)
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
        title: const Text(
          'Financial Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A0E21),
              const Color(0xFF0A0E21).withOpacity(0.8),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimeFilterSection(),
                    const SizedBox(height: 24),
                    Text(
                      'Financial Overview',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCards(
                        formatter, totalIncome, totalExpense, profit),
                    const SizedBox(height: 24),
                    Text(
                      'Income vs Expense',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildBarChart(),
                    const SizedBox(height: 24),
                    _buildTransactionSummary(formatter),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Period',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Last Week', TimeFilter.lastWeek),
                const SizedBox(width: 8),
                _buildFilterChip('Last Month', TimeFilter.lastMonth),
                const SizedBox(width: 8),
                _buildFilterChip('Custom', TimeFilter.custom),
              ],
            ),
          ),
          if (_selectedFilter == TimeFilter.custom) ...[
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      dropdownColor: const Color(0xFF1D1E33),
                      decoration: InputDecoration(
                        labelText: 'Year',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      style: const TextStyle(color: Colors.white),
                      items: _availableYears
                          .map((year) => DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedYear = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 140,
                    child: DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      dropdownColor: const Color(0xFF1D1E33),
                      decoration: InputDecoration(
                        labelText: 'Month',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      style: const TextStyle(color: Colors.white),
                      items: List.generate(12, (index) => index + 1)
                          .map((month) => DropdownMenuItem(
                                value: month,
                                child: Text(DateFormat('MMMM').format(
                                    DateTime(DateTime.now().year, month))),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedMonth = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TimeFilter filter) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: FilterChip(
        selected: _selectedFilter == filter,
        label: Text(
          label,
          style: TextStyle(
            color: _selectedFilter == filter ? Colors.white : Colors.grey[400],
          ),
        ),
        selectedColor: Colors.blue,
        backgroundColor: const Color(0xFF0A0E21),
        checkmarkColor: Colors.white,
        onSelected: (selected) {
          setState(() => _selectedFilter = filter);
        },
      ),
    );
  }

  Widget _buildSummaryCards(
      NumberFormat formatter, double income, double expense, double profit) {
    return Container(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _SummaryCard(
            title: 'Income',
            value: formatter.format(income),
            color: Colors.green,
            icon: Icons.arrow_upward,
          ),
          _SummaryCard(
            title: 'Expense',
            value: formatter.format(expense),
            color: Colors.red,
            icon: Icons.arrow_downward,
          ),
          _SummaryCard(
            title: 'Profit',
            value: formatter.format(profit),
            color: profit >= 0 ? Colors.blue : Colors.orange,
            icon: profit >= 0 ? Icons.trending_up : Icons.trending_down,
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Comparison',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                alignment: BarChartAlignment.spaceAround,
                maxY: [totalIncome, totalExpense]
                        .reduce((a, b) => a > b ? a : b) *
                    1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (FlTouchEvent event, barTouchResponse) {},
                  touchTooltipData: BarTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      NumberFormat localFormatter =
                          NumberFormat.currency(symbol: '\$');
                      String value = localFormatter.format(rod.toY);
                      String title = groupIndex == 0 ? 'Income' : 'Expense';
                      return BarTooltipItem(
                        '$title\n$value',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return const Text("Income",
                                style: TextStyle(color: Colors.white));
                          case 1:
                            return const Text("Expense",
                                style: TextStyle(color: Colors.white));
                          default:
                            return const Text("");
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        NumberFormat localFormatter =
                            NumberFormat.currency(symbol: '\$');
                        return Text(
                          localFormatter.format(value),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: totalIncome,
                        color: Colors.green,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: totalExpense,
                        color: Colors.red,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSummary(NumberFormat formatter) {
    final monthlyTransactions = filteredTransactions;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Total Transactions',
              '${monthlyTransactions.length}', Colors.blue),
          _buildSummaryRow(
              'Average Transaction',
              formatter.format(monthlyTransactions.isEmpty
                  ? 0
                  : monthlyTransactions
                          .map((t) => t.amount)
                          .reduce((a, b) => a + b) /
                      monthlyTransactions.length),
              Colors.purple),
          _buildSummaryRow(
              'Largest Transaction',
              formatter.format(monthlyTransactions.isEmpty
                  ? 0
                  : monthlyTransactions
                      .map((t) => t.amount)
                      .reduce((a, b) => a > b ? a : b)),
              Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
              Icon(icon, color: color),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          LinearProgressIndicator(
            value: 0.7,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }
}
