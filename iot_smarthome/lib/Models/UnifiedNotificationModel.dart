// models/unified_notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  deviceAlert,
  invitation,
  invitationResponse,
  system
}

class UnifiedNotificationModel {
  final String id;
  final NotificationType type;
  
  // Common fields
  final String message;
  final bool isRead;
  final bool isProcessed;
  final int timestamp;
  final DateTime? createdAt;
  
  // Fields for device notifications
  final String? deviceId;
  final String? homeId;
  final String? roomId;
  final String? locationDevice;
  final String? deviceType;
  final String? deviceName;
  
  // Fields for invitation notifications
  final String? invitationId;
  final String? fromUserId;
  final String? fromUserName;
  final String? fromUserEmail;
  final String? toUserEmail;
  final String? toUserId;
  final String? invitationHomeId;
  final String? homeName;
  final String? status;

  UnifiedNotificationModel({
    required this.id,
    required this.type,
    required this.message,
    required this.isRead,
    required this.isProcessed,
    required this.timestamp,
    this.createdAt,
    
    // Device fields
    this.deviceId,
    this.homeId,
    this.roomId,
    this.locationDevice,
    this.deviceType,
    this.deviceName,
    
    // Invitation fields
    this.invitationId,
    this.fromUserId,
    this.fromUserName,
    this.fromUserEmail,
    this.toUserEmail,
    this.toUserId,
    this.invitationHomeId,
    this.homeName,
    this.status,
  });
  UnifiedNotificationModel copyWith({bool? isProcessed}) {
    return UnifiedNotificationModel(
      id: id,
      isRead: isRead,
      message: message,
      timestamp: timestamp,
      createdAt: createdAt,
      type: type,
      deviceId: deviceId,
      homeId: homeId,
      roomId: roomId,
      locationDevice: locationDevice,
      deviceType: deviceType,
      deviceName: deviceName,
      invitationId: invitationId,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      fromUserEmail: fromUserEmail,
      toUserEmail: toUserEmail,
      toUserId: toUserId,
      invitationHomeId: invitationHomeId,
      homeName: homeName,
      status: status,
      isProcessed: isProcessed ?? this.isProcessed,
    );
  }
  factory UnifiedNotificationModel.fromMap(Map<String, dynamic> data, String documentId) {
    final typeString = data['type'] ?? 'deviceAlert';
    final notificationType = _parseNotificationType(typeString);

    return UnifiedNotificationModel(
      id: documentId,
      type: notificationType,
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      isProcessed: data['isProcessed'] ?? false,
      timestamp: data['timestamp'] ?? 0,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      
      // Device fields
      deviceId: data['deviceId'],
      homeId: data['homeId'],
      roomId: data['roomId'],
      locationDevice: data['locationDevice'],
      deviceType: data['deviceType'],
      deviceName: data['deviceName'],
      
      // Invitation fields
      invitationId: data['invitationId'],
      fromUserId: data['fromUserId'],
      fromUserName: data['fromUserName'],
      fromUserEmail: data['fromUserEmail'],
      toUserEmail: data['toUserEmail'],
      toUserId: data['toUserId'],
      invitationHomeId: data['homeId'],
      homeName: data['homeName'],
      status: data['status'],
    );
  }

  static NotificationType _parseNotificationType(String typeString) {
    switch (typeString) {
      case 'invitation':
        return NotificationType.invitation;
      case 'invitation_response':
        return NotificationType.invitationResponse;
      case 'system':
        return NotificationType.system;
      case 'deviceAlert':
      default:
        return NotificationType.deviceAlert;
    }
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'type': _typeToString(type),
      'message': message,
      'isRead': isRead,
      'isProcessed': isProcessed,
      'timestamp': timestamp,
    };

    if (createdAt != null) {
      map['createdAt'] = Timestamp.fromDate(createdAt!);
    }

    // Add device fields for device alerts
    if (type == NotificationType.deviceAlert) {
      map.addAll({
        'deviceId': deviceId,
        'homeId': homeId,
        'roomId': roomId,
        'locationDevice': locationDevice,
        'deviceType': deviceType,
        'deviceName': deviceName,
      });
    }

    // Add invitation fields for invitation notifications
    if (type == NotificationType.invitation || type == NotificationType.invitationResponse) {
      map.addAll({
        'invitationId': invitationId,
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'fromUserEmail': fromUserEmail,
        'toUserEmail': toUserEmail,
        'toUserId': toUserId,
        'homeId': invitationHomeId,
        'homeName': homeName,
        'status': status,
      });
    }

    return map;
  }

  String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.invitation:
        return 'invitation';
      case NotificationType.invitationResponse:
        return 'invitation_response';
      case NotificationType.system:
        return 'system';
      case NotificationType.deviceAlert:
      default:
        return 'deviceAlert';
    }
  }

  // Helper methods
  bool get isDeviceAlert => type == NotificationType.deviceAlert;
  bool get isInvitation => type == NotificationType.invitation;
  bool get isInvitationResponse => type == NotificationType.invitationResponse;

  // Factory methods for specific types
  factory UnifiedNotificationModel.deviceAlert({
    required String id,
    required String deviceId,
    required String homeId,
    required String message,
    String roomId = '',
    String locationDevice = '',
    String deviceType = '',
    String deviceName = '',
    bool isRead = false,
    bool isProcessed = false,
    int? timestamp,
  }) {
    return UnifiedNotificationModel(
      id: id,
      type: NotificationType.deviceAlert,
      message: message,
      isRead: isRead,
      isProcessed: isProcessed,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      createdAt: DateTime.now(),
      deviceId: deviceId,
      homeId: homeId,
      roomId: roomId,
      locationDevice: locationDevice,
      deviceType: deviceType,
      deviceName: deviceName,
    );
  }

  factory UnifiedNotificationModel.invitation({
    required String id,
    required String fromUserId,
    required String fromUserName,
    required String fromUserEmail,
    required String toUserEmail,
    required String toUserId,
    required String homeId,
    required String homeName,
    String message = '',
    bool isRead = false,
    int? timestamp,
  }) {
    return UnifiedNotificationModel(
      id: id,
      type: NotificationType.invitation,
      message: message.isNotEmpty ? message : 'Bạn được mời tham gia ngôi nhà $homeName',
      isRead: isRead,
      isProcessed: false,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      createdAt: DateTime.now(),
      invitationId: id,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      fromUserEmail: fromUserEmail,
      toUserEmail: toUserEmail,
      toUserId: toUserId,
      invitationHomeId: homeId,
      homeName: homeName,
      status: 'pending',
    );
  }
}