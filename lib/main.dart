import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 导入服务
import 'services/database_service.dart';
import 'services/recognition_service.dart';

// 导入页面
import 'screens/home_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/financial_goal_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>(
          create: (_) => DatabaseService(),
        ),
        Provider<RecognitionService>(
          create: (_) => RecognitionService(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

/// 应用主入口
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI自动记账',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'PingFang SC',
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// 主屏幕，包含底部导航栏
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  // 页面列表
  final List<Widget> _pages = [
    const HomeScreen(),
    const AddTransactionScreen(),
    const StatisticsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: '记账',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '统计',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? null
          : FloatingActionButton(
              onPressed: () {
                setState(() {
                  _currentIndex = 1; // 切换到记账页面
                });
              },
              child: const Icon(Icons.add),
            ),
    );
  }
}
