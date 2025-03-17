import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/financial_goal.dart';

/// 数据库服务类，用于管理本地SQLite数据库
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  // 单例模式
  factory DatabaseService() => _instance;

  DatabaseService._internal();

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ai_jizhan.db');
    return await openDatabase(
      path,
      version: 2,  // 将版本从1升级到2
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 创建预算表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount REAL NOT NULL,
          period INTEGER NOT NULL,
          category INTEGER,
          startDate TEXT NOT NULL,
          note TEXT
        )
      ''');
      
      // 创建财务目标表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS financial_goals(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type INTEGER NOT NULL,
          targetAmount REAL NOT NULL,
          currentAmount REAL NOT NULL,
          startDate TEXT NOT NULL,
          targetDate TEXT NOT NULL,
          status INTEGER NOT NULL,
          note TEXT,
          relatedCategory INTEGER
        )
      ''');
    }
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        type INTEGER NOT NULL,
        category INTEGER NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        imagePath TEXT
      )
    ''');
    
    // 创建预算表
    await db.execute('''
      CREATE TABLE budgets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        period INTEGER NOT NULL,
        category INTEGER,
        startDate TEXT NOT NULL,
        note TEXT
      )
    ''');
    
    // 创建财务目标表
    await db.execute('''
      CREATE TABLE financial_goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        targetAmount REAL NOT NULL,
        currentAmount REAL NOT NULL,
        startDate TEXT NOT NULL,
        targetDate TEXT NOT NULL,
        status INTEGER NOT NULL,
        note TEXT,
        relatedCategory INTEGER
      )
    ''');
  }

  /// 插入交易记录
  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  /// 更新交易记录
  Future<int> updateTransaction(Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  /// 删除交易记录
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取所有交易记录
  Future<List<Transaction>> getAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions');
    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  /// 获取指定日期范围内的交易记录
  Future<List<Transaction>> getTransactionsByDateRange(
      DateTime startDate, DateTime endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [
        startDate.toString().split(' ')[0],
        endDate.toString().split(' ')[0]
      ],
    );
    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  /// 获取指定类型的交易记录（收入/支出）
  Future<List<Transaction>> getTransactionsByType(TransactionType type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type.index],
    );
    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  /// 获取指定分类的交易记录
  Future<List<Transaction>> getTransactionsByCategory(
      TransactionCategory category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'category = ?',
      whereArgs: [category.index],
    );
    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  /// 获取总收入
  Future<double> getTotalIncome() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
        [TransactionType.income.index]);
    return result.first['total'] == null ? 0.0 : result.first['total'] as double;
  }

  /// 获取总支出
  Future<double> getTotalExpense() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
        [TransactionType.expense.index]);
    return result.first['total'] == null ? 0.0 : result.first['total'] as double;
  }

  /// 获取余额（总收入-总支出）
  Future<double> getBalance() async {
    double income = await getTotalIncome();
    double expense = await getTotalExpense();
    return income - expense;
  }

  // ==================== 预算相关操作 ====================

  /// 插入预算
  Future<int> insertBudget(Budget budget) async {
    final db = await database;
    return await db.insert('budgets', budget.toMap());
  }

  /// 更新预算
  Future<int> updateBudget(Budget budget) async {
    final db = await database;
    return await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  /// 删除预算
  Future<int> deleteBudget(int id) async {
    final db = await database;
    return await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取所有预算
  Future<List<Budget>> getAllBudgets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('budgets');
    return List.generate(maps.length, (i) {
      return Budget.fromMap(maps[i]);
    });
  }

  /// 获取特定分类的预算
  Future<Budget?> getBudgetByCategory(TransactionCategory category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'category = ?',
      whereArgs: [category.index],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Budget.fromMap(maps.first);
  }

  /// 获取总体预算（无分类）
  Future<Budget?> getOverallBudget() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'category IS NULL',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Budget.fromMap(maps.first);
  }

  /// 获取当前活跃的预算（基于日期）
  Future<List<Budget>> getActiveBudgets() async {
    final db = await database;
    final now = DateTime.now();
    final List<Map<String, dynamic>> maps = await db.query('budgets');
    
    // 过滤出当前活跃的预算
    List<Budget> allBudgets = maps.map((map) => Budget.fromMap(map)).toList();
    return allBudgets.where((budget) {
      final endDate = budget.getEndDate();
      return now.isAfter(budget.startDate) && now.isBefore(endDate) || 
             now.isAtSameMomentAs(budget.startDate) || 
             now.isAtSameMomentAs(endDate);
    }).toList();
  }

  // ==================== 财务目标相关操作 ====================

  /// 插入财务目标
  Future<int> insertFinancialGoal(FinancialGoal goal) async {
    final db = await database;
    return await db.insert('financial_goals', goal.toMap());
  }

  /// 更新财务目标
  Future<int> updateFinancialGoal(FinancialGoal goal) async {
    final db = await database;
    return await db.update(
      'financial_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  /// 删除财务目标
  Future<int> deleteFinancialGoal(int id) async {
    final db = await database;
    return await db.delete(
      'financial_goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取所有财务目标
  Future<List<FinancialGoal>> getAllFinancialGoals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('financial_goals');
    return List.generate(maps.length, (i) {
      return FinancialGoal.fromMap(maps[i]);
    });
  }

  /// 获取特定类型的财务目标
  Future<List<FinancialGoal>> getFinancialGoalsByType(GoalType type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'financial_goals',
      where: 'type = ?',
      whereArgs: [type.index],
    );
    return List.generate(maps.length, (i) {
      return FinancialGoal.fromMap(maps[i]);
    });
  }

  /// 获取特定状态的财务目标
  Future<List<FinancialGoal>> getFinancialGoalsByStatus(GoalStatus status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'financial_goals',
      where: 'status = ?',
      whereArgs: [status.index],
    );
    return List.generate(maps.length, (i) {
      return FinancialGoal.fromMap(maps[i]);
    });
  }
}