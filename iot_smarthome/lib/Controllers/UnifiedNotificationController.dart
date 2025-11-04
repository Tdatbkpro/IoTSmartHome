// controllers/unified_notification_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Models/HomeModel.dart';
import 'package:iot_smarthome/Models/UnifiedNotificationModel.dart';


class UnifiedNotificationController extends GetxController {
  // final FireBáe auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;
  
  Stream<List<UnifiedNotificationModel>> getNotificationStream() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return const Stream.empty();
  }

  return FirebaseFirestore.instance
      .collection("users")
      .doc(user.uid)
      .collection("Notifications")
      .orderBy("timestamp", descending: true)
      .snapshots()
      .map((querySnapshot) {
        return querySnapshot.docs.map((doc) {
          return UnifiedNotificationModel.fromMap(doc.data(), doc.id);
        }).toList();
      });
}


  // Lấy stream chỉ cho device alerts
  Stream<List<UnifiedNotificationModel>> getDeviceAlertsStream() {
    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null) return const Stream.empty();
    
    return db.collection("users")
      .doc(auth!.uid)
      .collection("Notifications")
      .where('type', isEqualTo: 'deviceAlert')
      .orderBy("timestamp", descending: true)
      .snapshots()
      .map((querySnapshot) {
        return querySnapshot.docs.map((doc) {
          return UnifiedNotificationModel.fromMap(doc.data(), doc.id);
        }).toList();
      });
  }

  // Lấy stream chỉ cho invitations
  Stream<List<UnifiedNotificationModel>> getInvitationsStream() {
    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null) return const Stream.empty();
    
    return db.collection("users")
      .doc(auth!.uid)
      .collection("Notifications")
      .where('type', whereIn: ['invitation', 'invitation_response'])
      .orderBy("timestamp", descending: true)
      .snapshots()
      .map((querySnapshot) {
        return querySnapshot.docs.map((doc) {
          return UnifiedNotificationModel.fromMap(doc.data(), doc.id);
        }).toList();
      });
  }

  // Tạo invitation notification
  Future<void> createInvitationNotification({
    required String toUserEmail,
    required String fromUserId,
    required String fromUserName,
    required String fromUserEmail,
    required String homeId,
    required String homeName,
    String message = '',
  }) async {
    // Tìm user ID từ email
    final usersSnapshot = await db.collection('users')
        .where('email', isEqualTo: toUserEmail.toLowerCase())
        .get();
    
    if (usersSnapshot.docs.isEmpty) {
      throw Exception('User not found with email: $toUserEmail');
    }
    
    final toUserId = usersSnapshot.docs.first.id;
    final notificationId = db.collection('users').doc().id;

    final invitationNotification = UnifiedNotificationModel.invitation(
      id: notificationId,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      fromUserEmail: fromUserEmail,
      toUserEmail: toUserEmail,
      toUserId: toUserId,
      homeId: homeId,
      homeName: homeName,
      message: message,
    );

    await db.collection('users')
        .doc(toUserId)
        .collection('Notifications')
        .doc(notificationId)
        .set(invitationNotification.toMap());
  }

  // Xử lý invitation (accept/reject)
  Future<void> respondToInvitation(String notificationId, String response) async {
    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null) return;

    await db.collection("users")
        .doc(auth!.uid)
        .collection("Notifications")
        .doc(notificationId)
        .update({
          'status': response,
          'isProcessed': true,
          'isRead': true,
        });

    // Tạo notification response cho người gửi
    await _createInvitationResponseNotification(notificationId, response);
    
    // Thêm user vào home nếu accepted
    if (response == 'accepted') {
      await _addUserToHome(notificationId);
    }
  }

  Future<void> _createInvitationResponseNotification(String originalNotificationId, String response) async {
    final auth = FirebaseAuth.instance.currentUser;
    final originalDoc = await db.collection("users")
        .doc(auth!.uid)
        .collection("Notifications")
        .doc(originalNotificationId)
        .get();
    
    if (!originalDoc.exists) return;

    final originalData = originalDoc.data()!;
    final responseNotificationId = 'response_${originalNotificationId}';

    final responseNotification = UnifiedNotificationModel(
      id: responseNotificationId,
      type: NotificationType.invitationResponse,
      message: response == 'accepted'
          ? '${auth!.email} đã chấp nhận lời mời tham gia ${originalData['homeName']}'
          : '${auth!.email} đã từ chối lời mời tham gia ${originalData['homeName']}',
      isRead: false,
      isProcessed: false,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      createdAt: DateTime.now(),
      fromUserId: auth!.uid,
      fromUserName: 'Hệ thống',
      fromUserEmail: auth!.email!,
      toUserEmail: originalData['fromUserEmail'],
      toUserId: originalData['fromUserId'],
      invitationHomeId: originalData['homeId'],
      homeName: originalData['homeName'],
      status: response,
    );

    // Lưu notification cho người gửi
    await db.collection('users')
        .doc(originalData['fromUserId'])
        .collection('Notifications')
        .doc(responseNotificationId)
        .set(responseNotification.toMap());
  }

  Future<void> _addUserToHome(String notificationId) async {
  final auth = FirebaseAuth.instance.currentUser;
  final db = FirebaseFirestore.instance;

  final doc = await db
      .collection("users")
      .doc(auth!.uid)
      .collection("Notifications")
      .doc(notificationId)
      .get();

  if (doc.exists) {
    final data = doc.data()!;
    final homeId = data['homeId'];

    if (homeId == null) {
      print("⚠️ homeId null, không thể thêm thành viên.");
      return;
    }

    final homeMember = HomeMember(userId: auth.uid, role: HomeRole.member, joinedAt: DateTime.now(), invitedAt: DateTime.now(), invitedBy: doc["fromUserName"]);

    try {
      await db.collection('Homes').doc(homeId).set({
        'members': FieldValue.arrayUnion([homeMember.toMap()])
      }, SetOptions(merge: true));

      print("✅ Đã thêm thành viên vào home $homeId");
    } catch (e) {
      print("❌ Lỗi khi thêm thành viên: $e");
    }
  }
}


  // Các method chung
  Future<void> markAsRead(String notificationId) async {
    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null) return;
    await db.collection("users")
        .doc(auth!.uid)
        .collection("Notifications")
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAsProcessed(String notificationId) async {
    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null) return;
    await db.collection("users")
        .doc(auth!.uid)
        .collection("Notifications")
        .doc(notificationId)
        .update({'isProcessed': true});
  }

  Future<void> deleteNotification(String notificationId) async {
    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null) return;
    await db.collection("users")
        .doc(auth!.uid)
        .collection("Notifications")
        .doc(notificationId)
        .delete();
  }

  Future<void> restoreNotification(String notificationId, UnifiedNotificationModel notification) async {
    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null) return;
    await db.collection("users")
        .doc(auth!.uid)
        .collection("Notifications")
        .doc(notificationId)
        .set(notification.toMap());
  }

  // Lấy số lượng thông báo chưa đọc
  Stream<int> getUnreadCount() {
    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null) return Stream.value(0);
    
    return db.collection("users")
        .doc(auth!.uid)
        .collection("Notifications")
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs.length);
  }

  // Lấy số lượng invitations chưa đọc
  Stream<int> getUnreadInvitationsCount() {
    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null) return Stream.value(0);
    
    return db.collection("users")
        .doc(auth!.uid)
        .collection("Notifications")
        .where('type', whereIn: ['invitation', 'invitation_response'])
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs.length);
  }

  // Đánh dấu invitation đã đọc
  Future<void> markInvitationAsRead(String notificationId) async {
    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null) return;
    await db.collection("users")
        .doc(auth!.uid)
        .collection("Notifications")
        .doc(notificationId)
        .update({'isRead': true});
  }
}