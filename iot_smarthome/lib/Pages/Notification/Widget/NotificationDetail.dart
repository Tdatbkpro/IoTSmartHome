import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:iot_smarthome/Controllers/UnifiedNotificationController.dart';
import 'package:iot_smarthome/Models/UnifiedNotificationModel.dart';


class NotificationDetailPage extends StatelessWidget {
  final UnifiedNotificationModel notification;
  const NotificationDetailPage({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final isUrgent = notification.isDeviceAlert && 
                    (notification.deviceType?.toLowerCase().contains('security') == true ||
                     notification.message.toLowerCase().contains('cảnh báo') ||
                     notification.message.toLowerCase().contains('alert'));
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: _getAppBarColor(isUrgent),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
        actions: [
          if (notification.isDeviceAlert)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: _shareAlertDetails,
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎯 CARD THÔNG TIN CHÍNH
            _buildMainAlertCard(context, isUrgent),
            
            const SizedBox(height: 20),
            
            // 🎯 THÔNG TIN CHI TIẾT
            _buildDetailInfoCard(context),
            
            const SizedBox(height: 20),
            
            // 🎯 HÌNH ẢNH MÔ PHỎNG (chỉ hiển thị với device alerts)
            if (notification.isDeviceAlert) ...[
              _buildCameraPreview(),
              const SizedBox(height: 20),
            ],
            
            // 🎯 HÀNH ĐỘNG
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  /// 🎯 Lấy tiêu đề AppBar dựa trên loại notification
  String _getAppBarTitle() {
    if (notification.isDeviceAlert) {
      return 'Chi Tiết Cảnh Báo';
    } else if (notification.isInvitation) {
      return 'Chi Tiết Lời Mời';
    } else if (notification.isInvitationResponse) {
      return 'Phản Hồi Lời Mời';
    } else {
      return 'Chi Tiết Thông Báo';
    }
  }

  /// 🎯 Lấy màu AppBar dựa trên loại notification
  Color _getAppBarColor(bool isUrgent) {
    if (notification.isDeviceAlert) {
      return isUrgent ? const Color(0xFFE74C3C) : const Color(0xFF3498DB);
    } else if (notification.isInvitation) {
      return const Color(0xFF9B59B6);
    } else if (notification.isInvitationResponse) {
      return notification.status == 'accepted' 
          ? const Color(0xFF27AE60) 
          : const Color(0xFFE74C3C);
    } else {
      return const Color(0xFF3498DB);
    }
  }

  /// 🎯 Card thông tin chính
  Widget _buildMainAlertCard(BuildContext context, bool isUrgent) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getCardGradientColors(isUrgent),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getCardShadowColor(isUrgent).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Icon
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getMainIcon(),
              color: Colors.white,
              size: 35,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tiêu đề
          Text(
            _getMainTitle(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Nội dung
          Text(
            notification.message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Trạng thái
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusBadge(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Lấy màu gradient cho card
  List<Color> _getCardGradientColors(bool isUrgent) {
    if (notification.isDeviceAlert) {
      return isUrgent 
        ? [const Color(0xFFE74C3C), const Color(0xFFC0392B)]
        : [const Color(0xFF3498DB), const Color(0xFF2980B9)];
    } else if (notification.isInvitation) {
      return [const Color(0xFF9B59B6), const Color(0xFF8E44AD)];
    } else if (notification.isInvitationResponse) {
      return notification.status == 'accepted'
        ? [const Color(0xFF27AE60), const Color(0xFF229954)]
        : [const Color(0xFFE74C3C), const Color(0xFFC0392B)];
    } else {
      return [const Color(0xFF3498DB), const Color(0xFF2980B9)];
    }
  }

  /// 🎯 Lấy màu shadow cho card
  Color _getCardShadowColor(bool isUrgent) {
    if (notification.isDeviceAlert) {
      return isUrgent ? const Color(0xFFE74C3C) : const Color(0xFF3498DB);
    } else if (notification.isInvitation) {
      return const Color(0xFF9B59B6);
    } else if (notification.isInvitationResponse) {
      return notification.status == 'accepted' 
          ? const Color(0xFF27AE60) 
          : const Color(0xFFE74C3C);
    } else {
      return const Color(0xFF3498DB);
    }
  }

  /// 🎯 Lấy icon chính
  IconData _getMainIcon() {
    if (notification.isDeviceAlert) {
      final isUrgent = notification.deviceType?.toLowerCase().contains('security') == true;
      return isUrgent ? Icons.security_rounded : Icons.device_thermostat_rounded;
    } else if (notification.isInvitation) {
      return Icons.mail_outline_rounded;
    } else if (notification.isInvitationResponse) {
      return notification.status == 'accepted' 
          ? Icons.check_circle_rounded 
          : Icons.cancel_rounded;
    } else {
      return Icons.notifications_active_rounded;
    }
  }

  /// 🎯 Lấy tiêu đề chính
  String _getMainTitle() {
    if (notification.isDeviceAlert) {
      return notification.deviceName ?? 'Thiết bị';
    } else if (notification.isInvitation) {
      return 'Lời Mời Tham Gia';
    } else if (notification.isInvitationResponse) {
      return notification.status == 'accepted' 
          ? 'Lời Mời Được Chấp Nhận' 
          : 'Lời Mời Bị Từ Chối';
    } else {
      return 'Thông Báo';
    }
  }

  /// 🎯 Lấy badge trạng thái
  String _getStatusBadge() {
    if (notification.isDeviceAlert) {
      final isUrgent = notification.deviceType?.toLowerCase().contains('security') == true;
      return isUrgent ? '🚨 CẢNH BÁO KHẨN CẤP' : '💬 THÔNG BÁO THIẾT BỊ';
    } else if (notification.isInvitation) {
      return '📨 LỜI MỜI';
    } else if (notification.isInvitationResponse) {
      return notification.status == 'accepted' ? '✅ ĐÃ CHẤP NHẬN' : '❌ ĐÃ TỪ CHỐI';
    } else {
      return '💬 THÔNG BÁO';
    }
  }

  /// 🎯 Card thông tin chi tiết
  Widget _buildDetailInfoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề section
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Thông Tin Chi Tiết',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Dòng thông tin thời gian
          _buildDetailRow(
            Icons.access_time_rounded,
            'Thời gian nhận',
            DateFormat('HH:mm - dd/MM/yyyy').format(notification.createdAt ?? DateTime.now()),
          ),
          
          const SizedBox(height: 12),
          
          // Dòng thông tin trạng thái
          _buildDetailRow(
            Icons.verified_rounded,
            'Trạng thái',
            notification.isProcessed ? 'Đã xử lý' : 'Chưa xử lý',
          ),
          
          if (notification.isDeviceAlert) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.location_pin,
              'Khu vực',
              notification.locationDevice ?? 'Không xác định',
            ),
            
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.device_hub_rounded,
              'Loại thiết bị',
              notification.deviceType ?? 'Không xác định',
            ),
            
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.priority_high_rounded,
              'Mức độ ưu tiên',
              _getPriorityLevel(),
              valueColor: _getPriorityColor(),
            ),
          ] else if (notification.isInvitation || notification.isInvitationResponse) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.person_rounded,
              'Người gửi',
              notification.fromUserName ?? 'Không xác định',
            ),
            
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.email_rounded,
              'Email',
              notification.fromUserEmail ?? 'Không xác định',
            ),
            
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.home_rounded,
              'Ngôi nhà',
              notification.homeName ?? 'Không xác định',
            ),
            
            if (notification.isInvitationResponse) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.star_rate_rounded,
                'Kết quả',
                notification.status == 'accepted' ? 'Đã chấp nhận' : 'Đã từ chối',
                valueColor: notification.status == 'accepted' 
                    ? const Color(0xFF27AE60) 
                    : const Color(0xFFE74C3C),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// 🎯 Lấy mức độ ưu tiên
  String _getPriorityLevel() {
    if (notification.isDeviceAlert) {
      final isSecurity = notification.deviceType?.toLowerCase().contains('security') == true;
      return isSecurity ? 'Cao' : 'Trung bình';
    } else if (notification.isInvitation) {
      return 'Trung bình';
    } else {
      return 'Thấp';
    }
  }

  /// 🎯 Lấy màu ưu tiên
  Color _getPriorityColor() {
    final level = _getPriorityLevel();
    switch (level) {
      case 'Cao':
        return const Color(0xFFE74C3C);
      case 'Trung bình':
        return const Color(0xFFF39C12);
      case 'Thấp':
        return const Color(0xFF27AE60);
      default:
        return const Color(0xFF3498DB);
    }
  }

  /// 🎯 Dòng thông tin chi tiết
  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.grey[800],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  /// 🎯 Hình ảnh mô phỏng camera preview (chỉ cho device alerts)
  Widget _buildCameraPreview() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header hình ảnh
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.photo_camera_rounded,
                  color: Colors.grey[700],
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Hình ảnh phát hiện',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Placeholder hình ảnh
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_rounded,
                  color: Colors.grey[400],
                  size: 50,
                ),
                const SizedBox(height: 8),
                Text(
                  'Không có hình ảnh',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.snackbar(
                      'Tính năng đang phát triển',
                      'Xem video trực tiếp sẽ có trong phiên bản tới',
                      backgroundColor: Colors.blue[50],
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Xem Video Trực Tiếp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3498DB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Các nút hành động
  Widget _buildActionButtons() {
    return Row(
      children: [
        if (notification.isDeviceAlert && !notification.isProcessed) ...[
          // Nút đánh dấu đã xử lý (chỉ cho device alerts chưa xử lý)
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextButton.icon(
                onPressed: _markAsResolved,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text(
                  'Đánh dấu đã xử lý',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF27AE60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        
        // Nút xem thêm
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getActionButtonGradient(),
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _getActionButtonShadowColor().withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextButton.icon(
              onPressed: _viewMoreDetails,
              icon: Icon(_getActionButtonIcon(), size: 18),
              label: Text(
                _getActionButtonText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 🎯 Lấy gradient cho nút hành động
  List<Color> _getActionButtonGradient() {
    if (notification.isDeviceAlert) {
      return [const Color(0xFF3498DB), const Color(0xFF2980B9)];
    } else if (notification.isInvitation) {
      return [const Color(0xFF9B59B6), const Color(0xFF8E44AD)];
    } else {
      return [const Color(0xFF27AE60), const Color(0xFF229954)];
    }
  }

  /// 🎯 Lấy màu shadow cho nút hành động
  Color _getActionButtonShadowColor() {
    if (notification.isDeviceAlert) {
      return const Color(0xFF3498DB);
    } else if (notification.isInvitation) {
      return const Color(0xFF9B59B6);
    } else {
      return const Color(0xFF27AE60);
    }
  }

  /// 🎯 Lấy icon cho nút hành động
  IconData _getActionButtonIcon() {
    if (notification.isDeviceAlert) {
      return Icons.remove_red_eye_rounded;
    } else if (notification.isInvitation) {
      return Icons.group_add_rounded;
    } else {
      return Icons.history_rounded;
    }
  }

  /// 🎯 Lấy text cho nút hành động
  String _getActionButtonText() {
    if (notification.isDeviceAlert) {
      return 'Xem Thêm';
    } else if (notification.isInvitation) {
      return 'Quản Lý';
    } else {
      return 'Lịch Sử';
    }
  }

  /// 🎯 Hàm chia sẻ thông tin cảnh báo
  void _shareAlertDetails() {
    final shareContent = '''
🚨 Thông Báo An Ninh

${notification.deviceName ?? 'Thiết bị'}
${notification.message}

⏰ Thời gian: ${DateFormat('HH:mm dd/MM/yyyy').format(notification.createdAt ?? DateTime.now())}
📍 Khu vực: ${notification.locationDevice ?? 'Không xác định'}

Được gửi từ ứng dụng An Ninh Thông Minh
    ''';
    
    Get.snackbar(
      'Chia sẻ thông tin',
      'Tính năng chia sẻ đang được phát triển',
      backgroundColor: Colors.blue[50],
      snackPosition: SnackPosition.BOTTOM,
    );
    
    print('Nội dung chia sẻ: $shareContent');
  }

  /// 🎯 Đánh dấu cảnh báo đã xử lý
  void _markAsResolved() {
    final notificationController = Get.put(UnifiedNotificationController());
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF27AE60), size: 50),
            SizedBox(height: 10),
            Text(
              'Xác Nhận Đã Xử Lý',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đánh dấu cảnh báo này đã được xử lý?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              await notificationController.markAsProcessed(notification.id);
              Get.back(); // Quay lại màn hình trước
              Get.snackbar(
                'Thành công',
                'Đã đánh dấu cảnh báo là đã xử lý',
                backgroundColor: Colors.green[50],
                colorText: Colors.green,
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
            ),
            child: const Text(
              'Xác Nhận',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Xem thêm chi tiết
  void _viewMoreDetails() {
    String title = '';
    String content = '';

    if (notification.isDeviceAlert) {
      title = 'Lịch Sử Cảnh Báo';
      content = 'Tính năng xem lịch sử chi tiết và phân tích cảnh báo sẽ có trong phiên bản tới.';
    } else if (notification.isInvitation) {
      title = 'Quản Lý Lời Mời';
      content = 'Tính năng quản lý và theo dõi lời mời sẽ có trong phiên bản tới.';
    } else {
      title = 'Lịch Sử Phản Hồi';
      content = 'Tính năng xem lịch sử phản hồi lời mời sẽ có trong phiên bản tới.';
    }

    Get.to(() => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            content,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ),
    ));
  }
}