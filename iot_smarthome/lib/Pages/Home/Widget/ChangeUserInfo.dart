import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iot_smarthome/Controllers/Auth.dart';
import 'package:iot_smarthome/Controllers/PickImageController.dart';
import 'package:iot_smarthome/Models/UserModel.dart';

class Changeuserinfo extends StatelessWidget {
  final User user;
  Changeuserinfo({super.key, required this.user});

  final authController = Get.put(AuthController());
  final pickImageController = Get.put(PickImageController());

  final RxString avatarImage = "".obs;
  final RxString name = "".obs;

  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _rePassController = TextEditingController();

  /// ✅ Chọn ảnh avatar mới
  Future<void> _pickAvatar() async {
    final picked = await pickImageController.pickImageFileAndUpload();
    if (picked != null) {
      avatarImage.value = picked;
    }
  }

  /// ✅ Lưu thông tin người dùng
  Future<void> _saveUserInfo(BuildContext context) async {
    if (name.value.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Tên không được để trống")));
      return;
    }

    try {
      await authController.updateUserInfo(name.value, avatarImage.value);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật thông tin thành công ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  /// ✅ Cập nhật mật khẩu
  Future<void> _updatePassword(BuildContext context) async {
    if (_passwordFormKey.currentState!.validate()) {
      final checked = await authController.checkOldPassword(_oldPassController.text);
      if (checked) {
        await authController.updateUserPassword(
          oldPassword: _oldPassController.text,
          newPassword: _newPassController.text,
          rePassword: _rePassController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đổi mật khẩu thành công ✅")),
        );

        _oldPassController.clear();
        _newPassController.clear();
        _rePassController.clear();

        await authController.signOut();
        Get.toNamed("/authPath");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mật khẩu cũ không đúng ❌")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    name.value = user.name ?? "";
    _emailController.text = user.email ?? "";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ Avatar reactive
            Obx(() => Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blueAccent,
                        backgroundImage: avatarImage.value.isNotEmpty
                            ? NetworkImage(avatarImage.value)
                            : (user.profileImage != null &&
                                    user.profileImage!.isNotEmpty)
                                ? NetworkImage(user.profileImage!)
                                : null,
                        child: (avatarImage.value.isEmpty &&
                                (user.profileImage == null ||
                                    user.profileImage!.isEmpty))
                            ? Text(
                                (user.name?.isNotEmpty ?? false)
                                    ? user.name![0].toUpperCase()
                                    : "?",
                                style: const TextStyle(
                                    fontSize: 40, color: Colors.white),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickAvatar,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blueAccent,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      )
                    ],
                  ),
                )),
            const SizedBox(height: 24),

            // ✅ Thông tin user
            Form(
              key: _formKey,
              child: Card(
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Obx(() => TextFormField(
                            initialValue: name.value,
                            onChanged: (val) => name.value = val,
                            decoration: const InputDecoration(
                              labelText: "Tên hiển thị",
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Tên không được để trống";
                              }
                              return null;
                            },
                          )),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _saveUserInfo(context),
                        icon: const Icon(Icons.save),
                        label: const Text("Lưu thông tin"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ✅ Form đổi mật khẩu
            Form(
              key: _passwordFormKey,
              child: Card(
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text("Đổi mật khẩu",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _oldPassController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Mật khẩu cũ",
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Vui lòng nhập mật khẩu cũ";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _newPassController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Mật khẩu mới",
                          prefixIcon: Icon(Icons.lock),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return "Mật khẩu mới ít nhất 6 ký tự";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _rePassController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Nhập lại mật khẩu mới",
                          prefixIcon: Icon(Icons.lock_reset),
                        ),
                        validator: (value) {
                          if (value != _newPassController.text) {
                            return "Mật khẩu nhập lại không khớp";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _updatePassword(context),
                        icon: const Icon(Icons.vpn_key),
                        label: const Text("Cập nhật mật khẩu"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
