import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

/// 预算管理页面
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Budget> _budgets = [];
  bool _isLoading = true;
  Map<int, double> _categorySpending = {}; // 分类ID -> 支出金额
  double _totalSpending = 0.0; // 总支出

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载预算数据和支出数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取所有活跃预算
      final budgets = await _databaseService.getActiveBudgets();
      
      // 获取当月交易记录
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = (now.month < 12)
          ? DateTime(now.year, now.month + 1, 0)
          : DateTime(now.year + 1, 1, 0);
      
      final transactions = await _databaseService.getTransactionsByDateRange(
        startOfMonth, endOfMonth);
      
      // 计算各分类支出
      Map<int, double> categorySpending = {};
      double totalSpending = 0.0;
      
      for (var transaction in transactions) {
        if (transaction.type == TransactionType.expense) {
          final categoryIndex = transaction.category.index;
          categorySpending[categoryIndex] = 
              (categorySpending[categoryIndex] ?? 0.0) + transaction.amount;
          totalSpending += transaction.amount;
        }
      }

      setState(() {
        _budgets = budgets;
        _categorySpending = categorySpending;
        _totalSpending = totalSpending;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载预算数据失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('预算管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddBudgetDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  /// 构建主体内容
  Widget _buildBody() {
    if (_budgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('暂无预算', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showAddBudgetDialog(context),
              child: const Text('添加预算'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOverallBudgetCard(),
          const SizedBox(height: 16),
          ..._budgets.map((budget) => _buildBudgetCard(budget)).toList(),
        ],
      ),
    );
  }

  /// 构建总体预算卡片
  Widget _buildOverallBudgetCard() {
    // 查找总体预算（无分类）
    final overallBudget = _budgets.firstWhere(
      (budget) => budget.category == null,
      orElse: () => Budget(
        amount: 0,
        period: BudgetPeriod.monthly,
        startDate: DateTime.now(),
      ),
    );

    final hasOverallBudget = overallBudget.id != null;
    final percentage = hasOverallBudget && overallBudget.amount > 0
        ? (_totalSpending / overallBudget.amount) * 100
        : 0.0;
    final isOverBudget = percentage > 100;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '总体预算',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (hasOverallBudget)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditBudgetDialog(context, overallBudget),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (!hasOverallBudget) ...[              
              const Text('未设置总体预算'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _showAddBudgetDialog(context, isOverall: true),
                child: const Text('设置总体预算'),
              ),
            ] else ...[              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 2).format(_totalSpending)} / ${NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 2).format(overallBudget.amount)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: isOverBudget ? Colors.red : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      color: isOverBudget ? Colors.red : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: percentage / 100 > 1 ? 1 : percentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget ? Colors.red : Colors.green,
                ),
                minHeight: 10,
              ),
              const SizedBox(height: 8),
              Text(
                '周期: ${overallBudget.getPeriodText()}',
                style: const TextStyle(color: Colors.grey),
              ),
              if (isOverBudget)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '⚠️ 预算已超出',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建分类预算卡片
  Widget _buildBudgetCard(Budget budget) {
    // 跳过总体预算
    if (budget.category == null) return const SizedBox.shrink();
    
    final categoryIndex = budget.category!.index;
    final spending = _categorySpending[categoryIndex] ?? 0.0;
    final percentage = budget.amount > 0 ? (spending / budget.amount) * 100 : 0.0;
    final isOverBudget = percentage > 100;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  budget.getCategoryText(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      onPressed: () => _showEditBudgetDialog(context, budget),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      onPressed: () => _deleteBudget(budget),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 2).format(spending)} / ${NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 2).format(budget.amount)}',
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: isOverBudget ? Colors.red : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage / 100 > 1 ? 1 : percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? Colors.red : Colors.green,
              ),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '周期: ${budget.getPeriodText()}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (isOverBudget)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  '⚠️ 预算已超出',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 显示添加预算对话框
  void _showAddBudgetDialog(BuildContext context, {bool isOverall = false}) {
    final formKey = GlobalKey<FormState>();
    double? amount;
    BudgetPeriod period = BudgetPeriod.monthly;
    TransactionCategory? category;
    String? note;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isOverall ? '设置总体预算' : '添加预算'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: '预算金额 (¥)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入预算金额';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return '请输入有效的金额';
                    }
                    return null;
                  },
                  onSaved: (value) => amount = double.parse(value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BudgetPeriod>(
                  decoration: const InputDecoration(labelText: '预算周期'),
                  value: period,
                  items: BudgetPeriod.values.map((period) {
                    String periodText;
                    switch (period) {
                      case BudgetPeriod.daily:
                        periodText = '每日';
                        break;
                      case BudgetPeriod.weekly:
                        periodText = '每周';
                        break;
                      case BudgetPeriod.monthly:
                        periodText = '每月';
                        break;
                      case BudgetPeriod.yearly:
                        periodText = '每年';
                        break;
                    }
                    return DropdownMenuItem(
                      value: period,
                      child: Text(periodText),
                    );
                  }).toList(),
                  onChanged: (value) => period = value!,
                ),
                if (!isOverall) ...[                  
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TransactionCategory>(
                    decoration: const InputDecoration(labelText: '预算分类'),
                    value: TransactionCategory.food, // 默认值
                    items: TransactionCategory.values.map((category) {
                      String categoryText;
                      switch (category) {
                        case TransactionCategory.food:
                          categoryText = '餐饮';
                          break;
                        case TransactionCategory.transport:
                          categoryText = '交通';
                          break;
                        case TransactionCategory.shopping:
                          categoryText = '购物';
                          break;
                        case TransactionCategory.entertainment:
                          categoryText = '娱乐';
                          break;
                        case TransactionCategory.housing:
                          categoryText = '住房';
                          break;
                        case TransactionCategory.utilities:
                          categoryText = '水电煤';
                          break;
                        case TransactionCategory.health:
                          categoryText = '医疗健康';
                          break;
                        case TransactionCategory.education:
                          categoryText = '教育';
                          break;
                        case TransactionCategory.salary:
                          categoryText = '工资';
                          break;
                        case TransactionCategory.investment:
                          categoryText = '投资';
                          break;
                        case TransactionCategory.gift:
                          categoryText = '礼金';
                          break;
                        case TransactionCategory.other:
                          categoryText = '其他';
                          break;
                      }
                      return DropdownMenuItem(
                        value: category,
                        child: Text(categoryText),
                      );
                    }).toList(),
                    onChanged: (value) => category = value,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  decoration: const InputDecoration(labelText: '备注（可选）'),
                  onSaved: (value) => note = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                
                final budget = Budget(
                  amount: amount!,
                  period: period,
                  category: isOverall ? null : category,
                  startDate: DateTime.now(),
                  note: note,
                );
                
                try {
                  await _databaseService.insertBudget(budget);
                  Navigator.pop(context);
                  _loadData(); // 重新加载数据
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('预算添加成功')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('添加预算失败: $e')),
                  );
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 显示编辑预算对话框
  void _showEditBudgetDialog(BuildContext context, Budget budget) {
    final formKey = GlobalKey<FormState>();
    double amount = budget.amount;
    BudgetPeriod period = budget.period;
    TransactionCategory? category = budget.category;
    String? note = budget.note;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑${budget.category == null ? "总体" : budget.getCategoryText()}预算'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: '预算金额 (¥)'),
                  keyboardType: TextInputType.number,
                  initialValue: amount.toString(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入预算金额';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return '请输入有效的金额';
                    }
                    return null;
                  },
                  onSaved: (value) => amount = double.parse(value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BudgetPeriod>(
                  decoration: const InputDecoration(labelText: '预算周期'),
                  value: period,
                  items: BudgetPeriod.values.map((p) {
                    String periodText;
                    switch (p) {
                      case BudgetPeriod.daily:
                        periodText = '每日';
                        break;
                      case BudgetPeriod.weekly:
                        periodText = '每周';
                        break;
                      case BudgetPeriod.monthly:
                        periodText = '每月';
                        break;
                      case BudgetPeriod.yearly:
                        periodText = '每年';
                        break;
                    }
                    return DropdownMenuItem(
                      value: p,
                      child: Text(periodText),
                    );
                  }).toList(),
                  onChanged: (value) => period = value!,
                ),
                if (budget.category != null) ...[                  
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TransactionCategory>(
                    decoration: const InputDecoration(labelText: '预算分类'),
                    value: category,
                    items: TransactionCategory.values.map((c) {
                      String categoryText;
                      switch (c) {
                        case TransactionCategory.food:
                          categoryText = '餐饮';
                          break;
                        case TransactionCategory.transport:
                          categoryText = '交通';
                          break;
                        case TransactionCategory.shopping:
                          categoryText = '购物';
                          break;
                        case TransactionCategory.entertainment:
                          categoryText = '娱乐';
                          break;
                        case TransactionCategory.housing:
                          categoryText = '住房';
                          break;
                        case TransactionCategory.utilities:
                          categoryText = '水电煤';
                          break;
                        case TransactionCategory.health:
                          categoryText = '医疗健康';
                          break;
                        case TransactionCategory.education:
                          categoryText = '教育';
                          break;
                        case TransactionCategory.salary:
                          categoryText = '工资';
                          break;
                        case TransactionCategory.investment:
                          categoryText = '投资';
                          break;
                        case TransactionCategory.gift:
                          categoryText = '礼金';
                          break;
                        case TransactionCategory.other:
                          categoryText = '其他';
                          break;
                      }
                      return DropdownMenuItem(
                        value: c,
                        child: Text(categoryText),
                      );
                    }).toList(),
                    onChanged: (value) => category = value,
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: '备注（可选）'),
                  initialValue: note,
                  onSaved: (value) => note = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                
                final updatedBudget = Budget(
                  id: budget.id,
                  amount: amount,
                  period: period,
                  category: budget.category == null ? null : category,
                  startDate: budget.startDate,
                  note: note,
                );
                
                try {
                  await _databaseService.updateBudget(updatedBudget);
                  Navigator.pop(context);
                  _loadData(); // 重新加载数据
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('预算更新成功')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('更新预算失败: $e')),
                  );
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 删除预算
  void _deleteBudget(Budget budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除预算'),
        content: Text('确定要删除${budget.category == null ? "总体" : budget.getCategoryText()}预算吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _databaseService.deleteBudget(budget.id!);
                Navigator.pop(context);
                _loadData(); // 重新加载数据
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('预算删除成功')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('删除预算失败: $e')),
                );
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}