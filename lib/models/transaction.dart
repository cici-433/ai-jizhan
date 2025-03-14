import 'package:intl/intl.dart';

/// 交易类型枚举
enum TransactionType {
  income,  // 收入
  expense  // 支出
}

/// 交易分类枚举
enum TransactionCategory {
  food,       // 餐饮
  transport,  // 交通
  shopping,   // 购物
  entertainment, // 娱乐
  housing,    // 住房
  utilities,  // 水电煤
  health,     // 医疗健康
  education,  // 教育
  salary,     // 工资
  investment, // 投资收益
  gift,       // 礼金
  other       // 其他
}

/// 交易数据模型
class Transaction {
  int? id;                      // 交易ID
  double amount;                // 交易金额
  TransactionType type;         // 交易类型（收入/支出）
  TransactionCategory category; // 交易分类
  String description;           // 交易描述
  DateTime date;                // 交易日期
  String? imagePath;            // 票据图片路径（可选）

  Transaction({
    this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    this.imagePath,
  });

  /// 从Map创建Transaction对象（用于数据库操作）
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      amount: map['amount'],
      type: TransactionType.values[map['type']],
      category: TransactionCategory.values[map['category']],
      description: map['description'],
      date: DateTime.parse(map['date']),
      imagePath: map['imagePath'],
    );
  }

  /// 将Transaction对象转换为Map（用于数据库操作）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type.index,
      'category': category.index,
      'description': description,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'imagePath': imagePath,
    };
  }

  /// 获取交易分类的显示名称
  String getCategoryName() {
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
        return '投资收益';
      case TransactionCategory.gift:
        return '礼金';
      case TransactionCategory.other:
        return '其他';
    }
  }

  /// 获取交易类型的显示名称
  String getTypeName() {
    return type == TransactionType.income ? '收入' : '支出';
  }
}