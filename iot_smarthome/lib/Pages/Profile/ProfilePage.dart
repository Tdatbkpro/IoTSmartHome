import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Config/Texts.dart';
import 'package:iot_smarthome/Controllers/Auth.dart';
import 'package:iot_smarthome/Controllers/DeviceController.dart';
import 'package:iot_smarthome/Models/HomeModel.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:iot_smarthome/Models/RoomModel.dart';
import 'package:iot_smarthome/Models/UserModel.dart';
import 'package:iot_smarthome/Pages/Home/Widget/HomeDetail.dart';
import 'package:iot_smarthome/Pages/Profile/Widget/ChangeUserInfo.dart';
import 'package:kf_drawer/kf_drawer.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  final authController = Get.put(AuthController());
  final deviceController = Get.put(DeviceController());
  final firebaseUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Hồ sơ cá nhân",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: theme.appBarTheme.titleTextStyle?.color ?? Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu, 
            size: 24, 
            color: theme.appBarTheme.iconTheme?.color ?? Colors.white
          ),
          onPressed: () => KFDrawer.of(context)?.toggle(),
        ),
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.primaryColor,
      ),
      body: Obx(() {
        final homes = deviceController.homes;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              // Header với thông tin user
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? [
                            theme.primaryColor,
                            theme.primaryColor.withOpacity(0.7),
                          ]
                        : [
                            theme.primaryColor,
                            theme.primaryColor.withOpacity(0.8),
                          ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: Colors.white,
                            child: FutureBuilder<User?>(
                              future: authController.getUserById(FirebaseAuth.instance.currentUser!.uid),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return CircularProgressIndicator(
                                    color: theme.primaryColor,
                                  );
                                } else if (snapshot.hasError) {
                                  return Icon(Icons.error, color: theme.colorScheme.error);
                                } else if (!snapshot.hasData || snapshot.data == null) {
                                  return CircleAvatar(
                                    radius: 40,
                                    backgroundImage: const AssetImage("assets/icons/logo.png"),
                                    backgroundColor: theme.cardColor,
                                  );
                                } else {
                                  final user = snapshot.data!;
                                  return CircleAvatar(
                                    radius: 40,
                                    backgroundImage: user.profileImage != null && user.profileImage!.isNotEmpty
                                        ? NetworkImage(user.profileImage!)
                                        : const AssetImage("assets/icons/logo.png") as ImageProvider,
                                    backgroundColor: theme.cardColor,
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.verified,
                              color: theme.primaryColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<User?>(
                      stream: firebaseUser != null
                          ? authController.getUserByIdStream(firebaseUser!.uid)
                          : const Stream.empty(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator.adaptive(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          );
                        }

                        if (snapshot.hasError) {
                          return Text(
                            "Lỗi tải thông tin",
                            style: AppTextStyles.title.copyWith(color: Colors.white),
                          );
                        }

                        final user = snapshot.data;
                        final displayName = user?.name ?? 
                            firebaseUser?.displayName ?? 
                            firebaseUser?.email ?? 
                            "Khách";

                        return Column(
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              firebaseUser?.email ?? "Chưa có email",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatItem(
                          context,
                          "Tổng nhà",
                          homes.length.toString(),
                          Icons.home_work_outlined,
                        ),
                        const SizedBox(width: 32),
                        _buildStatItem(
                          context,
                          "Tổng phòng",
                          _calculateTotalRooms(homes).toString(),
                          Icons.room_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section: Homes đang điều khiển
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.home_outlined,
                          color: theme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "NHÀ ĐANG ĐIỀU KHIỂN",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    homes.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: homes.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final home = homes[index];
                              return _buildHomeCard(context, home);
                            },
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildActionButton(
                      context,
                      "Cài đặt tài khoản",
                      Icons.settings_outlined,
                      Colors.blue,
                      () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (context) => StreamBuilder(
                              stream: authController.getUserByIdStream(FirebaseAuth.instance.currentUser!.uid), 
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Scaffold(
                                    backgroundColor: theme.scaffoldBackgroundColor,
                                    body: Center(
                                      child: CircularProgressIndicator(color: theme.primaryColor),
                                    ),
                                  );
                                }
                                
                                if (snapshot.hasError || !snapshot.hasData) {
                                  return Scaffold(
                                    backgroundColor: theme.scaffoldBackgroundColor,
                                    appBar: AppBar(
                                      title: const Text('Lỗi'),
                                      leading: IconButton(
                                        icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                      backgroundColor: theme.appBarTheme.backgroundColor,
                                    ),
                                    body: Center(
                                      child: Text(
                                        'Không thể tải thông tin người dùng',
                                        style: TextStyle(color: theme.colorScheme.onSurface),
                                      ),
                                    ),
                                  );
                                }
                                
                                return ChangeUserInfo(user: snapshot.data!);
                              }
                            )
                          )
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      context,
                      "Trung tâm hỗ trợ",
                      Icons.help_outline,
                      Colors.orange,
                      () {
                        // Navigate to help center
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      context,
                      "Đăng xuất",
                      Icons.logout_outlined,
                      Colors.red,
                      () {
                        _showLogoutDialog(context);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatItem(BuildContext context, String title, String value, IconData icon) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  int _calculateTotalDevices(List<RoomModel> rooms) {
    return rooms.fold(0, (sum, room) => sum + room.devices.length);
  }

  Widget _buildHomeCard(BuildContext context, HomeModel home) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: home.image?.isNotEmpty == true
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    home.image!,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  Icons.home_outlined,
                  color: theme.primaryColor,
                  size: 24,
                ),
        ),
        title: Text(
          home.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "${home.rooms.length} phòng • ${_calculateTotalDevices(home.rooms)} thiết bị",
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _calculateTotalDevices(home.rooms) > 0 ? "Đang hoạt động" : "Không có thiết bị",
            style: TextStyle(
              color: _calculateTotalDevices(home.rooms) > 0 ? theme.primaryColor : Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeDetailPage(home: home),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.home_work_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            "Chưa có ngôi nhà nào",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Thêm ngôi nhà đầu tiên để bắt đầu trải nghiệm",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to add home
            },
            icon: Icon(Icons.add, size: 18, color: theme.colorScheme.onPrimary),
            label: Text("Thêm nhà mới", style: TextStyle(color: theme.colorScheme.onPrimary)),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String text, IconData icon, Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: theme.colorScheme.onSurface,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.4),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              "Xác nhận đăng xuất",
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ],
        ),
        content: Text(
          "Bạn có chắc chắn muốn đăng xuất khỏi tài khoản hiện tại?",
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Hủy",
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              authController.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text("Đăng xuất"),
          ),
        ],
      ),
    );
  }

  int _calculateTotalRooms(List<HomeModel> homes) {
    return homes.fold(0, (sum, home) => sum + home.rooms.length);
  }
}