import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:iot_smarthome/Models/NotificationModel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Controllers/NotificationController.dart';
import 'package:iot_smarthome/Pages/Home/Dialog.dart';
import 'package:kf_drawer/kf_drawer.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final notificationController = Get.put(NotificationController());
  
  // Hàm lấy icon và màu sắc theo loại thông báo
  (IconData, Color, Color, Color) _getNotificationStyle(String type, bool isDark) {
    final darkMode = isDark;
    
    switch (type.toLowerCase()) {
      case 'warning':
        return (
          Icons.warning_amber_rounded,
          darkMode ? Color(0xFFFBBF24) : Color(0xFFD97706),
          darkMode ? Color(0xFF451A03) : Color(0xFFFEF3C7),
          darkMode ? Color(0xFFF59E0B).withOpacity(0.2) : Color(0xFFFEF3C7)
        );
      case 'alert':
        return (
          Icons.security,
          darkMode ? Color(0xFFEF4444) : Color(0xFFDC2626),
          darkMode ? Color(0xFF450A0A) : Color(0xFFFEE2E2),
          darkMode ? Color(0xFFEF4444).withOpacity(0.2) : Color(0xFFFEE2E2)
        );
      case 'info':
        return (
          Icons.info,
          darkMode ? Color(0xFF60A5FA) : Color(0xFF2563EB),
          darkMode ? Color(0xFF172554) : Color(0xFFDBEAFE),
          darkMode ? Color(0xFF3B82F6).withOpacity(0.2) : Color(0xFFDBEAFE)
        );
      case 'success':
        return (
          Icons.check_circle,
          darkMode ? Color(0xFF34D399) : Color(0xFF059669),
          darkMode ? Color(0xFF052E16) : Color(0xFFD1FAE5),
          darkMode ? Color(0xFF10B981).withOpacity(0.2) : Color(0xFFD1FAE5)
        );
      case 'error':
        return (
          Icons.error,
          darkMode ? Color(0xFFF87171) : Color(0xFFDC2626),
          darkMode ? Color(0xFF450A0A) : Color(0xFFFEE2E2),
          darkMode ? Color(0xFFDC2626).withOpacity(0.2) : Color(0xFFFEE2E2)
        );
      case 'device':
        return (
          DialogUtils.getDeviceIcon(type),
          darkMode ? Color(0xFFA78BFA) : Color(0xFF7C3AED),
          darkMode ? Color(0xFF2E1065) : Color(0xFFEDE9FE),
          darkMode ? Color(0xFF8B5CF6).withOpacity(0.2) : Color(0xFFEDE9FE)
        );
      case 'security':
        return (
          Icons.camera_indoor,
          darkMode ? Color(0xFF818CF8) : Color(0xFF4F46E5),
          darkMode ? Color(0xFF1E1B4B) : Color(0xFFE0E7FF),
          darkMode ? Color(0xFF6366F1).withOpacity(0.2) : Color(0xFFE0E7FF)
        );
      default:
        return (
          Icons.notifications,
          darkMode ? Color(0xFF9CA3AF) : Color(0xFF6B7280),
          darkMode ? Color(0xFF1F2937) : Color(0xFFF3F4F6),
          darkMode ? Color(0xFF6B7280).withOpacity(0.2) : Color(0xFFF3F4F6)
        );
    }
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  bool get _isDarkMode {
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0F172A) : Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Thông Báo",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: isDark ? Colors.white : Color(0xFF0F172A),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.menu, color: isDark ? Colors.white : Color(0xFF0F172A)),
          onPressed: () => KFDrawer.of(context)?.toggle(),
        ),
        backgroundColor: isDark ? Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        centerTitle: false,
        shadowColor: isDark ? Colors.transparent : Colors.black12,
        surfaceTintColor: Colors.transparent,
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notificationController.getNotificationStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(isDark);
          } else if (snapshot.hasError) {
            return _buildErrorState(isDark);
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(isDark);
          }

          final notifications = snapshot.data!;
          return _buildNotificationList(notifications, isDark);
        },
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? Color(0xFF60A5FA) : Color(0xFF3B82F6)
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Đang tải thông báo...",
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1E293B) : Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 50,
              color: isDark ? Colors.red.shade400 : Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Không thể tải thông báo",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Vui lòng kiểm tra kết nối internet",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Retry logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Color(0xFF3B82F6) : Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text("Thử lại"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1E293B) : Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 60,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Không có thông báo",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tất cả thông báo hệ thống sẽ hiển thị tại đây",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationModel> notifications, bool isDark) {
    final unreadCount = notifications.where((n) => !n.isRead).length;
    
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: isDark ? null : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Thông Báo Hệ Thống",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${notifications.length} thông báo",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark 
                        ? [Color(0xFFEF4444), Color(0xFFDC2626)]
                        : [Color(0xFFDC2626), Color(0xFFB91C1C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(isDark ? 0.3 : 0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        "$unreadCount chưa đọc",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // List
        Expanded(
          child: ListView.builder(
            itemCount: notifications.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(notification, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(NotificationModel notification, bool isDark) {
    final (icon, color, bgColor, glowColor) = _getNotificationStyle(notification.type, isDark);
    final timeText = _formatTime(notification.timestamp);
    
    return Builder(
      builder: (BuildContext innerContext) {
        return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Slidable(
          key: ValueKey(notification.id),
          endActionPane: ActionPane(
            motion: const StretchMotion(),
            children: [
              SizedBox(width: 10,),
              SlidableAction(
                onPressed: (context) {
                  if (!notification.isRead) {
                    _markAsRead(notification, innerContext);
                  }
                   },
                backgroundColor: isDark ? Color(0xFF059669) : Color(0xFF10B981),
                icon: Icons.mark_email_read,
                label: notification.isRead ? 'Đã đọc' : 'Đánh dấu đã đọc',
                borderRadius: BorderRadius.circular(16),
                spacing: 8,
                foregroundColor: Colors.white,
              ),
              SizedBox(width: 10,),
              SlidableAction(
                onPressed: (innerContext) => _deleteNotification( notification, innerContext),
                backgroundColor: isDark ? Color(0xFFDC2626) : Color(0xFFEF4444),
                icon: Icons.delete_rounded,
                label: 'Xóa',
                borderRadius: BorderRadius.circular(16),
                spacing: 8,
                foregroundColor: Colors.white,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark 
                ? (notification.isRead ? Color(0xFF1E293B) : Color(0xFF1E3A8A))
                : (notification.isRead ? Colors.white : Color(0xFFE0F2FE)),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                if (!notification.isRead)
                  BoxShadow(
                    color: glowColor,
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                BoxShadow(
                  color: isDark 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isDark
                  ? (notification.isRead ? Colors.transparent : Color(0xFF3B82F6).withOpacity(0.3))
                  : (notification.isRead ? Colors.grey.shade200 : Color(0xFF0EA5E9).withOpacity(0.3)),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Background pattern
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Opacity(
                    opacity: isDark ? 0.05 : 0.03,
                    child: Icon(icon, size: 80, color: color),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon với background glow effect
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(isDark ? 0.3 : 0.2),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: color, size: 26),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Nội dung
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.message,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                                color: isDark ? Colors.white : Color(0xFF0F172A),
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Thông tin device và thời gian
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.black.withOpacity(0.4) : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.device_hub, size: 14, 
                                           color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                      const SizedBox(width: 6),
                                      Text(
                                        notification.deviceName.length > 10 
                                          ? '${notification.deviceName.substring(0, 10)}...'
                                          : notification.deviceName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.black.withOpacity(0.4) : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.access_time, size: 14, 
                                           color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                      const SizedBox(width: 6),
                                      Text(
                                        timeText,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Indicator chưa đọc
                      if (!notification.isRead)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isDark ? Color(0xFFEF4444) : Color(0xFFDC2626),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isDark ? Color(0xFFEF4444) : Color(0xFFDC2626)).withOpacity(0.8),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      } 
      
    );
  }

  void _markAsRead(NotificationModel notification, BuildContext context) async {
    await notificationController.markAsRead(notification.id);
    if (!context.mounted) return; // ✅ kiểm tra context còn hợp lệ
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã đánh dấu đã đọc'),
        backgroundColor: _isDarkMode ? Color(0xFF059669) : Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 2),
      ),
    );
  }

 void _deleteNotification(NotificationModel notification, BuildContext context) async {
  final controller = notificationController;
  
  // Lưu lại context trước khi thực hiện async operations
  final currentContext = context;
  final messengerState = ScaffoldMessenger.of(currentContext);
  
  // Lưu thông báo trước khi xóa để có thể hoàn tác
  final deletedNotification = notification;
  
  // Xóa ngay lập thứct
  await controller.deleteNotification(notification.id);
  
  // Hiển thị snackbar với tùy chọn hoàn tác
  final snackBar = SnackBar(
    content: Text('Đã xóa thông báo'),
    backgroundColor: _isDarkMode ? Color(0xFFDC2626) : Color(0xFFEF4444),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    duration: Duration(seconds: 4),
    action: SnackBarAction(
      label: 'Hoàn tác',
      textColor: Colors.white,
      onPressed: () async {
        // Khôi phục thông báo
        await controller.restoreNotification(deletedNotification.id,deletedNotification);
      },
    ),
  );
  
  // Sử dụng messengerState đã lưu trước đó
  messengerState.showSnackBar(snackBar);
}

}