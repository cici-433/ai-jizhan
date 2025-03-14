import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/transaction.dart';

/// 首页/概览页面
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  double _balance = 0.0;
  double _income = 0.0;
  double _expense = 0.0;
  List<Transaction> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取余额
      final balance = await _databaseService.getBalance();
      // 获取总收入
      final income = await _databaseService.getTotalIncome();
      // 获取总支出
      final expense = await _databaseService.getTotalExpense();
      // 获取最近交易记录
      final transactions = await _databaseService.getAllTransactions();

      // 按日期排序，最新的在前面
      transactions.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _balance = balance;
        _income = income;
        _expense = expense;
        _recentTransactions = transactions.take(5).toList(); // 只显示最近5条记录
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载数据失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI自动记账'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 用户信息
                    const Row(
                      children: [
                        CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '你好，小明',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '周三，2023年10月18日',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 余额卡片
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue, Colors.blue.shade800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '本月余额',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '¥ ${_balance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '收入',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '¥ ${_income.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '支出',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '¥ ${_expense.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 快捷操作
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickAction(
                          icon: Icons.camera_alt,
                          label: '扫票',
                          onTap: () {
                            // 导航到扫票页面
                          },
                        ),
                        _buildQuickAction(
                          icon: Icons.edit,
                          label: '记账',
                          onTap: () {
                            // 导航到记账页面
                          },
                        ),
                        _buildQuickAction(
                          icon: Icons.mic,
                          label: '语音',
                          onTap: () {
                            // 导航到语音记账页面
                          },
                        ),
                        _buildQuickAction(
                          icon: Icons.pie_chart,
                          label: '报表',
                          onTap: () {
                            // 导航到统计页面
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 本地存储空间使用情况
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '本地存储空间',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: 0.75,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '75% 已使用',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 最近交易记录
                    const Text(
                      '最近交易',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _recentTransactions.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('暂无交易记录'),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _recentTransactions.length,
                            itemBuilder: (context, index) {
                              final transaction = _recentTransactions[index];
                              return _buildTransactionItem(transaction);
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  /// 构建快捷操作按钮
  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建交易记录项
  Widget _buildTransactionItem(Transaction transaction) {
    // 根据交易类型选择图标和颜色
    IconData icon;
    Color color;

    switch (transaction.category) {
      case TransactionCategory.food:
        icon = Icons.restaurant;
        color = Colors.orange;
        break;
      case TransactionCategory.transport:
        icon = Icons.directions_bus;
        color = Colors.blue;
        break;
      case TransactionCategory.shopping:
        icon = Icons.shopping_bag;
        color = Colors.purple;
        break;
      case TransactionCategory.entertainment:
        icon = Icons.movie;
        color = Colors.pink;
        break;
      case TransactionCategory.housing:
        icon = Icons.home;
        color = Colors.brown;
        break;
      case TransactionCategory.utilities:
        icon = Icons.power;
        color = Colors.teal;
        break;
      case TransactionCategory.health:
        icon = Icons.medical_services;
        color = Colors.red;
        break;
      case TransactionCategory.education:
        icon = Icons.school;
        color = Colors.indigo;
        break;
      case TransactionCategory.salary:
        icon = Icons.work;
        color = Colors.green;
        break;
      case TransactionCategory.investment:
        icon = Icons.trending_up;
        color = Colors.amber;
        break;
      case TransactionCategory.gift:
        icon = Icons.card_giftcard;
        color = Colors.deepPurple;
        break;
      case TransactionCategory.other:
      default:
        icon = Icons.category;
        color = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(transaction.description),
        subtitle: Text(
          DateFormat('yyyy-MM-dd').format(transaction.date),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '${transaction.type == TransactionType.expense ? '-' : '+'} ¥${transaction.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: transaction.type == TransactionType.expense
                ? Colors.red
                : Colors.green,
          ),
        ),
      ),
    );
  }
}