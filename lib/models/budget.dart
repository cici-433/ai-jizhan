import 'package:intl/intl.dart';
import 'transaction.dart';

/// 预算周期枚举
enum BudgetPeriod {
  daily,    // 每日
  weekly,   // 每周
  monthly,  // 每月
  yearly    // 每年
}

/// 预算数据模型
class Budget {
  int? id;                      // 预算ID
  double amount;                // 预算金额
  BudgetPeriod period;          // 预算周期
  TransactionCategory? category; // 预算分类（可选，为空表示总体预算）
  DateTime startDate;           // 开始日期
  String? note;                 // 备注

  Budget({
    this.id,
    required this.amount,
    required this.period,
    this.category,
    required this.startDate,
    this.note,
  });

  /// 从Map创建Budget对象（用于数据库操作）
  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      amount: map['amount'],
      period: BudgetPeriod.values[map['period']],
      category: map['category'] != null 
          ? TransactionCategory.values[map['category']] 
          : null,
      startDate: DateTime.parse(map['startDate']),
      note: map['note'],
    );
  }

  /// 将Budget对象转换为Map（用于数据库操作）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'period': period.index,
      'category': category?.index,
      'startDate': startDate.toIso8601String(),
      'note': note,
    };
  }

  /// 获取预算周期的结束日期
  DateTime getEndDate() {
    switch (period) {
      case BudgetPeriod.daily:
        return DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59);
      case BudgetPeriod.weekly:
        return startDate.add(const Duration(days: 6));
      case BudgetPeriod.monthly:
        // 获取下个月同一天的前一天
        final nextMonth = (startDate.month < 12) 
            ? DateTime(startDate.year, startDate.month + 1, 1)
            : DateTime(startDate.year + 1, 1, 1);
        return nextMonth.subtract(const Duration(days: 1));
      case BudgetPeriod.yearly:
        return DateTime(startDate.year + 1, startDate.month, startDate.day)
            .subtract(const Duration(days: 1));
    }
  }

  /// 获取预算周期的显示文本
  String getPeriodText() {
    switch (period) {
      case BudgetPeriod.daily:
        return '每日';
      case BudgetPeriod.weekly:
        return '每周';
      case BudgetPeriod.monthly:
        return '每月';
      case BudgetPeriod.yearly:
        return '每年';
    }
  }

  /// 获取预算分类的显示文本
  String getCategoryText() {
    if (category == null) {
      return '总预算';
    }
    
    switch (category) {
      case TransactionCategory.food:
        return '餐饮';
      case TransactionCategory.transport:
        return '交通';
      case TransactionCategory.shopping:
        return '购物';
      case TransactionCategory.entertainment:
        return '娱乐';
      case TransactionCategory.housing:
        return '住房';
      case TransactionCategory.utilities:
        return '水电煤';
      case TransactionCategory.health:
        return '医疗健康';
      case TransactionCategory.education:
        return '教育';
      case TransactionCategory.salary:
        return '工资';
      case TransactionCategory.investment:
        return '投资';
      case TransactionCategory.gift:
        return '礼金';
      case TransactionCategory.other:
        return '其他';
      default:
        return '未知';
    }
  }
}