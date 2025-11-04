import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

class TelegramService extends GetxService {
  static TelegramService get instance => Get.find<TelegramService>();
  
  final String _botToken = '7963798042:AAE-3A9vmugmX19mjq2vleamWJmpGbEgL2w';
  final String _chatId = '8436437909'; // Chat ID của bạn
  bool _isEnabled = true;

  /// 🚀 Gửi cảnh báo đến Telegram
  Future<void> sendAlertNotification({
    required String title,
    required String message,
    required String deviceName,
    required String location,
    String? imageUrl,
  }) async {
    if (!_isEnabled) {
      print('🔕 Thông báo Telegram đã tắt');
      return;
    }

    try {
      final String telegramMessage = """
🚨 *${_escapeMarkdown(title)}* 🚨

📋 *Thông báo:* ${_escapeMarkdown(message)}
📱 *Thiết bị:* ${_escapeMarkdown(deviceName)}
📍 *Vị trí:* ${_escapeMarkdown(location)}
⏰ *Thời gian:* ${_escapeMarkdown(_formatTime(DateTime.now()))}

_Cảnh báo từ hệ thống SmartHome_ 🔒
      """;

      final response = await http.post(
        Uri.parse('https://api.telegram.org/bot$_botToken/sendMessage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': _chatId,
          'text': telegramMessage,
          'parse_mode': 'MarkdownV2',
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Đã gửi cảnh báo đến Telegram');
      } else {
        print('❌ Lỗi gửi Telegram: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Lỗi gửi Telegram: $e');
    }
  }

  /// 🖼️ Gửi cảnh báo có ảnh
  Future<void> sendAlertWithPhoto({
    required String title,
    required String message,
    required String deviceName,
    required String location,
    required String imageUrl,
  }) async {
    if (!_isEnabled) return;

    try {
      final String caption = """
🚨 *${_escapeMarkdown(title)}*

📋 ${_escapeMarkdown(message)}
📱 ${_escapeMarkdown(deviceName)}
📍 ${_escapeMarkdown(location)}
⏰ ${_escapeMarkdown(_formatTime(DateTime.now()))}
      """;

      final response = await http.post(
        Uri.parse('https://api.telegram.org/bot$_botToken/sendPhoto'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': _chatId,
          'photo': imageUrl,
          'caption': caption,
          'parse_mode': 'MarkdownV2',
        }),
      );

      if (response.statusCode != 200) {
        // Fallback to text message
        await sendAlertNotification(
          title: title,
          message: message,
          deviceName: deviceName,
          location: location,
        );
      }
    } catch (e) {
      // Fallback to text message
      await sendAlertNotification(
        title: title,
        message: message,
        deviceName: deviceName,
        location: location,
      );
    }
  }

  /// ⚙️ Định dạng thời gian
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} ${time.day}/${time.month}/${time.year}';
  }

  /// 🔧 Escape ký tự Markdown
  String _escapeMarkdown(String text) {
    final charactersToEscape = ['_', '*', '[', ']', '(', ')', '~', '`', '>', '#', '+', '-', '=', '|', '{', '}', '.', '!'];
    String escapedText = text;
    for (var char in charactersToEscape) {
      escapedText = escapedText.replaceAll(char, '\\$char');
    }
    return escapedText;
  }

  /// ⚙️ Bật/tắt thông báo
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    print('🔧 Thông báo Telegram ${enabled ? 'đã bật' : 'đã tắt'}');
  }

  /// 🔍 Kiểm tra trạng thái
  bool get isEnabled => _isEnabled;
  String get chatId => _chatId;

  /// 🧪 Test kết nối
  Future<void> testConnection() async {
    print('🧪 Testing Telegram connection...');
    await sendAlertNotification(
      title: 'TEST - Kết nối thành công!',
      message: 'Bot Telegram đã sẵn sàng nhận cảnh báo',
      deviceName: 'Hệ thống SmartHome',
      location: 'Ứng dụng di động',
    );
  }
}