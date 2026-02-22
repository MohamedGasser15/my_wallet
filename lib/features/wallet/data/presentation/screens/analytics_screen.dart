import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:my_wallet/features/wallet/data/repositories/wallet_repository.dart';
import 'package:my_wallet/features/wallet/data/models/wallet_models.dart';
import 'package:intl/intl.dart';
import 'package:my_wallet/core/extensions/context_extensions.dart';

// enum لأنواع الرسوم البيانية
enum ChartType { line, bar }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final WalletRepository _repository = WalletRepository();
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  bool _isLoading = false;
  Map<String, dynamic>? _summaryData;
  String? _errorMessage;

  // متغيرات لتخزين نوع الرسم المختار
  ChartType _expensesChartType = ChartType.line;
  ChartType _incomeChartType = ChartType.line;

  // للتجميل
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _repository.getSummary(
        fromDate: _fromDate,
        toDate: _toDate,
      );
      setState(() {
        _summaryData = {
          'totalIncome': data.totalIncome,
          'totalExpenses': data.totalExpenses,
          'netSavings': data.netSavings,
          'expensesByCategory': data.expensesByCategory,
          'incomeByCategory': data.incomeByCategory,
        };
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load analytics: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? Colors.grey[900]! : Colors.grey[50]!;
    final borderColor = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.analytics),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSummary,
                        child: Text(context.l10n.tryAgain),
                      ),
                    ],
                  ),
                )
              : _summaryData == null
                  ? Center(child: Text(context.l10n.noDataAvailable))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // بطاقات الإحصائيات الأساسية
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  title: context.l10n.totalIncome,
                                  value: _currencyFormat.format(_summaryData!['totalIncome']),
                                  icon: Icons.trending_up,
                                  color: Colors.green,
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  title: context.l10n.totalExpenses,
                                  value: _currencyFormat.format(_summaryData!['totalExpenses']),
                                  icon: Icons.trending_down,
                                  color: Colors.red,
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // بطاقة صافي التوفير
                          _buildNetSavingsCard(
                            netSavings: _summaryData!['netSavings'],
                            isDarkMode: isDarkMode,
                          ),

                          const SizedBox(height: 24),

                          // قسم المصروفات مع اختيار نوع الرسم
                          _buildChartSection(
                            title: context.l10n.expensesByCategory,
                            categories: _summaryData!['expensesByCategory'] as List,
                            chartType: _expensesChartType,
                            onChartTypeChanged: (type) {
                              setState(() {
                                _expensesChartType = type;
                              });
                            },
                            color: Colors.red,
                            isDarkMode: isDarkMode,
                          ),

                          const SizedBox(height: 16),

                          // قائمة تفصيلية للمصروفات
                          _buildCategoryDetails(
                            _summaryData!['expensesByCategory'] as List,
                            isDarkMode,
                            isIncome: false,
                          ),

                          const SizedBox(height: 24),

                          // قسم الإيرادات مع اختيار نوع الرسم
                          _buildChartSection(
                            title: context.l10n.incomeByCategory,
                            categories: _summaryData!['incomeByCategory'] as List,
                            chartType: _incomeChartType,
                            onChartTypeChanged: (type) {
                              setState(() {
                                _incomeChartType = type;
                              });
                            },
                            color: Colors.green,
                            isDarkMode: isDarkMode,
                          ),

                          const SizedBox(height: 16),

                          // قائمة تفصيلية للإيرادات
                          _buildCategoryDetails(
                            _summaryData!['incomeByCategory'] as List,
                            isDarkMode,
                            isIncome: true,
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
    );
  }

  // دالة مساعدة لبناء قسم الرسم البياني مع خيارات النوع
  Widget _buildChartSection({
    required String title,
    required List<dynamic> categories,
    required ChartType chartType,
    required ValueChanged<ChartType> onChartTypeChanged,
    required Color color,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            // خيارات اختيار نوع الرسم
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _buildTypeChip(
                    icon: Icons.show_chart,
                    label: 'Line',
                    isSelected: chartType == ChartType.line,
                    onSelected: () => onChartTypeChanged(ChartType.line),
                    isDarkMode: isDarkMode,
                  ),
                  _buildTypeChip(
                    icon: Icons.bar_chart,
                    label: 'Bar',
                    isSelected: chartType == ChartType.bar,
                    onSelected: () => onChartTypeChanged(ChartType.bar),
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // بناء الرسم البياني حسب النوع
        _buildChart(categories, chartType, color, isDarkMode),
      ],
    );
  }

  // دالة مساعدة لبناء خيارات النوع مع أيقونة
  Widget _buildTypeChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? Colors.blueGrey[700] : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? (isDarkMode ? Colors.white : Colors.black)
                  : (isDarkMode ? Colors.grey[400] : Colors.grey[700]),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? (isDarkMode ? Colors.white : Colors.black)
                    : (isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة موحدة لبناء الرسم البياني (خطي أو أعمدة)
  Widget _buildChart(List<dynamic> categories, ChartType type, Color color, bool isDarkMode) {
    if (categories.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          type == ChartType.line ? 'No expenses in this period' : 'No expenses in this period',
          style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        ),
      );
    }

    // إنشاء نقاط البيانات
    final spots = <FlSpot>[];
    for (int i = 0; i < categories.length; i++) {
      spots.add(FlSpot(i.toDouble(), categories[i].total));
    }

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = 0.0;

    // إذا كان النوع أعمدة
    if (type == ChartType.bar) {
      return Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY * 1.1,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final cat = categories[group.x.toInt()];
                  final name = Localizations.localeOf(context).languageCode == 'ar'
                      ? cat.categoryNameAr
                      : cat.categoryNameEn;
                  return BarTooltipItem(
                    '$name\n${_currencyFormat.format(rod.toY)}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      _currencyFormat.format(value).replaceAll('\$', ''),
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(categories.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: categories[i].total,
                    color: color.withOpacity(0.7),
                    width: 22,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }),
          ),
        ),
      );
    } else {
      // رسم بياني خطي
      return Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      _currencyFormat.format(value).replaceAll('\$', ''),
                      style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 10),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (categories.length - 1).toDouble(),
            minY: minY,
            maxY: maxY * 1.1,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: false,
                color: color,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(show: false),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((touchedSpot) {
                    final index = touchedSpot.spotIndex;
                    final cat = categories[index];
                    final name = Localizations.localeOf(context).languageCode == 'ar'
                        ? cat.categoryNameAr
                        : cat.categoryNameEn;
                    return LineTooltipItem(
                      '$name\n${_currencyFormat.format(touchedSpot.y)}',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      );
    }
  }

  // باقي الدوال كما هي ( _buildStatCard, _buildNetSavingsCard, _buildCategoryDetails )
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.more_vert, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildNetSavingsCard({required double netSavings, required bool isDarkMode}) {
    final color = netSavings >= 0 ? Colors.green : Colors.red;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.7), color.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.netSavings, style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(netSavings),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  // قائمة تفصيلية بالفئات (بأيقونة بدلاً من الدائرة)
  Widget _buildCategoryDetails(List<dynamic> categories, bool isDarkMode, {bool isIncome = false}) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: categories.map<Widget>((cat) {
        final locale = Localizations.localeOf(context).languageCode;
        final name = locale == 'ar' ? cat.categoryNameAr : cat.categoryNameEn;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // أيقونة صغيرة بدلاً من الدائرة
              Icon(
                isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: isIncome ? Colors.green[800] : Colors.red[800],
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(name, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black))),
              Text(
                _currencyFormat.format(cat.total),
                style: TextStyle(
                  color: isIncome ? Colors.green[800] : Colors.red[800],
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}