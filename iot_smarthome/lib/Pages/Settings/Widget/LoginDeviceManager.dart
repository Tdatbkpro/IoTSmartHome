import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Controllers/DeviceController.dart';
import 'package:iot_smarthome/Controllers/LoginDeviceController.dart';
import 'package:intl/intl.dart';
import 'package:iot_smarthome/Models/LoginDeviceModel.dart';

class LoginDeviceManagementPage extends StatefulWidget {
  const LoginDeviceManagementPage({super.key});

  @override
  State<LoginDeviceManagementPage> createState() => _LoginDeviceManagementPageState();
}

class _LoginDeviceManagementPageState extends State<LoginDeviceManagementPage> {
  final LoginDeviceController _deviceController = Get.put(LoginDeviceController());

  @override
  void initState() {
    super.initState();
    _deviceController.loadUserDevices();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Quản lý thiết bị",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colorScheme.primary),
            onPressed: () => _deviceController.loadUserDevices(),
          ),
        ],
      ),
      body: Obx(() {
        final devices = _deviceController.userDevices;
        final currentDeviceId = _deviceController.currentDeviceId;

        return Column(
          children: [
            // Header Stats
            _buildHeaderStats(theme, devices.length),
            
            // Devices List
            Expanded(
              child: devices.isEmpty
                  ? _buildEmptyState(theme)
                  : _buildDevicesList(theme, devices, currentDeviceId.value),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHeaderStats(ThemeData theme, int deviceCount) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.devices_rounded,
              color: theme.colorScheme.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Thiết bị đã kết nối",
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$deviceCount thiết bị",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "Đang hoạt động",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.devices_other_rounded,
              size: 50,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Chưa có thiết bị nào",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Các thiết bị đăng nhập sẽ xuất hiện tại đây",
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _deviceController.loadUserDevices(),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Tải lại danh sách"),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesList(ThemeData theme, List<LoginDeviceModel> devices, String currentDeviceId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Section Title
          Row(
            children: [
              Text(
                "Thiết bị đã đăng nhập",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                "${devices.length} thiết bị",
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Devices List
          Expanded(
            child: ListView.separated(
              itemCount: devices.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final device = devices[index];
                final isCurrentDevice = device.deviceId == currentDeviceId;
                
                return _buildDeviceCard(theme, device, isCurrentDevice);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(ThemeData theme, LoginDeviceModel device, bool isCurrentDevice) {
    final timeAgo = _getTimeAgo(device.lastActive);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isCurrentDevice 
            ? Border.all(color: theme.colorScheme.primary.withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Device Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isCurrentDevice 
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : theme.colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getDeviceIcon(device.deviceModel),
                    color: isCurrentDevice 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Device Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            device.deviceName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (isCurrentDevice) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Thiết bị này",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.deviceModel,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Hoạt động $timeAgo",
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Actions
                if (!isCurrentDevice)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    onSelected: (value) {
                      if (value == 'logout') {
                        _showLogoutConfirmation(device);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            Text("Đăng xuất thiết bị"),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          // Online Indicator
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _isDeviceActive(device.lastActive) 
                    ? Colors.green
                    : Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(LoginDeviceModel device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text("Xác nhận đăng xuất"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bạn có chắc muốn đăng xuất thiết bị này?",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.deviceName,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    device.deviceModel,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deviceController.signOutDevice(device.deviceId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Đăng xuất"),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String model) {
    if (model.toLowerCase().contains('phone')) return Icons.phone_android_rounded;
    if (model.toLowerCase().contains('tablet')) return Icons.tablet_android_rounded;
    if (model.toLowerCase().contains('samsung')) return Icons.android_rounded;
    if (model.toLowerCase().contains('iphone')) return Icons.phone_iphone_rounded;
    return Icons.devices_other_rounded;
  }

  String _getTimeAgo(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) return 'vài giây trước';
      if (difference.inMinutes < 60) return '${difference.inMinutes} phút trước';
      if (difference.inHours < 24) return '${difference.inHours} giờ trước';
      if (difference.inDays < 7) return '${difference.inDays} ngày trước';
      
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return 'Không xác định';
    }
  }

  bool _isDeviceActive(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      return now.difference(dateTime).inMinutes < 10; // Active within 10 minutes
    } catch (e) {
      return false;
    }
  }
}