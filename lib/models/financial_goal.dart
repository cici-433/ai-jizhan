import 'package:intl/intl.dart';
import 'transaction.dart';

/// 财务目标类型枚举
enum GoalType {
  saving,     // 储蓄
  investment, // 投资
  debt,       // 债务偿还
  purchase,   // 购买
  other       // 其他
}

/// 财务目标状态枚举
enum GoalStatus {
  inProgress, // 进行中
  completed,  // 已完成
  failed      // 未达成
}

/// 财务目标数据模型
class FinancialGoal {
  int? id;                // 目标ID
  String name;            // 目标名称
  GoalType type;          // 目标类型
  double targetAmount;    // 目标金额
  double currentAmount;   // 当前金额
  DateTime startDate;     // 开始日期
  DateTime targetDate;    // 目标日期
  GoalStatus status;      // 目标状态
  String? note;           // 备注
  TransactionCategory? relatedCategory; // 相关交易分类（可选）

  FinancialGoal({
    this.id,
    required this.name,
    required this.type,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.startDate,
    required this.targetDate,
    this.status = GoalStatus.inProgress,
    this.note,
    this.relatedCategory,
  });

  /// 从Map创建FinancialGoal对象（用于数据库操作）
  factory FinancialGoal.fromMap(Map<String, dynamic> map) {
    return FinancialGoal(
      id: map['id'],
      name: map['name'],
      type: GoalType.values[map['type']],
      targetAmount: map['targetAmount'],
      currentAmount: map['currentAmount'],
      startDate: DateTime.parse(map['startDate']),
      targetDate: DateTime.parse(map['targetDate']),
      status: GoalStatus.values[map['status']],
      note: map['note'],
      relatedCategory: map['relatedCategory'] != null
          ? TransactionCategory.values[map['relatedCategory']]
          : null,
    );
  }

  /// 将FinancialGoal对象转换为Map（用于数据库操作）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'startDate': startDate.toIso8601String(),
      'targetDate': targetDate.toIso8601String(),
      'status': status.index,
      'note': note,
      'relatedCategory': relatedCategory?.index,
    };
  }

  /// 获取目标类型的显示文本
  String getTypeText() {
    switch (type) {
      case GoalType.saving:
        return '储蓄';
      case GoalType.investment:
        return '投资';
      case GoalType.debt:
        return '债务偿还';
      case GoalType.purchase:
        return '购买';
      case GoalType.other:
        return '其他';
    }
  }

  /// 获取目标状态的显示文本
  String getStatusText() {
    switch (status) {
      case GoalStatus.inProgress:
        return '进行中';
      case GoalStatus.completed:
        return '已完成';
      case GoalStatus.failed:
        return '未达成';
    }
  }

  /// 计算目标完成百分比
  double getCompletionPercentage() {
    if (targetAmount <= 0) return 0;
    double percentage = (currentAmount / targetAmount) * 100;
    return percentage > 100 ? 100 : percentage;
  }

  /// 计算距离目标日期的剩余天数
  int getRemainingDays() {
    final now = DateTime.now();
    if (now.isAfter(targetDate)) return 0;
    return targetDate.difference(now).inDays;
  }

  /// 更新目标状态
  void updateStatus() {
    final now = DateTime.now();
    
    if (currentAmount >= targetAmount) {
      status = GoalStatus.completed;
    } else if (now.isAfter(targetDate)) {
      status = GoalStatus.failed;
    } else {
      status = GoalStatus.inProgress;
    }
  }

  /// 添加进度金额
  void addProgress(double amount) {
    currentAmount += amount;
    updateStatus();
  }
}