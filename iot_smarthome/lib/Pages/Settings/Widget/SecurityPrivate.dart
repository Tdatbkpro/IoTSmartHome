import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Controllers/ThemeController.dart';
import 'package:iot_smarthome/Services/AutoLogoutService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityPrivacyPage extends StatefulWidget {
  const SecurityPrivacyPage({super.key});

  @override
  State<SecurityPrivacyPage> createState() => _SecurityPrivacyPageState();
}

class _SecurityPrivacyPageState extends State<SecurityPrivacyPage> {
  final RxBool _biometricEnabled = false.obs;
  final RxBool _autoLogout = true.obs;
  final RxBool _dataEncryption = true.obs;
  final RxBool _usageAnalytics = false.obs;
  final RxBool _remoteAccess = true.obs;
  final RxBool _cameraRecording = true.obs;
  final RxBool _deviceSharing = true.obs;
  final AutoLogoutService _autoLogoutService = Get.put(AutoLogoutService());

  final RxInt _autoLogoutTime = 15.obs; // minutes
  final RxString _securityLevel = 'Trung bình'.obs;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final themeController = Get.put(ThemeController());
    _biometricEnabled.value = themeController.securitySettings.biometricEnabled ?? false;
    _autoLogout.value = themeController.securitySettings.autoLogout ?? true;
    _dataEncryption.value = themeController.securitySettings.dataEncryption ?? true;
    _usageAnalytics.value = themeController.securitySettings.usageAnalytics ?? false;
    _remoteAccess.value = themeController.securitySettings.remoteAccess ?? true;
    _cameraRecording.value = themeController.securitySettings.cameraRecording ?? true;
    _deviceSharing.value = themeController.securitySettings.deviceSharing ?? true;
    _autoLogoutTime.value = themeController.securitySettings.autoLogoutTime ?? 15;
    _securityLevel.value = themeController.securitySettings.securityLevel ?? 'Trung bình';
  }

  Future<void> _saveSecuritySettings() async {
    final themeController = Get.put(ThemeController());
    themeController.updateSecuritySettings(
      biometricEnabled: _biometricEnabled.value,
      autoLogout: _autoLogout.value,
      usageAnalytics: _usageAnalytics.value,
      remoteAccess: _remoteAccess.value,
      cameraRecording: _cameraRecording.value,
      deviceSharing: _deviceSharing.value,
      autoLogoutTime: _autoLogoutTime.value,
      securityLevel: _securityLevel.value
    );
     _applySecuritySettings();
    Get.snackbar(
      "Thành công",
      "✅ Đã lưu cài đặt bảo mật!",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.primary,
      colorText: Colors.white,
    );
  }
  void _applySecuritySettings() {
    // Apply biometric setting
    if (_biometricEnabled.value) {
      //_enableBiometricAuthentication();
    }

    // Apply auto logout setting
    if (_autoLogout.value) {
      _autoLogoutService.resetTimer();
    } else {
      _autoLogoutService.stopAutoLogout();
    }

    // Apply data encryption
    if (_dataEncryption.value) {
      //_enableDataEncryption();
    }

    // Apply analytics setting
    if (_usageAnalytics.value) {
      //_enableUsageAnalytics();
    } else {
      //_disableUsageAnalytics();
    }
  }

  void _showAutoLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Thời gian tự động đăng xuất"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => Text(
                  "${_autoLogoutTime.value} phút",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                )),
            const SizedBox(height: 16),
            Obx(() => Slider(
                  value: _autoLogoutTime.value.toDouble(),
                  min: 1,
                  max: 60,
                  divisions: 59,
                  onChanged: (value) {
                    _autoLogoutTime.value = value.toInt();
                  },
                )),
            const SizedBox(height: 8),
            const Text("Thiết lập thời gian tự động đăng xuất khi không hoạt động"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveSecuritySettings();
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  void _showSecurityLevelDialog() {
    final levels = ['Thấp', 'Trung bình', 'Cao', 'Rất cao'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mức độ bảo mật"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: levels.map((level) {
            return ListTile(
              leading: Obx(() => Radio(
                    value: level,
                    groupValue: _securityLevel.value,
                    onChanged: (value) {
                      _securityLevel.value = value!;
                      _saveSecuritySettings();
                    },
                  )),
              title: Text(level),
              onTap: () {
                _securityLevel.value = level;
                Navigator.pop(context);
                _saveSecuritySettings();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showPermissionInfo(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đã hiểu"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title:  Text(
          "Bảo mật & Riêng tư",
          style: TextStyle(fontWeight: FontWeight.w600,
          color: colorScheme.onSurface
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeaderSection(theme),
            const SizedBox(height: 24),

            // Xác thực & Đăng nhập
            _buildSectionTitle("Xác thực & Đăng nhập", theme),
            const SizedBox(height: 12),
            _buildAuthSecuritySection(theme),

            const SizedBox(height: 24),

            // Quyền riêng tư & Dữ liệu
            _buildSectionTitle("Quyền riêng tư & Dữ liệu", theme),
            const SizedBox(height: 12),
            _buildPrivacyDataSection(theme),

            const SizedBox(height: 24),

            // Quyền truy cập thiết bị
            _buildSectionTitle("Quyền truy cập thiết bị", theme),
            const SizedBox(height: 12),
            _buildDeviceAccessSection(theme),

            const SizedBox(height: 24),

            // Mức độ bảo mật
            _buildSecurityLevelSection(theme),

            const SizedBox(height: 32),

            // Action Buttons
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.error.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.security_rounded,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            "Bảo vệ thiết bị & dữ liệu của bạn",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Quản lý cài đặt bảo mật và quyền riêng tư cho ngôi nhà thông minh",
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildAuthSecuritySection(ThemeData theme) {
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
      ),
      child: Column(
        children: [
          _buildSecuritySetting(
            theme,
            Icons.fingerprint_rounded,
            "Xác thực sinh trắc học",
            "Sử dụng vân tay/face ID để đăng nhập",
            _biometricEnabled,
            Icons.info_outline_rounded,
            () => _showPermissionInfo(
              "Xác thực sinh trắc học",
              "Cho phép sử dụng vân tay hoặc nhận diện khuôn mặt để đăng nhập nhanh chóng và an toàn.",
            ),
          ),
          _buildDivider(theme),
          _buildSecuritySettingWithAction(
            theme,
            Icons.timer_rounded,
            "Tự động đăng xuất",
            "Đăng xuất tự động khi không hoạt động",
            _autoLogout,
            "${_autoLogoutTime.value} phút",
            _showAutoLogoutDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyDataSection(ThemeData theme) {
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
      ),
      child: Column(
        children: [
          _buildSecuritySetting(
            theme,
            Icons.no_encryption_rounded,
            "Mã hóa dữ liệu",
            "Mã hóa dữ liệu nhạy cảm trên thiết bị",
            _dataEncryption,
            Icons.info_outline_rounded,
            () => _showPermissionInfo(
              "Mã hóa dữ liệu",
              "Tất cả dữ liệu nhạy cảm sẽ được mã hóa để bảo vệ thông tin cá nhân của bạn.",
            ),
          ),
          _buildDivider(theme),
          _buildSecuritySetting(
            theme,
            Icons.analytics_rounded,
            "Phân tích sử dụng",
            "Chia sẻ dữ liệu sử dụng để cải thiện ứng dụng",
            _usageAnalytics,
            Icons.info_outline_rounded,
            () => _showPermissionInfo(
              "Phân tích sử dụng",
              "Cho phép thu thập dữ liệu sử dụng ẩn danh để cải thiện trải nghiệm người dùng.",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceAccessSection(ThemeData theme) {
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
      ),
      child: Column(
        children: [
          _buildSecuritySetting(
            theme,
            Icons.settings_remote_outlined,
            "Truy cập từ xa",
            "Cho phép điều khiển thiết bị từ xa",
            _remoteAccess,
            Icons.info_outline_rounded,
            () => _showPermissionInfo(
              "Truy cập từ xa",
              "Cho phép điều khiển các thiết bị IoT khi không ở trong mạng nội bộ.",
            ),
          ),
          _buildDivider(theme),
          _buildSecuritySetting(
            theme,
            Icons.camera_indoor_rounded,
            "Ghi hình camera",
            "Cho phép camera ghi hình và lưu trữ",
            _cameraRecording,
            Icons.info_outline_rounded,
            () => _showPermissionInfo(
              "Ghi hình camera",
              "Camera an ninh sẽ ghi hình và lưu trữ trong cloud hoặc thiết bị cục bộ.",
            ),
          ),
          _buildDivider(theme),
          _buildSecuritySetting(
            theme,
            Icons.share_rounded,
            "Chia sẻ thiết bị",
            "Cho phép chia sẻ quyền điều khiển với thành viên gia đình",
            _deviceSharing,
            Icons.info_outline_rounded,
            () => _showPermissionInfo(
              "Chia sẻ thiết bị",
              "Cho phép thêm thành viên gia đình và cấp quyền điều khiển thiết bị cụ thể.",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityLevelSection(ThemeData theme) {
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
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_rounded, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Mức độ bảo mật tổng thể",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() => ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getSecurityLevelColor(),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.security_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    _securityLevel.value,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    _getSecurityLevelDescription(),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: _showSecurityLevelDialog,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySetting(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
    RxBool value,
    IconData? infoIcon,
    VoidCallback? onInfoTap,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          fontSize: 12,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (infoIcon != null)
            IconButton(
              icon: Icon(infoIcon, size: 18, color: theme.colorScheme.primary.withOpacity(0.6)),
              onPressed: onInfoTap,
            ),
          Obx(() => Switch(
                value: value.value,
                onChanged: (newValue) {
                  value.value = newValue;
                  _saveSecuritySettings();
                },
                activeThumbColor: theme.colorScheme.primary,
              )),
        ],
      ),
    );
  }

  Widget _buildSecuritySettingWithAction(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
    RxBool value,
    String actionText,
    VoidCallback onActionTap,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          fontSize: 12,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            actionText,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Obx(() => Switch(
                value: value.value,
                onChanged: (newValue) {
                  value.value = newValue;
                  _saveSecuritySettings();
                },
                activeThumbColor: theme.colorScheme.primary,
              )),
        ],
      ),
      onTap: onActionTap,
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 72, right: 16),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: theme.dividerColor.withOpacity(0.3),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              // Reset to default settings
              _loadSecuritySettings();
              Get.snackbar(
                "Thành công",
                "✅ Đã đặt lại cài đặt mặc định!",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: theme.colorScheme.outline),
            ),
            child: Text(
              "Đặt lại mặc định",
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveSecuritySettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Lưu cài đặt",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Color _getSecurityLevelColor() {
    switch (_securityLevel.value) {
      case 'Thấp':
        return Colors.orange;
      case 'Trung bình':
        return Colors.blue;
      case 'Cao':
        return Colors.green;
      case 'Rất cao':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getSecurityLevelDescription() {
    switch (_securityLevel.value) {
      case 'Thấp':
        return "Cân bằng giữa bảo mật và tiện lợi";
      case 'Trung bình':
        return "Bảo mật cơ bản cho hầu hết người dùng";
      case 'Cao':
        return "Bảo mật nâng cao với hạn chế quyền truy cập";
      case 'Rất cao':
        return "Bảo mật tối đa, có thể ảnh hưởng đến trải nghiệm";
      default:
        return "Mức độ bảo mật được đề xuất";
    }
  }
}