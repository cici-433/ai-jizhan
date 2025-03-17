import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import '../models/transaction.dart';

/// AI识别服务类，用于处理图像识别和语音识别
class RecognitionService {
  static final RecognitionService _instance = RecognitionService._internal();
  final ImagePicker _imagePicker = ImagePicker();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;

  // 单例模式
  factory RecognitionService() => _instance;

  RecognitionService._internal();

  /// 初始化语音识别
  Future<bool> initSpeechRecognition() async {
    // 检查麦克风权限
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) {
        return false;
      }
    }

    // 初始化语音识别
    bool available = await _speechToText.initialize();
    return available;
  }

  /// 开始语音识别
  Future<void> startListening(Function(String) onResult) async {
    if (!_isListening) {
      bool available = await initSpeechRecognition();
      if (available) {
        _isListening = true;
        await _speechToText.listen(
          onResult: (result) {
            onResult(result.recognizedWords);
          },
          localeId: 'zh_CN', // 设置为中文识别
        );
      }
    }
  }

  /// 停止语音识别
  Future<void> stopListening() async {
    if (_isListening) {
      _isListening = false;
      await _speechToText.stop();
    }
  }

  /// 拍照识别
  Future<File?> takePicture() async {
    // 检查相机权限
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        return null;
      }
    }

    // 拍照
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  /// 从相册选择图片
  Future<File?> pickImage() async {
    // 检查相册权限
    var status = await Permission.photos.status;
    if (!status.isGranted) {
      status = await Permission.photos.request();
      if (!status.isGranted) {
        return null;
      }
    }

    // 选择图片
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  /// 使用Google ML Kit进行OCR图像识别
  Future<Map<String, dynamic>> recognizeImage(File imageFile) async {
    try {
      // 创建InputImage对象
      final inputImage = InputImage.fromFile(imageFile);
      
      // 创建文本识别器
      final textRecognizer = GoogleMlKit.vision.textDetector();
      
      // 处理图像并获取识别结果
      final RecognisedText recognizedText = await textRecognizer.processImage(inputImage);
      // 释放资源
      textRecognizer.close();
      
      // 解析识别结果
      return _parseRecognizedText(recognizedText.text);
    } catch (e) {
      print('OCR识别错误: $e');
      // 识别失败时返回空结果
      return {
        'amount': 0.0,
        'date': DateTime.now(),
        'category': null,
        'description': '无法识别',
        'error': e.toString(),
      };
    }
  }
  
  /// 解析识别出的文本
  Map<String, dynamic> _parseRecognizedText(String text) {
    // 默认结果
    Map<String, dynamic> result = {
      'amount': 0.0,
      'date': DateTime.now(),
      'category': TransactionCategory.other,
      'description': '未知消费',
    };
    
    try {
      // 尝试提取金额（寻找带有￥或数字的行）
      final amountRegex = RegExp(r'(¥|￥|\$)?\s*([0-9]+[.,][0-9]{2}|[0-9]+)');
      final amountMatch = amountRegex.firstMatch(text);
      if (amountMatch != null) {
        final amountStr = amountMatch.group(2)?.replaceAll(',', '.') ?? '0';
        result['amount'] = double.tryParse(amountStr) ?? 0.0;
      }
      
      // 尝试提取日期（常见的日期格式）
      final dateRegex = RegExp(r'(\d{4}[-/年]\d{1,2}[-/月]\d{1,2}日?|\d{1,2}[-/月]\d{1,2}日?)');
      final dateMatch = dateRegex.firstMatch(text);
      if (dateMatch != null) {
        final dateStr = dateMatch.group(1) ?? '';
        try {
          // 尝试解析不同格式的日期
          if (dateStr.contains('年')) {
            // 处理中文日期格式
            final parts = dateStr.replaceAll('日', '').split(RegExp(r'[年月]'));
            if (parts.length >= 3) {
              result['date'] = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            }
          } else {
            // 处理数字日期格式
            final cleanDateStr = dateStr.replaceAll('/', '-');
            result['date'] = DateTime.parse(cleanDateStr.length <= 5 ? '${DateTime.now().year}-$cleanDateStr' : cleanDateStr);
          }
        } catch (e) {
          // 日期解析失败，使用当前日期
          result['date'] = DateTime.now();
        }
      }
      
      // 尝试识别类别（基于关键词）
      if (text.contains(RegExp(r'餐|饭|食|菜|酒|咖啡|奶茶'))) {
        result['category'] = TransactionCategory.food;
        result['description'] = '餐饮消费';
      } else if (text.contains(RegExp(r'车|地铁|公交|出租|打车|高铁|火车|机票|飞机'))) {
        result['category'] = TransactionCategory.transport;
        result['description'] = '交通出行';
      } else if (text.contains(RegExp(r'购|买|商场|超市|电商|淘宝|京东|拼多多'))) {
        result['category'] = TransactionCategory.shopping;
        result['description'] = '购物消费';
      } else if (text.contains(RegExp(r'娱乐|游戏|电影|KTV|演唱会|门票'))) {
        result['category'] = TransactionCategory.entertainment;
        result['description'] = '娱乐消费';
      } else if (text.contains(RegExp(r'房|租|水电|物业|宽带'))) {
        result['category'] = TransactionCategory.housing;
        result['description'] = '住房相关';
      } else if (text.contains(RegExp(r'医|药|诊|病|保健|体检'))) {
        result['category'] = TransactionCategory.health;
        result['description'] = '医疗健康';
      } else if (text.contains(RegExp(r'学|教|培训|书|课'))) {
        result['category'] = TransactionCategory.education;
        result['description'] = '教育支出';
      } else {
        // 默认为其他类别，使用前几个字作为描述
        final shortDesc = text.replaceAll(RegExp(r'\s+'), ' ').trim();
        result['description'] = shortDesc.length > 20 ? '${shortDesc.substring(0, 20)}...' : shortDesc;
      }
    } catch (e) {
      print('解析文本错误: $e');
    }
    
    return result;
  }
}