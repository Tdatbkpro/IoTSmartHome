import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:flutter_advanced_avatar/flutter_advanced_avatar.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Controllers/Auth.dart';
import 'package:iot_smarthome/Controllers/DeviceController.dart';
import 'package:iot_smarthome/Controllers/ThemeController.dart';
import 'package:iot_smarthome/Pages/Home/Widget/ChangeUserInfo.dart';
import 'package:kf_drawer/kf_drawer.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../../Models/UserModel.dart';

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
  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => KFDrawer.of(context)?.toggle(),
        ),
      ),
      body: StreamBuilder<User?>(
                  stream: authController.getUserByIdStream(firebaseUser!.uid), // 👈 dùng stream thay vì future
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return const Center(child: Text("Lỗi tải user"));
                    } else if (!snapshot.hasData || snapshot.data == null) {
                      return const Center(child: Text("Không có dữ liệu user"));
                    }

                    final user = snapshot.data!; 

            return Obx( () =>
              SettingsList(
                sections: [
                  SettingsSection(
                    tiles: [
                      SettingsTile.navigation(
                        title: Text(user.name!),
                        leading: AdvancedAvatar(
                                    name: user.name,
                                    animated: true,
                                    image: (user.profileImage != null && user.profileImage!.isNotEmpty)
                                        ? NetworkImage(user.profileImage!)
                                        : null,
                                    child: Text(   // 👈 thêm dòng này để hiện chữ cái đầu
                                      user.name!.isNotEmpty ? user.name![0].toUpperCase() : "?",
                                      style: TextStyle(color: Colors.white, fontSize: 20),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue, // 👈 đổi nền thay vì mặc định đen
                                      shape: BoxShape.circle,
                                    ),
                                  ),
              
                        enabled: true,
                        trailing: Icon(Icons.chevron_right_outlined, color: Colors.amber,),
                        value: Text(user.email ?? ""),
                        onPressed: (context) {
                          Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Changeuserinfo(user: user,)),
                        );
              
                        },
                      ),
                    ],
                  ),
                  SettingsSection(
                    tiles: [
                      SettingsTile.navigation(
                        leading: const Icon(Icons.language),
                        title: const Text('Ngôn ngữ'),
                        value: const Text('Tiếng Việt'),
                        onPressed: (context) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Chưa hỗ trợ ngôn ngữ khác")),
                          );
                        },
                      ),
                      SettingsTile.switchTile(
                        leading: const Icon(Icons.dark_mode),
                        title: const Text('Chế độ tối'),
                        onToggle: (bool value) {
                          themeController.toggleTheme(value);
                        },
                        initialValue:
                            themeController.themeMode.value == ThemeMode.dark,
                      ),
              
                      SettingsTile.navigation(
                        leading: const Icon(Icons.assistant),
                        title: const Text('Cài đặt'),
                        value: const Text('Trợ lý voice'),
                        onPressed: (context) {
                          Get.toNamed("/voiceAssistant");
                        },
                      ),
                    ],
                  ),
                 
                ],
              ),
            );
          },
        ),

    );
  }
}
