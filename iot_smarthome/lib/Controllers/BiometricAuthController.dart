import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BiometricAuthController extends GetxController {
  final LocalAuthentication auth = LocalAuthentication();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  RxBool canCheckBiometrics = false.obs;
  RxBool isEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkBiometricAvailability();
  }

  Future<void> checkBiometricAvailability() async {
    canCheckBiometrics.value = await auth.canCheckBiometrics;
  }

  // Lưu email và password sau khi đăng nhập
  Future<void> saveLoginInfo(String email, String password) async {
    await secureStorage.write(key: 'email', value: email);
    await secureStorage.write(key: 'password', value: password);
  }

  // Dùng vân tay để đăng nhập
  Future<void> loginWithBiometrics(BuildContext context) async {
    try {
      final isAuthenticated = await auth.authenticate(
        localizedReason: 'Xác thực vân tay để đăng nhập',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (isAuthenticated) {
        final email = await secureStorage.read(key: 'email');
        final password = await secureStorage.read(key: 'password');

        if (email != null && password != null) {
          await firebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          Get.snackbar("Thành công", "Đăng nhập bằng vân tay thành công");
          Get.offAllNamed('/home'); // điều hướng tới trang chính
        } else {
          Get.snackbar("Lỗi", "Chưa có thông tin đăng nhập được lưu");
        }
      }
    } catch (e) {
      Get.snackbar("Lỗi", e.toString());
    }
  }

  // Xoá thông tin đã lưu
  Future<void> clearSavedInfo() async {
    await secureStorage.deleteAll();
  }
}
