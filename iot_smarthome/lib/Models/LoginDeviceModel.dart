// lib/Models/DeviceModel.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginDeviceModel {
  final String deviceId;
  final String deviceModel;
  final String deviceName;
  final String? token;
  final String lastActive;
  final String? createdAt;

  LoginDeviceModel({
    required this.deviceId,
    required this.deviceModel,
    required this.deviceName,
    this.token,
    required this.lastActive,
    this.createdAt,
  });

  factory LoginDeviceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoginDeviceModel(
      deviceId: data['deviceId'] ?? '',
      deviceModel: data['deviceModel'] ?? 'Unknown Device',
      deviceName: data['deviceName'] ?? 'Unknown',
      token: data['token'],
      lastActive: data['lastActive'] ?? DateTime.now().toIso8601String(),
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceModel': deviceModel,
      'deviceName': deviceName,
      'token': token,
      'lastActive': lastActive,
      'createdAt': createdAt,
    };
  }
}