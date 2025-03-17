import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/financial_goal.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

/// 财务目标管理页面
class FinancialGoalScreen extends StatefulWidget {
  const FinancialGoalScreen({Key? key}) : super(key: key);

  @override
  State<FinancialGoalScreen> createState() => _FinancialGoalScreenState();
}

class _FinancialGoalScreenState extends State<FinancialGoalScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<FinancialGoal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载财务目标数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取所有财务目标
      final goals = await _databaseService.getAllFinancialGoals();
      
      // 更新每个目标的状态
      for (var goal in goals) {
        goal.updateStatus();
      }
      
      // 按状态排序：进行中 -> 已完成 -> 未达成
      goals.sort((a, b) {
        if (a.status == b.status) {
          // 同一状态下，按剩余天数排序（对于进行中的目标）
          if (a.status == GoalStatus.inProgress) {
            return a.getRemainingDays().compareTo(b.getRemainingDays());
          }
          // 同一状态下，按完成时间排序（最近完成的在前）
          return b.targetDate.compareTo(a.targetDate);
        }
        return a.status.index.compareTo(b.status.index);
      });

      setState(() {
        _goals = goals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载财务目标数据失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('财务目标'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGoalDialog(context),
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
    if (_goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flag_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('暂无财务目标', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showAddGoalDialog(context),
              child: const Text('添加财务目标'),
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
          _buildGoalSummary(),
          const SizedBox(height: 16),
          ..._goals.map((goal) => _buildGoalCard(goal)).toList(),
        ],
      ),
    );
  }

  /// 构建目标摘要卡片
  Widget _buildGoalSummary() {
    // 计算进行中、已完成和未达成的目标数量
    int inProgressCount = _goals.where((g) => g.status == GoalStatus.inProgress).length;
    int completedCount = _goals.where((g) => g.status == GoalStatus.completed).length;
    int failedCount = _goals.where((g) => g.status == GoalStatus.failed).length;
    
    // 计算总目标金额和当前已积累金额
    double totalTargetAmount = _goals.fold(0, (sum, goal) => sum + goal.targetAmount);
    double totalCurrentAmount = _goals.fold(0, (sum, goal) => sum + goal.currentAmount);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '目标概览',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('进行中', inProgressCount, Colors.blue),
                _buildSummaryItem('已完成', completedCount, Colors.green),
                _buildSummaryItem('未达成', failedCount, Colors.red),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('总目标金额:'),
                Text(
                  NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 2)
                      .format(totalTargetAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('已积累金额:'),
                Text(
                  NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 2)
                      .format(totalCurrentAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('总体完成率:'),
                Text(
                  '${(totalTargetAmount > 0 ? (totalCurrentAmount / totalTargetAmount) * 100 : 0).toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建摘要项
  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }

  /// 构建目标卡片
  Widget _buildGoalCard(FinancialGoal goal) {
    final percentage = goal.getCompletionPercentage();
    final remainingDays = goal.getRemainingDays();
    
    // 根据目标状态设置颜色
    Color statusColor;
    switch (goal.status) {
      case GoalStatus.inProgress:
        statusColor = Colors.blue;
        break;
      case GoalStatus.completed:
        statusColor = Colors.green;
        break;
      case GoalStatus.failed:
        statusColor = Colors.red;
        break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    goal.getStatusText(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '类型: ${goal.getTypeText()}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 2).format(goal.currentAmount)} / ${NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 2).format(goal.targetAmount)}',
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '开始: ${DateFormat('yyyy-MM-dd').format(goal.startDate)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '目标: ${DateFormat('yyyy-MM-dd').format(goal.targetDate)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            if (goal.status == GoalStatus.inProgress)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '剩余 $remainingDays 天',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (goal.status == GoalStatus.inProgress) ...[                  
                  OutlinedButton(
                    onPressed: () => _showAddProgressDialog(context, goal),
                    child: const Text('添加进度'),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  onPressed: () => _showEditGoalDialog(context, goal),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  onPressed: () => _deleteGoal(goal),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 显示添加财务目标对话框
  void _showAddGoalDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String? name;
    GoalType type = GoalType.saving;
    double? targetAmount;
    DateTime startDate = DateTime.now();
    DateTime targetDate = DateTime.now().add(const Duration(days: 30));
    TransactionCategory? relatedCategory;
    String? note;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加财务目标'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: '目标名称'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入目标名称';
                    }
                    return null;
                  },
                  onSaved: (value) => name = value,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<GoalType>(
                  decoration: const InputDecoration(labelText: '目标类型'),
                  value: type,
                  items: GoalType.values.map((type) {
                    String typeText;
                    switch (type) {
                      case GoalType.saving:
                        typeText = '储蓄';
                        break;
                      case GoalType.investment:
                        typeText = '投资';
                        break;
                      case GoalType.debt:
                        typeText = '债务偿还';
                        break;
                      case GoalType.purchase:
                        typeText = '购买';
                        break;
                      case GoalType.other:
                        typeText = '其他';
                        break;
                    }
                    return DropdownMenuItem(
                      value: type,
                      child: Text(typeText),
                    );
                  }).toList(),
                  onChanged: (value) => type = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: '目标金额 (¥)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入目标金额';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return '请输入有效的金额';
                    }
                    return null;
                  },
                  onSaved: (value) => targetAmount = double.parse(value!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: '开始日期'),
                        readOnly: true,
                        controller: TextEditingController(
                          text: DateFormat('yyyy-MM-dd').format(startDate),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              startDate = picked;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: '目标日期'),
                        readOnly: true,
                        controller: TextEditingController(
                          text: DateFormat('yyyy-MM-dd').format(targetDate),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: targetDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              targetDate = picked;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TransactionCategory>(
                  decoration: const InputDecoration(labelText: '相关交易分类（可选）'),
                  value: null,
                  items: [
                    const DropdownMenuItem<TransactionCategory>(
                      value: null,
                      child: Text('无'),
                    ),
                    ...TransactionCategory.values.map((category) {
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
                    }),
                  ],
                  onChanged: (value) => relatedCategory = value,
                ),
                const SizedBox(height: 16),
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
                
                final goal = FinancialGoal(
                  name: name!,
                  type: type,
                  targetAmount: targetAmount!,
                  startDate: startDate,
                  targetDate: targetDate,
                  relatedCategory: relatedCategory,
                  note: note,
                );
                
                try {
                  await _databaseService.insertFinancialGoal(goal);
                  Navigator.pop(context);
                  _loadData(); // 重新加载数据
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('财务目标添加成功')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('添加财务目标失败: $e')),
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

  /// 显示编辑财务目标对话框
  void _showEditGoalDialog(BuildContext context, FinancialGoal goal) {
    final formKey = GlobalKey<FormState>();
    String name = goal.name;
    GoalType type = goal.type;
    double targetAmount = goal.targetAmount;
    DateTime startDate = goal.startDate;
    DateTime targetDate = goal.targetDate;
    TransactionCategory? relatedCategory = goal.relatedCategory;
    String? note = goal.note;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑财务目标'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: '目标名称'),
                  initialValue: name,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入目标名称';
                    }
                    return null;
                  },
                  onSaved: (value) => name = value!,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<GoalType>(
                  decoration: const InputDecoration(labelText: '目标类型'),
                  value: type,
                  items: GoalType.values.map((t) {
                    String typeText;
                    switch (t) {
                      case GoalType.saving:
                        typeText = '储蓄';
                        break;
                      case GoalType.investment:
                        typeText = '投资';
                        break;
                      case GoalType.debt:
                        typeText = '债务偿还';
                        break;
                      case GoalType.purchase:
                        typeText = '购买';
                        break;
                      case GoalType.other:
                        typeText = '其他';
                        break;
                    }
                    return DropdownMenuItem(
                      value: t,
                      child: Text(typeText),
                    );
                  }).toList(),
                  onChanged: (value) => type = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: '目标金额 (¥)'),
                  keyboardType: TextInputType.number,
                  initialValue: targetAmount.toString(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入目标金额';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return '请输入有效的金额';
                    }
                    return null;
                  },
                  onSaved: (value) => targetAmount = double.parse(value!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: '开始日期'),
                        readOnly: true,
                        controller: TextEditingController(
                          text: DateFormat('yyyy-MM-dd').format(startDate),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              startDate = picked;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: '目标日期'),
                        readOnly: true,
                        controller: TextEditingController(
                          text: DateFormat('yyyy-MM-dd').format(targetDate),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: targetDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              targetDate = picked;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TransactionCategory?>(
                  decoration: const InputDecoration(labelText: '相关交易分类（可选）'),
                  value: relatedCategory,
                  items: [
                    const DropdownMenuItem<TransactionCategory?>(
                      value: null,
                      child: Text('无'),
                    ),
                    ...TransactionCategory.values.map((category) {
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
                    }),
                  ],
                  onChanged: (value) => relatedCategory = value,
                ),
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
                
                final updatedGoal = FinancialGoal(
                  id: goal.id,
                  name: name,
                  type: type,
                  targetAmount: targetAmount,
                  currentAmount: goal.currentAmount,
                  startDate: startDate,
                  targetDate: targetDate,
                  status: goal.status,
                  relatedCategory: relatedCategory,
                  note: note,
                );
                
                try {
                  await _databaseService.updateFinancialGoal(updatedGoal);
                  Navigator.pop(context);
                  _loadData(); // 重新加载数据
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('财务目标更新成功')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('更新财务目标失败: $e')),
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

  /// 显示添加进度对话框
  void _showAddProgressDialog(BuildContext context, FinancialGoal goal) {
    final formKey = GlobalKey<FormState>();
    double? amount;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加进度'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '当前进度: ${NumberFormat.currency(locale: "zh_CN", symbol: "¥", decimalDigits: 2).format(goal.currentAmount)} / ${NumberFormat.currency(locale: "zh_CN", symbol: "¥", decimalDigits: 2).format(goal.targetAmount)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: '添加金额 (¥)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入金额';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return '请输入有效的金额';
                  }
                  return null;
                },
                onSaved: (value) => amount = double.parse(value!),
              ),
            ],
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
                
                // 更新目标进度
                goal.addProgress(amount!);
                
                try {
                  await _databaseService.updateFinancialGoal(goal);
                  Navigator.pop(context);
                  _loadData(); // 重新加载数据
                  
                  // 检查是否已完成目标
                  if (goal.status == GoalStatus.completed) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 恭喜！您已完成财务目标！'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('进度更新成功')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('更新进度失败: $e')),
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

  /// 删除财务目标
  void _deleteGoal(FinancialGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除财务目标'),
        content: Text('确定要删除"${goal.name}"目标吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _databaseService.deleteFinancialGoal(goal.id!);
                Navigator.pop(context);
                _loadData(); // 重新加载数据
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('财务目标删除成功')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('删除财务目标失败: $e')),
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