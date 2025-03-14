import 'package:flutter/material.dart';

/// 设置页面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 设置项状态
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = '简体中文';
  String _selectedCurrency = 'CNY (¥)';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // 个人信息卡片
          Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '个人信息',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        child: Icon(Icons.person, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '小明',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '用户ID: 10001',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('编辑个人资料'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // 跳转到编辑个人资料页面
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('此功能尚未实现')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // 通知设置
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '通知设置',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('启用通知'),
                    subtitle: const Text('接收记账提醒和预算提醒'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // 应用设置
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '应用设置',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('深色模式'),
                    subtitle: const Text('切换应用主题'),
                    value: _darkModeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _darkModeEnabled = value;
                      });
                      // 实际项目中应该调用主题切换逻辑
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('主题切换功能尚未实现')),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('语言'),
                    subtitle: Text(_selectedLanguage),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showLanguageSelector(context);
                    },
                  ),
                  ListTile(
                    title: const Text('货币'),
                    subtitle: Text(_selectedCurrency),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showCurrencySelector(context);
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // 数据管理
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '数据管理',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text('备份数据'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // 备份数据逻辑
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('备份功能尚未实现')),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('恢复数据'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // 恢复数据逻辑
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('恢复功能尚未实现')),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('清除所有数据', style: TextStyle(color: Colors.red)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showClearDataConfirmation(context);
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // 关于
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '关于',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('关于应用'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showAboutDialog(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('帮助与反馈'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // 跳转到帮助页面
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('帮助功能尚未实现')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // 版本信息
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                '版本 1.0.0',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 显示语言选择器
  void _showLanguageSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('选择语言'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _selectedLanguage = '简体中文';
                });
                Navigator.pop(context);
              },
              child: const Text('简体中文'),
            ),
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _selectedLanguage = 'English';
                });
                Navigator.pop(context);
              },
              child: const Text('English'),
            ),
          ],
        );
      },
    );
  }
  
  // 显示货币选择器
  void _showCurrencySelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('选择货币'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _selectedCurrency = 'CNY (¥)';
                });
                Navigator.pop(context);
              },
              child: const Text('CNY (¥)'),
            ),
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _selectedCurrency = 'USD (\$)';
                });
                Navigator.pop(context);
              },
              child: const Text('USD (\$)'),
            ),
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _selectedCurrency = 'EUR (€)';
                });
                Navigator.pop(context);
              },
              child: const Text('EUR (€)'),
            ),
          ],
        );
      },
    );
  }
  
  // 显示清除数据确认对话框
  void _showClearDataConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('清除所有数据'),
          content: const Text('此操作将删除所有记账数据，且无法恢复。确定要继续吗？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                // 实际项目中应该调用数据清除逻辑
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('数据已清除')),
                );
              },
              child: const Text('确定', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
  
  // 显示关于对话框
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('关于AI自动记账'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI自动记账是一款基于Flutter开发的智能记账应用，旨在帮助用户轻松管理个人财务。'),
              SizedBox(height: 16),
              Text('版本: 1.0.0'),
              Text('开发者: AI团队'),
              SizedBox(height: 16),
              Text('© 2023 AI自动记账 保留所有权利'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }
}