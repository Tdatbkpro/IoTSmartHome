// models/invitation_notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class InvitationNotificationModel {
  final String id;
  final String invitationId;
  final String fromUserId;
  final String fromUserName;
  final String fromUserEmail;
  final String toUserEmail;
  final String toUserId; // Có thể null cho đến khi user accept
  final String homeId;
  final String homeName;
  final String status; // 'pending', 'accepted', 'rejected'
  final String type;
  final String message;
  final bool isRead;
  final int timestamp;
  final DateTime? createdAt;

  InvitationNotificationModel({
    required this.id,
    required this.invitationId,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromUserEmail,
    required this.toUserEmail,
    required this.toUserId,
    required this.homeId,
    required this.homeName,
    required this.status,
    required this.type,
    required this.message,
    required this.isRead,
    required this.timestamp,
    this.createdAt,
  });

  factory InvitationNotificationModel.fromMap(Map<String, dynamic> data, String documentId) {
    return InvitationNotificationModel(
      id: documentId,
      invitationId: data['invitationId'] ?? '',
      fromUserId: data['fromUserId'] ?? '',
      fromUserName: data['fromUserName'] ?? '',
      fromUserEmail: data['fromUserEmail'] ?? '',
      toUserEmail: data['toUserEmail'] ?? '',
      toUserId: data['toUserId'] ?? '',
      homeId: data['homeId'] ?? '',
      homeName: data['homeName'] ?? '',
      status: data['status'] ?? 'pending',
      type: data['type'] ?? 'invitation',
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      timestamp: data['timestamp'] ?? 0,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invitationId': invitationId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserEmail': fromUserEmail,
      'toUserEmail': toUserEmail,
      'toUserId': toUserId,
      'homeId': homeId,
      'homeName': homeName,
      'status': status,
      'type': type,
      'message': message,
      'isRead': isRead,
      'timestamp': timestamp,
      'createdAt': createdAt,
    };
  }
}