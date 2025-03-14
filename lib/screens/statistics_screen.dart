import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

/// 统计分析页面
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  
  // 统计数据
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;
  Map<TransactionCategory, double> _categoryExpenses = {};
  Map<String, double> _dailyExpenses = {};
  Map<String, double> _dailyIncomes = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  /// 加载数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 获取最近30天的交易记录
      final DateTime now = DateTime.now();
      final DateTime thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final transactions = await _databaseService.getTransactionsByDateRange(
        thirtyDaysAgo,
        now,
      );
      
      // 计算总收入和总支出
      double totalIncome = 0;
      double totalExpense = 0;
      Map<TransactionCategory, double> categoryExpenses = {};
      Map<String, double> dailyExpenses = {};
      Map<String, double> dailyIncomes = {};
      
      for (var transaction in transactions) {
        if (transaction.type == TransactionType.income) {
          totalIncome += transaction.amount;
          
          // 按日期统计收入
          String dateKey = DateFormat('MM-dd').format(transaction.date);
          dailyIncomes[dateKey] = (dailyIncomes[dateKey] ?? 0) + transaction.amount;
        } else {
          totalExpense += transaction.amount;
          
          // 按分类统计支出
          categoryExpenses[transaction.category] = 
              (categoryExpenses[transaction.category] ?? 0) + transaction.amount;
          
          // 按日期统计支出
          String dateKey = DateFormat('MM-dd').format(transaction.date);
          dailyExpenses[dateKey] = (dailyExpenses[dateKey] ?? 0) + transaction.amount;
        }
      }
      
      setState(() {
        _transactions = transactions;
        _totalIncome = totalIncome;
        _totalExpense = totalExpense;
        _balance = totalIncome - totalExpense;
        _categoryExpenses = categoryExpenses;
        _dailyExpenses = dailyExpenses;
        _dailyIncomes = dailyIncomes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计分析'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '收支概览'),
            Tab(text: '分类统计'),
            Tab(text: '趋势分析'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCategoryTab(),
                _buildTrendTab(),
              ],
            ),
    );
  }
  
  /// 构建收支概览标签页
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 收支概览卡片
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '本月收支概览',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('收入', _totalIncome, Colors.green),
                      _buildStatItem('支出', _totalExpense, Colors.red),
                      _buildStatItem('结余', _balance, _balance >= 0 ? Colors.blue : Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // 收支比例饼图
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '收支比例',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _totalIncome == 0 && _totalExpense == 0
                        ? const Center(child: Text('暂无数据'))
                        : PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: _totalIncome,
                                  title: '收入',
                                  color: Colors.green,
                                  radius: 80,
                                ),
                                PieChartSectionData(
                                  value: _totalExpense,
                                  title: '支出',
                                  color: Colors.red,
                                  radius: 80,
                                ),
                              ],
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建分类统计标签页
  Widget _buildCategoryTab() {
    // 将分类支出转换为列表并排序
    final categoryItems = _categoryExpenses.entries.toList();
    categoryItems.sort((a, b) => b.value.compareTo(a.value));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分类支出饼图
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '支出分类占比',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: categoryItems.isEmpty
                        ? const Center(child: Text('暂无数据'))
                        : PieChart(
                            PieChartData(
                              sections: _getCategorySections(),
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // 分类支出列表
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '支出分类明细',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...categoryItems.map((entry) {
                    final Transaction dummyTransaction = Transaction(
                      amount: 0,
                      type: TransactionType.expense,
                      category: entry.key,
                      description: '',
                      date: DateTime.now(),
                    );
                    final categoryName = dummyTransaction.getCategoryName();
                    final percentage = _totalExpense > 0 
                        ? (entry.value / _totalExpense * 100).toStringAsFixed(1) 
                        : '0';
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(entry.key),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(categoryName),
                          ),
                          Text('¥${entry.value.toStringAsFixed(2)}'),
                          const SizedBox(width: 8),
                          Text('$percentage%'),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建趋势分析标签页
  Widget _buildTrendTab() {
    // 获取最近30天的日期列表
    final List<String> dateLabels = [];
    final DateTime now = DateTime.now();
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      dateLabels.add(DateFormat('MM-dd').format(date));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 收支趋势折线图
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '收支趋势（近30天）',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: _dailyExpenses.isEmpty && _dailyIncomes.isEmpty
                        ? const Center(child: Text('暂无数据'))
                        : LineChart(
                            LineChartData(
                              gridData: FlGridData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() % 5 == 0 && value.toInt() < dateLabels.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            dateLabels[value.toInt()],
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                // 收入曲线
                                LineChartBarData(
                                  spots: _getLineSpots(dateLabels, _dailyIncomes),
                                  isCurved: true,
                                  color: Colors.green,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(show: false),
                                ),
                                // 支出曲线
                                LineChartBarData(
                                  spots: _getLineSpots(dateLabels, _dailyExpenses),
                                  isCurved: true,
                                  color: Colors.red,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(show: false),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // 消费习惯分析卡片
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '消费习惯分析',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildConsumptionHabitAnalysis(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建消费习惯分析
  Widget _buildConsumptionHabitAnalysis() {
    if (_transactions.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }
    
    // 分析消费习惯
    String habitAnalysis = '';
    TransactionCategory? topCategory;
    double topAmount = 0;
    
    // 找出最大支出类别
    _categoryExpenses.forEach((category, amount) {
      if (amount > topAmount) {
        topAmount = amount;
        topCategory = category;
      }
    });
    
    if (topCategory != null) {
      final Transaction dummyTransaction = Transaction(
        amount: 0,
        type: TransactionType.expense,
        category: topCategory!,
        description: '',
        date: DateTime.now(),
      );
      final categoryName = dummyTransaction.getCategoryName();
      final percentage = _totalExpense > 0 
          ? (topAmount / _totalExpense * 100).toStringAsFixed(1) 
          : '0';
      
      habitAnalysis = '您的主要支出在$categoryName类别，占总支出的$percentage%。';
      
      // 根据不同类别给出建议
      switch (topCategory) {
        case TransactionCategory.food:
          habitAnalysis += '\n建议：可以考虑自己做饭，减少外卖频率，控制餐饮支出。';
          break;
        case TransactionCategory.shopping:
          habitAnalysis += '\n建议：购物前可以列清单，避免冲动消费，关注性价比。';
          break;
        case TransactionCategory.entertainment:
          habitAnalysis += '\n建议：寻找一些免费或低成本的娱乐方式，控制娱乐支出。';
          break;
        default:
          habitAnalysis += '\n建议：建立预算计划，合理控制支出，增加储蓄比例。';
      }
    } else {
      habitAnalysis = '暂无足够数据分析您的消费习惯。';
    }
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        habitAnalysis,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
  
  /// 构建统计项目
  Widget _buildStatItem(String title, double amount, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          '¥${amount.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
  
  /// 获取分类饼图数据
  List<PieChartSectionData> _getCategorySections() {
    final List<PieChartSectionData> sections = [];
    final List<Color> colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
      Colors.brown,
      Colors.grey,
    ];
    
    int colorIndex = 0;
    _categoryExpenses.forEach((category, amount) {
      if (amount > 0) {
        final Transaction dummyTransaction = Transaction(
          amount: 0,
          type: TransactionType.expense,
          category: category,
          description: '',
          date: DateTime.now(),
        );
        final categoryName = dummyTransaction.getCategoryName();
        
        sections.add(
          PieChartSectionData(
            value: amount,
            title: categoryName,
            color: colors[colorIndex % colors.length],
            radius: 80,
            titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        );
        colorIndex++;
      }
    });
    
    return sections;
  }
  
  /// 获取分类颜色
  Color _getCategoryColor(TransactionCategory category) {
    final List<Color> colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
      Colors.brown,
      Colors.grey,
    ];
    
    return colors[category.index % colors.length];
  }
  
  /// 获取折线图数据点
  List<FlSpot> _getLineSpots(List<String> dateLabels, Map<String, double> dailyData) {
    final List<FlSpot> spots = [];
    
    for (int i = 0; i < dateLabels.length; i++) {
      final String dateKey = dateLabels[i];
      final double value = dailyData[dateKey] ?? 0;
      spots.add(FlSpot(i.toDouble(), value));
    }
    
    return spots;
  }
}