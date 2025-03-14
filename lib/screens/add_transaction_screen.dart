import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/recognition_service.dart';

/// 记账页面
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({Key? key}) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final RecognitionService _recognitionService = RecognitionService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  late TabController _tabController;
  TransactionType _type = TransactionType.expense;
  TransactionCategory _category = TransactionCategory.food;
  DateTime _date = DateTime.now();
  File? _imageFile;
  bool _isRecognizing = false;
  bool _isListening = false;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// 保存交易记录
  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入金额')),
      );
      return;
    }

    try {
      final amount = double.parse(_amountController.text);
      final transaction = Transaction(
        amount: amount,
        type: _type,
        category: _category,
        description: _descriptionController.text.isEmpty
            ? _category.toString().split('.').last
            : _descriptionController.text,
        date: _date,
        imagePath: _imageFile?.path,
      );

      await _databaseService.insertTransaction(transaction);
      _resetForm();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('记账成功')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }

  /// 重置表单
  void _resetForm() {
    setState(() {
      _amountController.clear();
      _descriptionController.clear();
      _type = TransactionType.expense;
      _category = TransactionCategory.food;
      _date = DateTime.now();
      _imageFile = null;
      _recognizedText = '';
    });
  }

  /// 拍照识别
  Future<void> _takePicture() async {
    final imageFile = await _recognitionService.takePicture();
    if (imageFile != null) {
      setState(() {
        _imageFile = imageFile;
        _isRecognizing = true;
      });

      // 识别图片
      try {
        final result = await _recognitionService.recognizeImage(imageFile);
        setState(() {
          _amountController.text = result['amount'].toString();
          _descriptionController.text = result['description'];
          _date = result['date'];
          _isRecognizing = false;
        });
      } catch (e) {
        setState(() {
          _isRecognizing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('识别失败: $e')),
        );
      }
    }
  }

  /// 从相册选择图片
  Future<void> _pickImage() async {
    final imageFile = await _recognitionService.pickImage();
    if (imageFile != null) {
      setState(() {
        _imageFile = imageFile;
        _isRecognizing = true;
      });

      // 识别图片
      try {
        final result = await _recognitionService.recognizeImage(imageFile);
        setState(() {
          _amountController.text = result['amount'].toString();
          _descriptionController.text = result['description'];
          _date = result['date'];
          _isRecognizing = false;
        });
      } catch (e) {
        setState(() {
          _isRecognizing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('识别失败: $e')),
        );
      }
    }
  }

  /// 开始语音识别
  Future<void> _startListening() async {
    bool available = await _recognitionService.initSpeechRecognition();
    if (available) {
      setState(() {
        _isListening = true;
        _recognizedText = '';
      });

      await _recognitionService.startListening((text) {
        setState(() {
          _recognizedText = text;
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('语音识别不可用')),
      );
    }
  }

  /// 停止语音识别
  Future<void> _stopListening() async {
    await _recognitionService.stopListening();
    setState(() {
      _isListening = false;
    });

    // 简单的语音解析逻辑（实际项目中可以使用更复杂的NLP）
    if (_recognizedText.isNotEmpty) {
      // 尝试提取金额
      final amountRegex = RegExp(r'\d+(\.\d+)?');
      final amountMatch = amountRegex.firstMatch(_recognizedText);
      if (amountMatch != null) {
        _amountController.text = amountMatch.group(0)!;
      }

      // 尝试提取分类
      if (_recognizedText.contains('餐饮') || _recognizedText.contains('吃饭')) {
        setState(() {
          _category = TransactionCategory.food;
        });
      } else if (_recognizedText.contains('交通')) {
        setState(() {
          _category = TransactionCategory.transport;
        });
      }

      // 设置描述
      _descriptionController.text = _recognizedText;
    }
  }

  /// 选择日期
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记账'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '扫票识别'),
            Tab(text: '手动记账'),
            Tab(text: '语音记账'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 扫票识别页面
          _buildScanTab(),
          // 手动记账页面
          _buildManualTab(),
          // 语音记账页面
          _buildVoiceTab(),
        ],
      ),
    );
  }

  /// 构建扫票识别页面
  Widget _buildScanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 安全提示
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '所有数据都将保存在本地设备，保护您的隐私安全',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 图片预览/拍照区域
          GestureDetector(
            onTap: _takePicture,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _imageFile!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 48,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '点击拍摄发票/收据',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // 操作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _takePicture,
                icon: const Icon(Icons.camera_alt),
                label: const Text('拍照'),
              ),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('从相册选择'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 识别结果
          if (_isRecognizing)
            const Center(child: CircularProgressIndicator())
          else if (_imageFile != null)
            ..._buildTransactionForm(),
        ],
      ),
    );
  }

  /// 构建手动记账页面
  Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildTransactionForm(),
      ),
    );
  }

  /// 构建语音记账页面
  Widget _buildVoiceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 语音识别区域
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: _isListening ? Colors.blue.withOpacity(0.1) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isListening ? Colors.blue : Colors.grey.shade300,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mic,
                  size: 48,
                  color: _isListening ? Colors.blue : Colors.grey.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  _isListening ? '正在聆听...' : '点击开始语音记账',
                  style: TextStyle(
                    color: _isListening ? Colors.blue : Colors.grey.shade600,
                  ),
                ),
                if (_recognizedText.isNotEmpty) ...[  
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _recognizedText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 语音操作按钮
          ElevatedButton.icon(
            onPressed: _isListening ? _stopListening : _startListening,
            icon: Icon(_isListening ? Icons.stop : Icons.mic),
            label: Text(_isListening ? '停止识别' : '开始语音记账'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isListening ? Colors.red : Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 24),

          // 识别后的表单
          if (_recognizedText.isNotEmpty && !_isListening) ..._buildTransactionForm(),
        ],
      ),
    );
  }

  /// 构建交易表单
  List<Widget> _buildTransactionForm() {
    return [
      // 收入/支出选择
      Row(
        children: [
          Expanded(
            child: RadioListTile<TransactionType>(
              title: const Text('支出'),
              value: TransactionType.expense,
              groupValue: _type,
              onChanged: (value) {
                setState(() {
                  _type = value!;
                  // 切换类型时自动选择对应类型的第一个分类
                  if (_type == TransactionType.income) {
                    _category = TransactionCategory.salary;
                  } else {
                    _category = TransactionCategory.food;
                  }
                });
              },
            ),
          ),
          Expanded(
            child: RadioListTile<TransactionType>(
              title: const Text('收入'),
              value: TransactionType.income,
              groupValue: _type,
              onChanged: (value) {
                setState(() {
                  _type = value!;
                  // 切换类型时自动选择对应类型的第一个分类
                  if (_type == TransactionType.income) {
                    _category = TransactionCategory.salary;
                  } else {
                    _category = TransactionCategory.food;
                  }
                });
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // 金额输入
      TextField(
        controller: _amountController,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: '金额',
          prefixIcon: Icon(Icons.attach_money),
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),

      // 描述输入
      TextField(
        controller: _descriptionController,
        decoration: const InputDecoration(
          labelText: '描述',
          prefixIcon: Icon(Icons.description),
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),

      // 分类选择
      DropdownButtonFormField<TransactionCategory>(
        value: _category,
        decoration: const InputDecoration(
          labelText: '分类',
          prefixIcon: Icon(Icons.category),
          border: OutlineInputBorder(),
        ),
        items: _type == TransactionType.expense
            ? [
                DropdownMenuItem(value: TransactionCategory.food, child: const Text('餐饮')),
                DropdownMenuItem(value: TransactionCategory.transport, child: const Text('交通')),
                DropdownMenuItem(value: TransactionCategory.shopping, child: const Text('购物')),
                DropdownMenuItem(value: TransactionCategory.entertainment, child: const Text('娱乐')),
                DropdownMenuItem(value: TransactionCategory.housing, child: const Text('住房')),
                DropdownMenuItem(value: TransactionCategory.utilities, child: const Text('水电煤')),
                DropdownMenuItem(value: TransactionCategory.health, child: const Text('医疗健康')),
                DropdownMenuItem(value: TransactionCategory.education, child: const Text('教育')),
                DropdownMenuItem(value: TransactionCategory.other, child: const Text('其他')),
              ]
            : [
                DropdownMenuItem(value: TransactionCategory.salary, child: const Text('工资')),
                DropdownMenuItem(value: TransactionCategory.investment, child: const Text('投资收益')),
                DropdownMenuItem(value: TransactionCategory.gift, child: const Text('礼金')),
                DropdownMenuItem(value: TransactionCategory.other, child: const Text('其他')),
              ],
        onChanged: (value) {
          setState(() {
            _category = value!;
          });
        },
      ),
      const SizedBox(height: 16),

      // 日期选择
      InkWell(
        onTap: _selectDate,
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: '日期',
            prefixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(),
          ),
          child: Text(
            DateFormat('yyyy-MM-dd').format(_date),
          ),
        ),
      ),
      const SizedBox(height: 24),

      // 保存按钮
      ElevatedButton.icon(
        onPressed: _saveTransaction,
        icon: const Icon(Icons.save),
        label: const Text('保存'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    ];
  }
}