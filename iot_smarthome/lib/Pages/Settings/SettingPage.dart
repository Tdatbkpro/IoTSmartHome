import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:flutter_advanced_avatar/flutter_advanced_avatar.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Controllers/Auth.dart';
import 'package:iot_smarthome/Controllers/DeviceController.dart';
import 'package:iot_smarthome/Controllers/ThemeController.dart';
import 'package:iot_smarthome/Models/UserModel.dart';
import 'package:iot_smarthome/Pages/Settings/Widget/AboutApp.dart';
import 'package:iot_smarthome/Pages/Profile/Widget/ChangeUserInfo.dart';
import 'package:iot_smarthome/Pages/Settings/Widget/FeedBack.dart';
import 'package:iot_smarthome/Pages/Home/Widget/LoginDeviceManager.dart';
import 'package:iot_smarthome/Pages/Settings/Widget/SecurityPrivate.dart';
import 'package:kf_drawer/kf_drawer.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final authController = Get.put(AuthController());
  final deviceController = Get.put(DeviceController());
  final firebaseUser = FirebaseAuth.instance.currentUser;
  final themeController = Get.find<ThemeController>();

  late final RxBool _notificationsEnabled = false.obs ;
  late final RxBool _autoSyncEnabled = false.obs;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _notificationsEnabled.value = themeController.notificationSettings.pushNotifications ?? false;
    _autoSyncEnabled.value = themeController.isAutoSyncEnabled ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Cài đặt",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
          onPressed: () => KFDrawer.of(context)?.toggle(),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<User?>(
        stream: authController.getUserByIdStream(firebaseUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
          } else if (snapshot.hasError) {
            return Center(child: Text("Lỗi tải user", style: TextStyle(color: theme.colorScheme.error)));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text("Không có dữ liệu user", style: TextStyle(color: theme.colorScheme.onSurface)));
          }

          final user = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Profile Card
                _buildProfileCard(theme, user),
                const SizedBox(height: 24),

                // General Settings
                _buildSectionTitle("Cài đặt chung", theme),
                const SizedBox(height: 12),
                _buildGeneralSettings(theme),

                const SizedBox(height: 24),

                // Device & System
                _buildSectionTitle("Thiết bị & Hệ thống", theme),
                const SizedBox(height: 12),
                _buildDeviceSystemSettings(theme),

                const SizedBox(height: 24),

                // Support & About
                _buildSectionTitle("Hỗ trợ & Thông tin", theme),
                const SizedBox(height: 12),
                _buildSupportSettings(theme),

                const SizedBox(height: 32),

                // Logout Button
                _buildLogoutButton(theme),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme, User user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
          AdvancedAvatar(
            size: 70,
            name: user.name,
            animated: true,
            image: (user.profileImage != null && user.profileImage!.isNotEmpty)
                ? NetworkImage(user.profileImage!)
                : null,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.7),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Text(
              user.name!.isNotEmpty ? user.name![0].toUpperCase() : "?",
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? "No email",
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChangeUserInfo(user: user)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          "Chỉnh sửa hồ sơ",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
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

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGeneralSettings(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingTile(
            theme: theme,
            icon: Icons.dark_mode_rounded,
            title: "Chế độ tối",
            trailing: Switch(
              value: themeController.themeMode.value == ThemeMode.dark,
              onChanged: (value) {
                themeController.toggleTheme(value);
              },
              activeThumbColor: theme.colorScheme.primary,
            ),
          ),
          _buildDivider(theme),
          _buildSettingTile(
            theme: theme,
            icon: Icons.notifications_active_rounded,
            title: "Thông báo",
            subtitle: "Nhận thông báo từ thiết bị",
            trailing: Obx( () =>
              Switch(
                value: _notificationsEnabled.value,
                onChanged: (value) {
                  
                    _notificationsEnabled.value = value;
                    themeController.updateNotificationSettings(pushNotifications: _notificationsEnabled.value);
                  // TODO: Implement notification settings
                },
                activeThumbColor: theme.colorScheme.primary,
              ),
            ),
          ),
          _buildDivider(theme),
          _buildSettingTile(
            theme: theme,
            icon: Icons.sync_rounded,
            title: "Đồng bộ tự động",
            subtitle: "Tự động đồng bộ dữ liệu",
            trailing: Obx( () => 
              Switch(
                value: _autoSyncEnabled.value,
                onChanged: (value) {
                  
                    _autoSyncEnabled.value = value;
                    themeController.updateGeneralSettings(autoSync: _autoSyncEnabled.value);
                
                  // TODO: Implement auto sync
                },
                activeThumbColor: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSystemSettings(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingTile(
            theme: theme,
            icon: Icons.assistant_rounded,
            title: "Trợ lý giọng nói",
            subtitle: "Điều khiển bằng giọng nói",
            onTap: () {
              Get.toNamed("/voiceAssistant");
            },
          ),
          _buildDivider(theme),
          _buildSettingTile(
            theme: theme,
            icon: Icons.devices_rounded,
            title: "Quản lý thiết bị",
            subtitle: "Xem và quản lý tất cả thiết bị",
            onTap: () {
              Navigator.push(context,
              MaterialPageRoute(builder: (context) => LoginDeviceManagementPage()));
            },
          ),
          _buildDivider(theme),
          _buildSettingTile(
            theme: theme,
            icon: Icons.security_rounded,
            title: "Bảo mật",
            subtitle: "Cài đặt bảo mật và quyền riêng tư",
            onTap: () {
              Navigator.push(context,
              MaterialPageRoute(builder: (context) => SecurityPrivacyPage())
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSettings(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingTile(
            theme: theme,
            icon: Icons.help_center_rounded,
            title: "Trung tâm trợ giúp",
            onTap: () {
              // TODO: Navigate to help center
            },
          ),
          _buildDivider(theme),
          _buildSettingTile(
            theme: theme,
            icon: Icons.bug_report_rounded,
            title: "Báo lỗi & Góp ý",
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => FeedbackPage()));
            },
          ),
          _buildDivider(theme),
          _buildSettingTile(
            theme: theme,
            icon: Icons.info_rounded,
            title: "Về ứng dụng",
            subtitle: "Phiên bản 1.0.0",
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AboutAppPage()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
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
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            )
          : null,
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withOpacity(0.5)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _buildLogoutButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _showLogoutDialog(theme);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.error.withOpacity(0.1),
          foregroundColor: theme.colorScheme.error,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 20),
            SizedBox(width: 8),
            Text(
              "Đăng xuất",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            Text(
              "Xác nhận đăng xuất",
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          "Bạn có chắc chắn muốn đăng xuất khỏi tài khoản hiện tại?",
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Hủy",
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              authController.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text("Đăng xuất"),
          ),
        ],
      ),
    );
  }
}