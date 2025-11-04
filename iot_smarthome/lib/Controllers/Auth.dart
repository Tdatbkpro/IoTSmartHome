import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_core/firebase_core.dart';
 import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Controllers/BiometricAuthController.dart';
import 'package:iot_smarthome/Controllers/LoginDeviceController.dart';
import '../Models/UserModel.dart';

class AuthController extends GetxController {
  final auth = FirebaseAuth.instance;
    final db = FirebaseFirestore.instance;
    final RxBool isLoading = false.obs;
    final RxBool successSignIn = true.obs;
    final biometricController = Get.put(BiometricAuthController());
    static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

    String signInMessageError = '';
    String signUpMessageError = '';
    
  Stream<User?> getUserByIdStream(String uid) {
  try {
    return db.collection("users").doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return User.fromJson(snapshot.data()!);
      } else {
        return null;
      }
    });
  } catch (e) {
    debugPrint("❌ Lỗi khi stream user theo id: $e");
    // Nếu có lỗi, trả về Stream rỗng để không crash
    return const Stream.empty();
  }
}
Future<User?> getUserById(String uid) async {
  try {
    final docSnapshot = await db.collection("users").doc(uid).get();
    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      if (data != null) {
        return User.fromJson(data); // hoặc User.fromJson(data)
      }
    }
    return null; // Không tìm thấy user
  } catch (e) {
    print("Lỗi khi lấy user: $e");
    return null;
  }
}

    Future<bool> checkOldPassword(String oldPassword) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    final cred = EmailAuthProvider.credential(
      email: user!.email!,
      password: oldPassword,
    );

    await user.reauthenticateWithCredential(cred);
    return true; // ✅ nhập đúng mật khẩu
  } catch (e) {
    debugPrint("❌ Sai mật khẩu cũ: $e");
    return false;
  }
}
Future<String?> updateUserPassword({
  required String oldPassword,
  required String newPassword,
  required String rePassword,
}) async {
  if (newPassword != rePassword) {
    return "Mật khẩu nhập lại không khớp";
  }

  final isValidOldPass = await checkOldPassword(oldPassword);
  if (!isValidOldPass) {
    return "Mật khẩu cũ không chính xác";
  }

  try {
    final user = FirebaseAuth.instance.currentUser;
    await user!.updatePassword(newPassword);
    return null; // ✅ thành công
  } catch (e) {
    debugPrint("❌ Lỗi đổi mật khẩu: $e");
    return "Có lỗi xảy ra, vui lòng thử lại";
  }
}
Future<void> updateUserInfo(String? name, String? avatarFile) async {
  try {
    final Map<String, dynamic> updateData = {};

    // Chỉ cập nhật tên nếu khác null hoặc rỗng
    if (name != null && name.isNotEmpty) {
      updateData["name"] = name;
    }

    // Chỉ cập nhật ảnh nếu có ảnh mới
    if (avatarFile != null && avatarFile.isNotEmpty) {
      updateData["profileImage"] = avatarFile;
    }

    // Nếu có dữ liệu để cập nhật
    if (updateData.isNotEmpty) {
      await db.collection("users").doc(auth.currentUser!.uid).update(updateData);
      showSuccessSnackbar("Cập nhật thông tin thành công");
    } 
  } catch (e) {
    showErrorSnackbar("Lỗi sửa thông tin: $e");
  }
}


  Future<void> signIn(String email, String password) async {
      isLoading.value = true;
      signInMessageError = '';
      try {
        UserCredential userCredential = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        final uid = userCredential.user?.uid;
        if (uid != null) {
          await db.collection("users").doc(uid).update({
            'lastOnlineStatus': DateTime.now().toIso8601String(),
            'status': 'online',
          });

          await biometricController.saveLoginInfo(
            email.trim(),
            password.trim(),
          );
        }
        successSignIn.value = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.put(LoginDeviceController()).saveDeviceInfo();
        });
        showSuccessSnackbar('🎉 Đăng nhập thành công!');
        Get.toNamed("/homePage");
      } on FirebaseAuthException catch (e) {
        successSignIn.value = false;
        debugPrint(e.message);
        switch (e.code) {
          case 'invalid-email':
            signInMessageError = '❌ Email không đúng định dạng.';
            break;
          case 'user-disabled':
            signInMessageError = '❌ Tài khoản đã bị vô hiệu hóa.';
            break;
          case 'user-not-found':
          case 'wrong-password':
          case 'invalid-credential':
            signInMessageError = '❌ Email hoặc mật khẩu không chính xác.';
            break;
          case 'too-many-requests':
            signInMessageError = '❌ Đăng nhập thất bại quá nhiều lần. Vui lòng thử lại sau.';
            break;
          case 'operation-not-allowed':
            signInMessageError = '❌ Phương thức đăng nhập chưa được bật.';
            break;
          case 'network-request-failed':
            signInMessageError = '❌ Lỗi kết nối mạng. Vui lòng kiểm tra Internet.';
            break;
          case 'internal-error':
            signInMessageError = '❌ Lỗi hệ thống. Vui lòng thử lại.';
            break;
          case 'missing-email':
            signInMessageError = '❌ Bạn chưa nhập email.';
            break;
          case 'missing-password':
            signInMessageError = '❌ Bạn chưa nhập mật khẩu.';
            break;
          default:
            signInMessageError = '❌ Lỗi không xác định: ${e.message}';
        }
        showErrorSnackbar(signInMessageError);
      } catch (e) {
        signInMessageError = '❌ Lỗi không xác định: $e';
        showErrorSnackbar(signInMessageError);
      } finally {
        isLoading.value = false;
      }
    }
    Future<void> signOut() async {
      try {
        await auth.signOut();
        Get.offAllNamed('/authPath');
      } catch (e) {
        Get.snackbar(
        'Lỗi đăng xuất',
        e.toString(),
        backgroundColor: Colors.redAccent.shade200,
        colorText: Colors.white,
      );
      }
    }
  // --- Forgot password ---
  Future<void> sendPasswordResetEmail(String email) async {
  isLoading.value = true;
  try {
    // Kiểm tra email trong Firestore (collection "users")
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .get();

    if (snapshot.docs.isEmpty) {
      Get.snackbar(
        'Lỗi',
        '❌ Email không tồn tại',
        backgroundColor: Colors.redAccent.shade200,
        colorText: Colors.white,
      );
      return;
    }

    // Gửi email reset
    await auth.sendPasswordResetEmail(email: email.trim());

    Get.snackbar(
      'Thành công',
      '🎉 Link đặt lại mật khẩu đã được gửi đến email của bạn nằm ở thư rác',
      backgroundColor: Colors.green.shade400,
      colorText: Colors.white,
    );
  } catch (e) {
    Get.snackbar(
      'Lỗi',
      '❌ Lỗi không xác định: $e',
      backgroundColor: Colors.redAccent.shade200,
      colorText: Colors.white,
    );
  } finally {
    isLoading.value = false;
  }
}

  Future<void> signUp(String email, String password, String name) async {
      isLoading.value = true;
      signUpMessageError = '';
      try {
        UserCredential userCredential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = userCredential.user;
        if (user != null) {
          await initUser(user.uid,email, name);
        }

        showSuccessSnackbar('🎉 Đăng ký tài khoản thành công!');
        Get.offAllNamed("/authPath");
      } on FirebaseAuthException catch (e) {
        switch (e.code) {
          case 'email-already-in-use':
            signUpMessageError = '❌ Email đã được sử dụng.';
            break;
          case 'invalid-email':
            signUpMessageError = '❌ Email không hợp lệ.';
            break;
          case 'operation-not-allowed':
            signUpMessageError = '❌ Tính năng đăng ký đang bị vô hiệu hóa.';
            break;
          case 'weak-password':
            signUpMessageError = '❌ Mật khẩu quá yếu.';
            break;
          case 'network-request-failed':
            signUpMessageError = '❌ Lỗi mạng. Vui lòng kiểm tra kết nối.';
            break;
          case 'internal-error':
            signUpMessageError = '❌ Lỗi hệ thống.';
            break;
          case 'missing-email':
            signUpMessageError = '❌ Bạn chưa nhập email.';
            break;
          case 'missing-password':
            signUpMessageError = '❌ Bạn chưa nhập mật khẩu.';
            break;
          default:
            signUpMessageError = '❌ Lỗi không xác định: ${e.message}';
        }
        showErrorSnackbar(signUpMessageError);
      } catch (e) {
        signUpMessageError = '❌ Lỗi không xác định: $e';
        showErrorSnackbar(signUpMessageError);
      } finally {
        isLoading.value = false;
      }
    }
    Future<void> initUser(String uid, String email, String name) async {
    try {
      var newUser = User(
        id: uid,
        email: email,
        name: name,
        phoneNumber: null, // chưa có
        profileImage: null, // chưa có
        createdAt: DateTime.now(),
      );
      await db.collection("users").doc(uid).set(newUser.toJson());
      print("User saved to Firestore");
    } catch (e) {
      print('❌ Lỗi khi tạo user mới: $e');
    }
  }

    void showErrorSnackbar(String message) {
      Get.snackbar(
        'Lỗi',
        message,
        backgroundColor: Colors.redAccent.shade200,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 14,
        isDismissible: true,
      );
    }

    void showSuccessSnackbar(String message) async {
      Get.snackbar(
        'Thành công',
        message,
        backgroundColor: Colors.green.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 14,
        isDismissible: true,
      );
    }
}