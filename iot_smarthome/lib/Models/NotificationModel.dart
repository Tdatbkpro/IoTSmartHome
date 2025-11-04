import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String deviceId;
  final String homeId;
  final String roomId;
  final String locationDevice;
  final String deviceType;
  final String deviceName;
  final bool isProcessed;
  final String type;
  final String message;
  final bool isRead;
  final int timestamp;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.deviceId,
    required this.locationDevice,
    required this.homeId,
    required this.roomId,
    required this.deviceType,
    required this.deviceName,
    required this.type,
    required this.isProcessed,
    required this.message,
    required this.isRead,
    required this.timestamp,
    this.createdAt,
  });

  // Chuyển từ Firestore document -> object
  factory NotificationModel.fromMap(Map<String, dynamic> data, String documentId) {
    return NotificationModel(
      id: documentId,
      deviceId: data['deviceId'] ?? '',
      homeId: data['homeId'] ?? '',
      roomId: data['roomId'] ?? '',
      locationDevice: data['locationDevice'] ?? '',
      type: data['type'] ?? '',
      message: data['message'] ?? '',
      deviceName: data['deviceName'] ?? '',
      deviceType: data['deviceType'] ?? '',
      isProcessed: data['isProcessed'] ?? false,
      isRead: data['isRead'] ?? false,
      timestamp: data['timestamp'] ?? 0,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Chuyển object -> Map (để lưu lại Firestore)
  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'homeId': homeId,
      'roomId': roomId,
      'type': type,
      'locationDevice': locationDevice,
      'message': message,
      'isProcessed': isProcessed,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'isRead': isRead,
      'timestamp': timestamp,
      'createdAt': createdAt,
    };
  }
}
