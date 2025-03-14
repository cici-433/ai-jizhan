import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models/transaction.dart';

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
      version: 1,
      onCreate: _onCreate,
    );
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
}