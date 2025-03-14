import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

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

  /// 简单的图像识别（模拟实现，实际项目中可以接入OCR服务）
  Future<Map<String, dynamic>> recognizeImage(File imageFile) async {
    // 在实际项目中，这里应该调用OCR API进行识别
    // 这里仅做模拟实现，返回一些假数据
    await Future.delayed(Duration(seconds: 2)); // 模拟识别过程

    // 模拟识别结果
    return {
      'amount': 128.50,
      'date': DateTime.now(),
      'category': '餐饮',
      'description': '午餐消费',
    };
  }
}