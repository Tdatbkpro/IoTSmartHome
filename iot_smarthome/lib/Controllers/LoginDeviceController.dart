// lib/Controllers/DeviceController.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:iot_smarthome/Models/LoginDeviceModel.dart';

class LoginDeviceController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  final RxList<LoginDeviceModel> userDevices = <LoginDeviceModel>[].obs;
  final RxString currentDeviceId = ''.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initDeviceListener();
  }

  Future<void> _getCurrentDeviceInfo() async {
    try {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      currentDeviceId.value = androidInfo.id;
    } catch (e) {
      print('Error getting device info: $e');
    }
  }

  Future<void> loadUserDevices() async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user == null) return;

      final querySnapshot = await _db
          .collection("users")
          .doc(user.uid)
          .collection("devices")
          .orderBy("lastActive", descending: true)
          .get();

      userDevices.assignAll(
        querySnapshot.docs.map((doc) => LoginDeviceModel.fromFirestore(doc)).toList(),
      );
    } catch (e) {
      print('Error loading devices: $e');
      Get.snackbar(
        "Lỗi",
        "Không thể tải danh sách thiết bị",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
Future<void> _initDeviceListener() async {
  await _getCurrentDeviceInfo(); // Chờ lấy deviceId trước
  if (currentDeviceId.value.isNotEmpty) {
    _listenDeviceLogout();
  }
}

  Future<void> saveDeviceInfo() async {
    try {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      final String? token = await FirebaseMessaging.instance.getToken();
      final user = _auth.currentUser;
      
      if (user == null) return;

      final deviceInfo = {
        'deviceId': androidInfo.id,
        'deviceModel': androidInfo.model,
        'deviceName': androidInfo.name,
        'token': token,
        'lastActive': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _db
          .collection("users")
          .doc(user.uid)
          .collection("devices")
          .doc(androidInfo.id)
          .set(deviceInfo, SetOptions(merge: true));

      print('Device info saved successfully');
    } catch (e) {
      print('Error saving device info: $e');
    }
  }

  Future<void> signOutDevice(String targetDeviceId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _db
          .collection("users")
          .doc(user.uid)
          .collection("devices")
          .doc(targetDeviceId)
          .delete();

      // Remove from local list
      userDevices.removeWhere((device) => device.deviceId == targetDeviceId);

      Get.snackbar(
        "Thành công",
        "✅ Đã đăng xuất thiết bị",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error signing out device: $e');
      Get.snackbar(
        "Lỗi",
        "Không thể đăng xuất thiết bị",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _listenDeviceLogout() {
    final user = _auth.currentUser;
    if (user == null) return;

    _db
        .collection("users")
        .doc(user.uid)
        .collection("devices")
        .doc(currentDeviceId.value)
        .snapshots()
        .listen((snapshot) {
          if (!snapshot.exists) {
            // Device was deleted -> force logout
            _auth.signOut();
            Get.offAllNamed('/authPath');
            Get.snackbar(
              "Thông báo",
              "Tài khoản đã được đăng xuất từ thiết bị khác",
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        });
  }

  Future<void> updateDeviceActivity() async {
    try {
      final user = _auth.currentUser;
      if (user == null || currentDeviceId.value.isEmpty) return;

      await _db
          .collection("users")
          .doc(user.uid)
          .collection("devices")
          .doc(currentDeviceId.value)
          .update({
            'lastActive': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      print('Error updating device activity: $e');
    }
  }
}