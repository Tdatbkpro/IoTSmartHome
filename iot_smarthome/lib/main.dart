import 'dart:typed_data';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:iot_smarthome/Config/PagePath.dart';
import 'package:iot_smarthome/Controllers/ThemeController.dart';
import 'package:iot_smarthome/Pages/SlacePage.dart';
import 'package:iot_smarthome/Config/Theme.dart'; // nơi chứa lightTheme, darkTheme
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Biến toàn cục
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// 🎯 Hàm xử lý thông báo nền - ĐÃ TỐI ƯU
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  print("🔔 Nhận thông báo nền: ${message.notification?.title}");
  
  // Tạo ID duy nhất cho thông báo
  final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
  
  // Hiển thị thông báo với AwesomeNotifications
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: notificationId,
      channelKey: 'alert_channel_v2',
      title: message.notification?.title ?? '🚨 Cảnh báo an ninh',
      body: message.notification?.body ?? 'Phát hiện chuyển động đáng ngờ!',
      notificationLayout: NotificationLayout.BigText,
      actionType: ActionType.Default,
      payload: {'type': 'intrusion', 'timestamp': DateTime.now().toString()},
    ),
  );
}

/// 🎯 Hàm khởi tạo ứng dụng
Future<void> main() async {
  // Đảm bảo binding Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Cấu hình ngôn ngữ
  FirebaseAuth.instance.setLanguageCode('vi');
  
  // Khởi tạo SharedPreferences
  await SharedPreferences.getInstance();
  
  // Khởi tạo controller
  Get.put(ThemeController());
  
  // 🎯 KHỞI TẠO NOTIFICATIONS - ĐÃ CẢI TIẾN
  await _initializeNotifications();
  
  // 🎯 ĐĂNG KÝ XỬ LÝ THÔNG BÁO - ĐÃ CẢI TIẾN
  await _setupFirebaseMessaging();
  
  // 🎯 LẬP LỊCH THÔNG BÁO ĐỊNH KỲ
  await _scheduleDailyGreetings();
  
  runApp(const MyApp());
}

/// 🎯 Khởi tạo hệ thống thông báo
Future<void> _initializeNotifications() async {
  await AwesomeNotifications().initialize(
    null, // null để sử dụng icon mặc định của app
    [
      NotificationChannel(
        channelKey: 'alert_channel_v2',
        channelName: '🚨 Cảnh báo khẩn cấp',
        channelDescription: 'Thông báo khi phát hiện chuyển động đáng ngờ',
        defaultColor: const Color(0xFFE74C3C),
        ledColor: Colors.red,
        importance: NotificationImportance.Max,
        playSound: true,
        soundSource: 'resource://raw/alert_sound',
        enableVibration: true,
        vibrationPattern: Int64List.fromList([200, 100, 200, 100, 200]),
      ),
      NotificationChannel(
        channelKey: 'daily_channel',
        channelName: '💌 Lời chúc hàng ngày',
        channelDescription: 'Thông báo chúc bạn mỗi buổi trong ngày',
        defaultColor: const Color(0xFF3498DB),
        ledColor: Colors.blue,
        importance: NotificationImportance.High,
        playSound: true,
        soundSource: 'resource://raw/notification_sound',
      ),
    ],
    debug: true,
  );

  // Kiểm tra và yêu cầu quyền thông báo
  final isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    await _showNotificationPermissionDialog();
  }
}

/// 🎯 Hiển thị dialog yêu cầu quyền thông báo
Future<void> _showNotificationPermissionDialog() async {
  // Trong thực tế, bạn có thể hiển thị một dialog giải thích lý do cần thông báo
  await AwesomeNotifications().requestPermissionToSendNotifications(
    permissions: [
      NotificationPermission.Alert,
      NotificationPermission.Sound,
      NotificationPermission.Vibration,
      NotificationPermission.Light,
    ],
  );
}

/// 🎯 Thiết lập Firebase Messaging
Future<void> _setupFirebaseMessaging() async {
  // Đăng ký xử lý thông báo nền
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Xử lý thông báo foreground với UI đẹp hơn
  FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

  // Đăng ký topic
  try {
    await FirebaseMessaging.instance.subscribeToTopic("alert_pir");
    print("✅ Đã đăng ký topic: alert_pir");
  } catch (e) {
    print("❌ Lỗi đăng ký topic: $e");
  }

  // Cấu hình iOS
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
}

/// 🎯 Xử lý thông báo foreground với UI đẹp
void _handleForegroundMessage(RemoteMessage message) {
  print("🔔 Nhận thông báo foreground: ${message.notification?.title}");

  // Hiển thị custom dialog đẹp mắt
  Get.dialog(
    _buildCustomAlertDialog(message),
    barrierDismissible: false,
  );
}

/// 🎯 Xây dựng custom alert dialog đẹp mắt
Widget _buildCustomAlertDialog(RemoteMessage message) {
  return Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20.0),
    ),
    elevation: 0,
    backgroundColor: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon cảnh báo
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFE74C3C),
              size: 35,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tiêu đề
          Text(
            message.notification?.title ?? '🚨 CẢNH BÁO AN NINH',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Nội dung
          Text(
            message.notification?.body ?? 'Phát hiện chuyển động đáng ngờ trong khu vực!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          // Nút hành động
          Row(
            children: [
              // Nút bỏ qua
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: const Text(
                      'Bỏ qua',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Nút xem chi tiết
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () {
                      Get.back();
                      _handleAlertAction(message);
                    },
                    child: const Text(
                      'Xem chi tiết',
                      style: TextStyle(
                        color: Color(0xFFE74C3C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// 🎯 Xử lý khi nhấn nút xem chi tiết
void _handleAlertAction(RemoteMessage message) {
  // Điều hướng đến màn hình chi tiết cảnh báo
  Get.to(() => AlertDetailScreen(
    title: message.notification?.title ?? 'Cảnh báo',
    body: message.notification?.body ?? 'Có sự kiện đáng ngờ',
    timestamp: DateTime.now(),
  ));
}

/// 🎯 Lập lịch thông báo chúc mừng hàng ngày
/// 🎯 Lập lịch thông báo chúc mừng hàng ngày - ĐÃ SỬA
Future<void> _scheduleDailyGreetings() async {
  final now = DateTime.now();
  final greeting = _getDailyGreeting(now);
  
  // Gọi các hàm async
  await _createMorningSchedule(greeting.morning);
  await _createAfternoonSchedule(greeting.afternoon);
  await _createEveningSchedule(greeting.evening);
}

/// 🎯 Lấy lời chúc theo buổi
class DailyGreeting {
  final String morning;
  final String afternoon;
  final String evening;
  
  DailyGreeting({
    required this.morning,
    required this.afternoon,
    required this.evening,
  });
}

DailyGreeting _getDailyGreeting(DateTime now) {
  return DailyGreeting(
    morning: '🌅 Chúc bạn buổi sáng tràn đầy năng lượng!',
    afternoon: '☀️ Chúc bạn buổi chiều làm việc hiệu quả!',
    evening: '🌙 Chúc bạn buổi tối thư giãn và bình an!',
  );
}

/// 🎯 Tạo lịch cho buổi sáng
/// 🎯 Tạo lịch cho buổi sáng - ĐÃ SỬA
Future<void> _createMorningSchedule(String message) async {
  await AwesomeNotifications().createNotification(
    content: NotificationContent( // THÊM NAMED PARAMETER 'content:'
      id: 2001,
      channelKey: 'daily_channel',
      title: '🌅 Lời chào buổi sáng',
      body: message,
      notificationLayout: NotificationLayout.BigText,
      payload: {'type': 'morning_greeting'},
    ),
    schedule: NotificationCalendar(
      hour: 7,
      minute: 0,
      repeats: true,
    ),
  );
}

/// 🎯 Tạo lịch cho buổi chiều - ĐÃ SỬA
Future<void> _createAfternoonSchedule(String message) async {
  await AwesomeNotifications().createNotification(
    content: NotificationContent( // THÊM NAMED PARAMETER 'content:'
      id: 2002,
      channelKey: 'daily_channel',
      title: '☀️ Lời chào buổi chiều',
      body: message,
      notificationLayout: NotificationLayout.BigText,
      payload: {'type': 'afternoon_greeting'},
    ),
    schedule: NotificationCalendar(
      hour: 12,
      minute: 0,
      repeats: true,
    ),
  );
}

/// 🎯 Tạo lịch cho buổi tối - ĐÃ SỬA
Future<void> _createEveningSchedule(String message) async {
  await AwesomeNotifications().createNotification(
    content: NotificationContent( // THÊM NAMED PARAMETER 'content:'
      id: 2003,
      channelKey: 'daily_channel',
      title: '🌙 Lời chào buổi tối',
      body: message,
      notificationLayout: NotificationLayout.BigText,
      payload: {'type': 'evening_greeting'},
    ),
    schedule: NotificationCalendar(
      hour: 18,
      minute: 0,
      repeats: true,
    ),
  );
}

/// 🎯 Màn hình chi tiết cảnh báo (ví dụ)
class AlertDetailScreen extends StatelessWidget {
  final String title;
  final String body;
  final DateTime timestamp;

  const AlertDetailScreen({
    Key? key,
    required this.title,
    required this.body,
    required this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết cảnh báo'),
        backgroundColor: const Color(0xFFE74C3C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // UI chi tiết cảnh báo
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(body, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text(
              'Thời gian: ${DateFormat('HH:mm dd/MM/yyyy').format(timestamp)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// Lưu ý: Cần thêm import cho DateFormat
// import 'package:intl/intl.dart';
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return GetMaterialApp(
      title: "SmartHome",
      getPages: pagePath,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode.value, // mặc định chạy darkTheme
      debugShowCheckedModeBanner: false,
      home: const SlacePage(), // màn hình khởi chạy
      
    );
  }
}
