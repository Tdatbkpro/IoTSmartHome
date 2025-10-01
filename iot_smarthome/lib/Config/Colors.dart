import 'package:flutter/material.dart';

class AppColors {
  /// 🎨 Gradient / Background colors
  static List<Color> conBackgroundColor = [
    Color(0xFF20232A), // sáng hơn để phân tầng
    Color(0xFF0D1117),
  ];

  static List<Color> borderColors = [
    Color(0xFF2D333B),
    Color(0xFF1C1F24),
  ];

  /// 🎨 Progress bar colors
  static List<Color> progressBarBackground = [
    Color(0xFF1E1E1E),
    Color(0xFF0F0F0F),
  ];

  static List<Color> progressBarColor = [
    Color(0xff11A8FD),
    Color(0xff0074D9),
  ];

  // Màu nền chính
  static const Color background = Color(0xFF0D1117); // Nền app (tối nhất)
  static const Color surface = Color(0xFF1E2229);    // Card, AppBar (sáng hơn background)

  // Trạng thái
  static const Color primary = Color(0xFF1E90FF); // xanh dương IoT
  static const Color on = Color(0xFF4CAF50);      // thiết bị bật
  static const Color off = Color(0xFF9E9E9E);     // thiết bị tắt
  static const Color warning = Color(0xFFFF9800); // cảnh báo
  static const Color error = Color(0xFFF44336);   // lỗi

  // Chữ
  static const Color textPrimary = Color(0xFFFFFFFF); // trắng sáng
  static const Color textSecondary = Color(0xFFB0B3B8); // xám nhạt dễ đọc
}
