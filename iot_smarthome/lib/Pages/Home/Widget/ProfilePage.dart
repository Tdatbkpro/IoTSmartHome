import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Config/Texts.dart';
import 'package:iot_smarthome/Controllers/Auth.dart';
import 'package:iot_smarthome/Controllers/DeviceController.dart';
import 'package:iot_smarthome/Models/HomeModel.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:iot_smarthome/Models/UserModel.dart';
import 'package:kf_drawer/kf_drawer.dart';
import '../../User/AuthPage.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({Key? key}) : super(key: key);

  final authController = Get.put(AuthController());
  final deviceController = Get.put(DeviceController());
  final firebaseUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => KFDrawer.of(context)?.toggle(),
        ),
      ),
      body: Obx(() {
        final homes = deviceController.homes;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Avatar + Name + Email
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: firebaseUser?.photoURL != null
                        ? NetworkImage(firebaseUser!.photoURL!)
                        : const AssetImage("assets/icons/logo.png") as ImageProvider,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<User?>(
                          future:firebaseUser != null
                        ? authController.getUserById(firebaseUser!.uid) // 👈 lấy user Firestore
                        : null,

                           builder: (context,snapshot) {
                            final user = snapshot.data;
                            return Text(
                              user?.name ?? firebaseUser?.displayName ?? firebaseUser?.email ?? "Guest",
                        style: AppTextStyles.title,

                            );
                           }),
                        const SizedBox(height: 4),
                        Text(
                          firebaseUser?.email ?? "",
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Divider
              const Divider(),

              // Homes đang điều khiển
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Homes đang điều khiển",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),

              homes.isEmpty
                  ? const Text("Chưa có home nào")
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: homes.length,
                      itemBuilder: (context, index) {
                        final home = homes[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: const Icon(Icons.home, color: Colors.blue),
                            title: Text(home.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                "${home.rooms.length} phòng đang quản lý"),
                          ),
                        );
                      },
                    ),
            ],
          ),
        );
      }),
    );
  }
}
