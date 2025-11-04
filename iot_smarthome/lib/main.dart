import 'dart:typed_data';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Config/PagePath.dart';
import 'package:iot_smarthome/Controllers/Auth.dart';
import 'package:iot_smarthome/Controllers/LoginDeviceController.dart';
import 'package:iot_smarthome/Controllers/ThemeController.dart';
import 'package:iot_smarthome/Controllers/UnifiedNotificationController.dart';
import 'package:iot_smarthome/Models/UnifiedNotificationModel.dart';
import 'package:iot_smarthome/Pages/Home/HomePage.dart';
import 'package:iot_smarthome/Pages/Notification/NotificationsPage.dart';
import 'package:iot_smarthome/Pages/Notification/Widget/NotificationDetail.dart';
import 'package:iot_smarthome/Pages/SlacePage.dart';
import 'package:iot_smarthome/Services/AutoLogoutService.dart';
import 'package:iot_smarthome/Services/InvitationService.dart';
import 'package:iot_smarthome/Services/TelegramService.dart';

import 'package:iot_smarthome/config/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

// Biến toàn cục
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final themeController = Get.put(ThemeController());

/// 🎯 Hàm xử lý thông báo nền - ĐÃ THÊM ACTION NHANH
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  print("🔔 Nhận thông báo nền: ${message.notification?.title}");
  print("🔔 Data: ${message.data}");
  
  // 🎯 KIỂM TRA USER ID
  final prefs = await SharedPreferences.getInstance();
  final currentUserId = prefs.getString('current_user_id');
  final messageUserId = message.data['userId'];
  
  if (messageUserId != null && currentUserId != null && messageUserId != currentUserId) {
    print("🚫 Thông báo không dành cho user hiện tại");
    return;
  }
  
  if (currentUserId == null) {
    print("🚫 Không có user đăng nhập");
    return;
  }

  // 🚨 GỬI CẢNH BÁO ĐẾN TELEGRAM (chỉ cho device alerts)
  final notificationType = message.data['type'];
  if (notificationType == 'deviceAlert') {
    try {
      await TelegramService.instance.sendAlertNotification(
        title: message.notification?.title ?? '🚨 Cảnh báo an ninh',
        message: message.notification?.body ?? 'Phát hiện chuyển động đáng ngờ!',
        deviceName: message.data['deviceName'] ?? 'Thiết bị an ninh',
        location: message.data['locationDevice'] ?? 'Vị trí không xác định',
      );
      print('✅ Đã gửi cảnh báo đến Telegram');
    } catch (e) {
      print('❌ Lỗi gửi Telegram: $e');
    }
  }
  
  // Tạo local notification
  final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
  
  final isUrgent = notificationType == 'deviceAlert' ||
    (message.notification?.title?.toLowerCase().contains('cảnh báo') ?? false);

  // 🎯 XÁC ĐỊNH ACTION BUTTONS THEO LOẠI NOTIFICATION
  List<NotificationActionButton> actionButtons = [];
  
  if (notificationType == 'invitation') {
    // 🎯 ACTION CHO INVITATION
    actionButtons = [
      NotificationActionButton(
        key: 'reject',
        label: 'Từ chối',
        color: Colors.red,
        autoDismissible: true,
      ),
      NotificationActionButton(
        key: 'accept', 
        label: 'Chấp nhận',
        color: Colors.green,
        autoDismissible: true,
      ),
    ];
  } else if (notificationType == 'deviceAlert') {
    // 🎯 ACTION CHO DEVICE ALERT
    actionButtons = [
      NotificationActionButton(
        key: 'mark_read',
        label: 'Đánh dấu đã đọc',
        color: Colors.blue,
        autoDismissible: true,
      ),
      NotificationActionButton(
        key: 'view_details',
        label: 'Xem chi tiết',
        color: Colors.orange,
        autoDismissible: false, // Không tự đóng để user có thể xem chi tiết
      ),
    ];
  } else if (notificationType == 'invitation_response') {
    // 🎯 ACTION CHO INVITATION RESPONSE
    actionButtons = [
      NotificationActionButton(
        key: 'view_invitation',
        label: 'Xem lời mời',
        color: Colors.purple,
        autoDismissible: false
      ),
    ];
  }

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: notificationId,
      channelKey: isUrgent ? 'alert_channel_v2' : 'daily_channel',
      title: message.notification?.title ?? _getDefaultTitle(notificationType),
      body: message.notification?.body ?? _getDefaultBody(notificationType, message.data),
      notificationLayout: NotificationLayout.BigText,
      actionType: ActionType.Default,
      payload: {
        'type': notificationType ?? 'unknown',
        'timestamp': DateTime.now().toString(),
        'sound_played': 'true',
        'userId': currentUserId,
        // 🎯 THÊM THÔNG TIN CẦN THIẾT CHO ACTION
        'invitationId': message.data['invitationId'],
        'homeId': message.data['homeId'],
        'fromUserId': message.data['fromUserId'],
        'deviceId': message.data['deviceId'],
        'notificationId': notificationId.toString(),
      },
    ),
    actionButtons: actionButtons,
  );
  
  print("🔊 Đã xử lý thông báo cho user: $currentUserId với ${actionButtons.length} action buttons");
}

/// 🎯 Lấy tiêu đề mặc định theo loại notification
String _getDefaultTitle(String? type) {
  switch (type) {
    case 'deviceAlert':
      return '🚨 Cảnh báo an ninh';
    case 'invitation':
      return '📨 Lời mời tham gia nhà';
    case 'invitation_response':
      return '📩 Phản hồi lời mời';
    default:
      return '💬 Thông báo mới';
  }
}

/// 🎯 Lấy nội dung mặc định theo loại notification
String _getDefaultBody(String? type, Map<String, dynamic> data) {
  switch (type) {
    case 'deviceAlert':
      return 'Phát hiện chuyển động đáng ngờ!';
    case 'invitation':
      return '${data['fromUserName'] ?? 'Ai đó'} mời bạn tham gia ngôi nhà';
    case 'invitation_response':
      final status = data['status'];
      return status == 'accepted' ? 'Lời mời được chấp nhận' : 'Lời mời bị từ chối';
    default:
      return 'Bạn có thông báo mới';
  }
}

/// 🎯 Hàm khởi tạo ứng dụng - ĐÃ CẬP NHẬT
Future<void> main() async {
  // Đảm bảo binding Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Cấu hình ngôn ngữ
  FirebaseAuth.instance.setLanguageCode('vi');
  
  // Khởi tạo SharedPreferences
  await SharedPreferences.getInstance();
  
  // 🎯 KHỞI TẠO CONTROLLER - THÊM UNIFIED NOTIFICATION CONTROLLER
  Get.put(ThemeController());
  Get.put(AuthController());
  Get.put(AutoLogoutService());
  Get.put(LoginDeviceController());
  Get.put(TelegramService());
  Get.put(InvitationService());
  Get.put(UnifiedNotificationController()); // 🎯 THÊM CONTROLLER MỚI
  
  // 🎯 THEO DÕI THAY ĐỔI USER ĐỂ CẬP NHẬT TOPIC
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (user != null) {
      // User đã đăng nhập - đăng ký topic mới và lưu userId
      final userTopic = "alert_${user.uid}";
      try {
        await FirebaseMessaging.instance.subscribeToTopic(userTopic);
        print("✅ Đã đăng ký topic cho user: $userTopic");
        
        // 🎯 LƯU USER ID VÀO SHAREDPREFERENCES
        await prefs.setString('current_user_id', user.uid);
        print("✅ Đã lưu userId: ${user.uid}");
        
      } catch (e) {
        print("❌ Lỗi đăng ký topic sau login: $e");
      }
    } else {
      // User đăng xuất - hủy topic và xóa userId
      try {
        final previousUserId = prefs.getString('current_user_id');
        
        if (previousUserId != null) {
          final userTopic = "alert_$previousUserId";
          await FirebaseMessaging.instance.unsubscribeFromTopic(userTopic);
          print("✅ Đã hủy đăng ký topic sau khi logout: $userTopic");
        }
        
        await prefs.remove('current_user_id');
        print("✅ Đã xóa userId khỏi storage");
        
      } catch (e) {
        print("❌ Lỗi hủy đăng ký topic sau logout: $e");
      }
    }
  });
  
  // KHỞI TẠO NOTIFICATIONS
  await _initializeNotifications();
  await _setupFirebaseMessaging();
  await _scheduleDailyGreetings();
  
  runApp(const MyApp());
}

/// 🎯 Khởi tạo hệ thống thông báo
Future<void> _initializeNotifications() async {
  try {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'alert_channel_v2',
          channelName: '🚨 Cảnh báo khẩn cấp',
          channelDescription: 'Thông báo khi phát hiện chuyển động đáng ngờ',
          defaultColor: const Color(0xFFE74C3C),
          ledColor: Colors.red,
          importance: NotificationImportance.High,
          playSound: true,
          soundSource: 'resource://raw/alert_sound',
          enableVibration: true,
          channelShowBadge: true,
        ),
        NotificationChannel(
          channelKey: 'daily_channel',
          channelName: '💌 Thông báo thường',
          channelDescription: 'Thông báo lời mời và thông báo hệ thống',
          defaultColor: const Color(0xFF3498DB),
          ledColor: Colors.blue,
          importance: NotificationImportance.Default,
          playSound: true,
          soundSource: 'resource://raw/notification_sound',
          enableVibration: false,
          channelShowBadge: true,
        ),
      ],
      debug: true,
    );

    print('✅ Đã khởi tạo notification channels');
    
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkAndRequestNotificationPermission();
    
  } catch (e) {
    print('❌ Lỗi khởi tạo notifications: $e');
  }
}

/// 🎯 Kiểm tra và yêu cầu quyền thông báo
Future<bool> _checkAndRequestNotificationPermission() async {
  try {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    
    print('🔍 Trạng thái quyền thông báo: $isAllowed');
    
    if (!isAllowed) {
      print('🔄 Yêu cầu quyền thông báo...');
      
      final result = await AwesomeNotifications().requestPermissionToSendNotifications(
        permissions: [
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Vibration,
          NotificationPermission.Light,
          NotificationPermission.Badge,
          NotificationPermission.CriticalAlert,
        ],
        channelKey: 'alert_channel_v2',
      );
      
      print('✅ Kết quả yêu cầu quyền: $result');
      
      if (!result) {
        print('⚠️ Người dùng từ chối quyền thông báo');
        _showManualPermissionGuide();
      }
      
      return result;
    }
    
    print('✅ Đã có đầy đủ quyền thông báo');
    return true;
  } catch (e) {
    print('❌ Lỗi khi yêu cầu quyền: $e');
    return false;
  }
}

/// 🎯 Hiển thị hướng dẫn bật thông báo thủ công
void _showManualPermissionGuide() {
  if (Get.context == null || !Get.context!.mounted) return;
  
  Get.dialog(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Column(
        children: [
          Icon(Icons.settings, color: Color(0xFF3498DB), size: 50),
          SizedBox(height: 10),
          Text(
            'Hướng dẫn bật thông báo',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Để nhận cảnh báo an ninh, vui lòng:'),
          SizedBox(height: 10),
          Text('1. Vào Cài đặt > Ứng dụng'),
          Text('2. Chọn "SmartHome"'),
          Text('3. Bật "Cho phép thông báo"'),
          SizedBox(height: 10),
          Text('📱 Thao tác này rất quan trọng để nhận cảnh báo kịp thời!',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Đã hiểu'),
        ),
      ],
    ),
  );
}

/// 🎯 Thiết lập Firebase Messaging - ĐÃ CẬP NHẬT
Future<void> _setupFirebaseMessaging() async {
  // Đăng ký xử lý thông báo nền
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Xử lý thông báo foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // 🎯 KIỂM TRA USER ID
    final messageUserId = message.data['userId'];
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    if (messageUserId != null && currentUserId != null && messageUserId != currentUserId) {
      print("🚫 Thông báo foreground không dành cho user hiện tại, bỏ qua");
      return;
    }
    
    _handleForegroundMessage(message);
  });

  // 🎯 ĐĂNG KÝ TOPIC THEO USER ID
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userTopic = "alert_${currentUser.uid}";
      await FirebaseMessaging.instance.subscribeToTopic(userTopic);
      print("✅ Đã đăng ký topic cho user: $userTopic");
    }
  } catch (e) {
    print("❌ Lỗi đăng ký topic user: $e");
  }

  // Cấu hình iOS
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
}
void _setupNotificationActionHandlers() {
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: onActionReceivedMethod,
  );
}

@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
  // Ép kiểu payload thành Map<String, String> an toàn
  final rawPayload = receivedAction.payload ?? {};
  final payload = Map.fromEntries(
    rawPayload.entries.where((e) => e.value != null)
      .map((e) => MapEntry(e.key, e.value!))
  );

  final buttonKey = receivedAction.buttonKeyPressed;
  final notificationType = payload['type'];
  final userId = payload['userId'];

  print("🎯 Notification action pressed: $buttonKey");
  print("🎯 Notification type: $notificationType");
  print("🎯 Payload: $payload");

  // 🎯 Kiểm tra user ID
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (userId != null && currentUserId != null && userId != currentUserId) {
    print("🚫 Action không dành cho user hiện tại");
    return;
  }

  // 🎯 Xử lý action theo loại notification
  switch (notificationType) {
    case 'invitation':
      _handleInvitationAction(buttonKey, payload);
      break;
    case 'deviceAlert':
      _handleDeviceAlertAction(buttonKey, payload);
      break;
    case 'invitation_response':
      _handleInvitationResponseAction(buttonKey, payload);
      break;
    default:
      _handleGenericAction(buttonKey, payload);
  }
}


/// 🎯 Xử lý action cho invitation
void _handleInvitationAction(String? buttonKey, Map<String, String> payload) async {
  final invitationId = payload['invitationId'];
  final notificationController = Get.find<UnifiedNotificationController>();
  
  if (buttonKey == 'accept') {
    print("✅ User chấp nhận lời mời: $invitationId");
    
    try {
      await notificationController.respondToInvitation(invitationId!, 'accepted');
      
      // Hiển thị thông báo thành công
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'daily_channel',
          title: '✅ Đã chấp nhận lời mời',
          body: 'Bạn đã tham gia ngôi nhà thành công',
          notificationLayout: NotificationLayout.BigText,
        ),
      );
    } catch (e) {
      print('❌ Lỗi khi chấp nhận lời mời: $e');
    }
    
  } else if (buttonKey == 'reject') {
    print("❌ User từ chối lời mời: $invitationId");
    
    try {
      await notificationController.respondToInvitation(invitationId!, 'rejected');
      
      // Hiển thị thông báo
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'daily_channel',
          title: '❌ Đã từ chối lời mời',
          body: 'Bạn đã từ chối lời mời tham gia',
          notificationLayout: NotificationLayout.BigText,
        ),
      );
    } catch (e) {
      print('❌ Lỗi khi từ chối lời mời: $e');
    }
  }
}

/// 🎯 Xử lý action cho device alert
void _handleDeviceAlertAction(String? buttonKey, Map<String, String> payload) async {
  final notificationId = payload['notificationId'];
  final deviceId = payload['deviceId'];
  final notificationController = Get.find<UnifiedNotificationController>();
  
  if (buttonKey == 'mark_read') {
    print("📖 User đánh dấu đã đọc: $notificationId");
    
    try {
      if (notificationId != null) {
        await notificationController.markAsRead(notificationId);
      }
      
      // Hiển thị thông báo
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'daily_channel',
          title: '📖 Đã đánh dấu đã đọc',
          body: 'Cảnh báo đã được đánh dấu là đã đọc',
          notificationLayout: NotificationLayout.BigText,
        ),
      );
    } catch (e) {
      print('❌ Lỗi khi đánh dấu đã đọc: $e');
    }
    
  } else if (buttonKey == 'view_details') {
    print("👁️ User muốn xem chi tiết: $deviceId");
    
    // Điều hướng đến màn hình chi tiết
    // Lấy thông tin notification từ payload và điều hướng
    final notification = UnifiedNotificationModel(
      id: payload['notificationId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.deviceAlert,
      message: 'Cảnh báo an ninh',
      isRead: false,
      isProcessed: false,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      createdAt: DateTime.now(),
      deviceId: payload['deviceId'],
      homeId: payload['homeId'],
      deviceName: 'Thiết bị an ninh',
    );
    
    // Sử dụng Get để điều hướng (cần được gọi trong context phù hợp)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.to(() => NotificationDetailPage(notification: notification));
    });
  }
}

/// 🎯 Xử lý action cho invitation response
void _handleInvitationResponseAction(String? buttonKey, Map<String, String> payload) {
  if (buttonKey == 'view_invitation') {
    print("📨 User muốn xem chi tiết lời mời");
    
    // Điều hướng đến màn hình notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.toNamed('/notifications');
    });
  }
}

/// 🎯 Xử lý action generic
void _handleGenericAction(String? buttonKey, Map<String, String> payload) {
  print("🔔 Action generic: $buttonKey");
  // Mở app hoặc điều hướng đến màn hình chính
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Get.toNamed('/home');
  });
}
/// 🎯 Xử lý thông báo foreground - ĐÃ CẬP NHẬT CHO UNIFIED MODEL
void _handleForegroundMessage(RemoteMessage message) async {
  print("🔔 Nhận thông báo foreground: ${message.notification?.title}");
  print("🔔 Data: ${message.data}");

  // 🎯 KIỂM TRA USER ID
  final prefs = await SharedPreferences.getInstance();
  final currentUserId = prefs.getString('current_user_id');
  final messageUserId = message.data['userId'];
  
  if (messageUserId != null && currentUserId != null && messageUserId != currentUserId) {
    print("🚫 Thông báo không dành cho user hiện tại");
    return;
  }

  // 🎯 XỬ LÝ THEO LOẠI NOTIFICATION
  final notificationType = message.data['type'];
  
  if (notificationType == 'invitation' || notificationType == 'invitation_response') {
    _handleInvitationNotification(message);
  } else if (notificationType == 'deviceAlert') {
    _handleDeviceAlertNotification(message);
  } else {
    _handleGenericNotification(message);
  }
}

/// 🎯 Xử lý invitation notification
void _handleInvitationNotification(RemoteMessage message) {
  final data = message.data;
  final type = data['type'];
  
  if (type == 'invitation') {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.mail_outline, color: Colors.blue, size: 50),
            SizedBox(height: 10),
            Text(
              '📨 Lời mời tham gia nhà',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          '${data['fromUserName']} mời bạn tham gia ngôi nhà ${data['homeName']}',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Để sau'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Điều hướng đến màn hình notifications
              Get.toNamed("/notifications");
            },
            child: const Text('Xem ngay'),
          ),
        ],
      ),
    );
  } else if (type == 'invitation_response') {
    final status = data['status'];
    final title = status == 'accepted' ? '✅ Đã chấp nhận' : '❌ Đã từ chối';
    final content = status == 'accepted'
        ? '${data['fromUserEmail']} đã tham gia ngôi nhà ${data['homeName']}'
        : '${data['fromUserEmail']} đã từ chối lời mời tham gia ${data['homeName']}';
    
    Get.snackbar(
      title,
      content,
      backgroundColor: status == 'accepted' ? Colors.green : Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }
}

/// 🎯 Xử lý device alert notification
void _handleDeviceAlertNotification(RemoteMessage message) {
  Get.dialog(
    _buildCustomAlertDialog(message),
    barrierDismissible: false,
  );
}

/// 🎯 Xử lý generic notification
void _handleGenericNotification(RemoteMessage message) {
  Get.snackbar(
    message.notification?.title ?? 'Thông báo',
    message.notification?.body ?? 'Bạn có thông báo mới',
    backgroundColor: Colors.blue,
    colorText: Colors.white,
    duration: const Duration(seconds: 3),
  );
}

/// 🎯 Xây dựng custom alert dialog cho device alerts
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

/// 🎯 Xử lý khi nhấn nút xem chi tiết - ĐÃ CẬP NHẬT CHO UNIFIED MODEL
void _handleAlertAction(RemoteMessage message) {
  // Tạo UnifiedNotificationModel từ message data
  final notification = UnifiedNotificationModel(
    id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    type: NotificationType.deviceAlert,
    message: message.notification?.body ?? 'Có sự kiện đáng ngờ',
    isRead: false,
    isProcessed: false,
    timestamp: int.tryParse(message.data['timestamp'] ?? '') ?? DateTime.now().millisecondsSinceEpoch,
    createdAt: DateTime.now(),
    deviceId: message.data['deviceId'],
    homeId: message.data['homeId'],
    roomId: message.data['roomId'],
    locationDevice: message.data['locationDevice'],
    deviceType: message.data['deviceType'] ?? 'Security',
    deviceName: message.data['deviceName'],
  );

  // Điều hướng đến màn hình chi tiết cảnh báo
  Get.to(() => NotificationDetailPage(notification: notification));
}

/// 🎯 Lịch chào hàng ngày
Future<void> _scheduleDailyGreetings() async {
  final now = DateTime.now();
  final greeting = _getDailyGreeting(now);
  
  await _createMorningSchedule(greeting.morning);
  await _createAfternoonSchedule(greeting.afternoon);
  await _createEveningSchedule(greeting.evening);
}

class DailyGreeting {
  final String morning;
  final String afternoon;
  final String evening;
  
  const DailyGreeting({
    required this.morning,
    required this.afternoon,
    required this.evening,
  });
}

DailyGreeting _getDailyGreeting(DateTime now) {
  return const DailyGreeting(
    morning: '🌅 Chúc bạn buổi sáng tràn đầy năng lượng!',
    afternoon: '☀️ Chúc bạn buổi chiều làm việc hiệu quả!',
    evening: '🌙 Chúc bạn buổi tối thư giãn và bình an!',
  );
}

Future<void> _createMorningSchedule(String message) async {
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
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

Future<void> _createAfternoonSchedule(String message) async {
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
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

Future<void> _createEveningSchedule(String message) async {
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
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
      themeMode: themeController.themeMode.value,
      debugShowCheckedModeBanner: false,
      home: FirebaseAuth.instance.currentUser != null ? HomePageContent() : const SlacePage(),
    );
  }
}