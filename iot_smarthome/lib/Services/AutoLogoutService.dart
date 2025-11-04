// lib/Services/AutoLogoutService.dart
import 'dart:async';

import 'package:get/get.dart';
import 'package:iot_smarthome/Controllers/Auth.dart';
import 'package:iot_smarthome/Controllers/ThemeController.dart';

class AutoLogoutService extends GetxService {
  final ThemeController _themeController = Get.find();
  final AuthController _authController = Get.find();
  DateTime? lastUserActivity;
  Timer? logoutTimer;

  @override
  void onInit() {
    super.onInit();
    startActivityMonitoring();
  }

  void startActivityMonitoring() {
    // Reset timer khi có bất kỳ user activity nào
    Get.routing.obs.listen((_) => resetTimer());
  }

  void resetTimer() {
    lastUserActivity = DateTime.now();
    startLogoutTimer();
  }

  void startLogoutTimer() {
    logoutTimer?.cancel();
    
    if (_themeController.securitySettings.autoLogout == true) {
      final logoutTime = _themeController.securitySettings.autoLogoutTime ?? 15;
      
      logoutTimer = Timer(Duration(minutes: logoutTime), () {
        performLogout();
      });
    }
  }

  void performLogout() async {
    await _authController.signOut();
    // Điều hướng về màn hình login
    // Hiển thị thông báo
    Get.snackbar(
      "Tự động đăng xuất",
      "Bạn đã được đăng xuất tự động do không hoạt động",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void stopAutoLogout() {
    logoutTimer?.cancel();
  }

  @override
  void onClose() {
    logoutTimer?.cancel();
    super.onClose();
  }
}