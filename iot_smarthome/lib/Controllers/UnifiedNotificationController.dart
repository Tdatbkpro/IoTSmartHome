import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_smarthome/Models/HomeModel.dart';
import 'package:iot_smarthome/Models/UnifiedNotificationModel.dart';

final unifiedNotificationControllerProvider = Provider<UnifiedNotificationController>((ref) {
  return UnifiedNotificationController();
});

class UnifiedNotificationController {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  
  Stream<List<UnifiedNotificationModel>> getNotificationStream() {
    final user = auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return db.collection("users")
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

  // Lấy stream chỉ cho device 
  Stream<List<UnifiedNotificationModel>> getDeviceAlertsStream() {
    final user = auth.currentUser;
    if (user == null) return const Stream.empty();
    
    return db.collection("users")
      .doc(user.uid)
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
    final user = auth.currentUser;
    if (user == null) return const Stream.empty();
    
    return db.collection("users")
      .doc(user.uid)
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
    final user = auth.currentUser;
    if (user == null) return;

    await db.collection("users")
        .doc(user.uid)
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
    final user = auth.currentUser;
    final originalDoc = await db.collection("users")
        .doc(user!.uid)
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
          ? '${user.email} đã chấp nhận lời mời tham gia ${originalData['homeName']}'
          : '${user.email} đã từ chối lời mời tham gia ${originalData['homeName']}',
      isRead: false,
      isProcessed: false,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      createdAt: DateTime.now(),
      fromUserId: user.uid,
      fromUserName: 'Hệ thống',
      fromUserEmail: user.email!,
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
    final user = auth.currentUser;
    final db = FirebaseFirestore.instance;

    if (user == null) {
      print("⚠️ Chưa đăng nhập, không thể thêm thành viên.");
      return;
    }

    final doc = await db
        .collection("users")
        .doc(user.uid)
        .collection("Notifications")
        .doc(notificationId)
        .get();

    if (!doc.exists) {
      print("⚠️ Không tìm thấy thông báo $notificationId.");
      return;
    }

    final data = doc.data()!;
    final homeId = data['homeId'];

    if (homeId == null) {
      print("⚠️ homeId null, không thể thêm thành viên.");
      return;
    }

    final homeRef = db.collection('Homes').doc(homeId);
    final homeSnap = await homeRef.get();

    if (!homeSnap.exists) {
      print("⚠️ Không tìm thấy home $homeId.");
      return;
    }

    final homeData = homeSnap.data()!;
    final membersData = List<Map<String, dynamic>>.from(homeData['members'] ?? []);
    final members = membersData.map((m) => HomeMember.fromMap(m)).toList();

    // Kiểm tra xem user đã là thành viên chưa
    final alreadyMember = members.any((m) => m.userId == user.uid);

    if (alreadyMember) {
      print("ℹ️ Người dùng đã là thành viên của home này, bỏ qua.");
      return;
    }

    // Nếu chưa có thì thêm vào
    final homeMember = HomeMember(
      userId: user.uid,
      role: HomeRole.member,
      joinedAt: DateTime.now(),
      invitedAt: DateTime.now(),
      invitedBy: data["fromUserName"],
    );

    try {
      await homeRef.update({
        'members': FieldValue.arrayUnion([homeMember.toMap()])
      });
      print("✅ Đã thêm thành viên vào home $homeId");
    } catch (e) {
      print("❌ Lỗi khi thêm thành viên: $e");
    }
  }

  /// 🧹 Hàm xóa thành viên khỏi home
  Future<void> removeUserFromHome(String homeId, String userId) async {
    final db = FirebaseFirestore.instance;

    final homeRef = db.collection('Homes').doc(homeId);
    final homeSnap = await homeRef.get();

    if (!homeSnap.exists) {
      print("⚠️ Không tìm thấy home $homeId.");
      return;
    }

    final homeData = homeSnap.data()!;
    final membersData = List<Map<String, dynamic>>.from(homeData['members'] ?? []);
    final members = membersData.map((m) => HomeMember.fromMap(m)).toList();

    // Tìm thành viên cần xóa
    final memberToRemove = members.firstWhere(
      (m) => m.userId == userId,
      orElse: () => HomeMember.empty(),
    );

    if (memberToRemove.userId == null) {
      print("⚠️ Không tìm thấy thành viên cần xóa.");
      return;
    }

    try {
      await homeRef.update({
        'members': FieldValue.arrayRemove([memberToRemove.toMap()])
      });
      print("🗑️ Đã xóa thành viên $userId khỏi home $homeId");
    } catch (e) {
      print("❌ Lỗi khi xóa thành viên: $e");
    }
  }

  Future<void> updateMemberInHome(String userId, HomeRole memberRole, String homeId) async {
      final db = FirebaseFirestore.instance;

      final homeRef = db.collection('Homes').doc(homeId);
      final homeSnap = await homeRef.get();

      if (!homeSnap.exists) {
        print("⚠️ Không tìm thấy home $homeId.");
        return;
      }

      final homeData = homeSnap.data()!;
      final membersData = List<Map<String, dynamic>>.from(homeData['members'] ?? []);
      final members = membersData.map((m) => HomeMember.fromMap(m)).toList();

      // Tìm index của member cần update
      final index = members.indexWhere((m) => m.userId == userId);

      if (index == -1) {
        print("⚠️ Không tìm thấy thành viên cần cập nhật.");
        return;
      }

      // Cập nhật thông tin member
      members[index].role = memberRole;
      try {
        // Chuyển lại thành Map để lưu vào Firestore
        final updatedMembersData = members.map((m) => m.toMap()).toList();

        await homeRef.update({'members': updatedMembersData});
        
      } catch (e) {
        print("❌ Lỗi khi cập nhật thành viên: $e");
      }
    }


  // Các method chung
  Future<void> markAsRead(String notificationId) async {
    final user = auth.currentUser;
    if (user == null) return;
    await db.collection("users")
        .doc(user.uid)
        .collection("Notifications")
        .doc(notificationId)
        .update({'isRead': true});
  }

 Future<void> markAsProcessed(String notificationId) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ No user logged in");
      return;
    }

    print("🔍 Marking as processed: $notificationId");

    // CÁCH 1: Thử update trực tiếp với ID (đơn giản nhất)
    try {
      final docRef = db.collection("users")
          .doc(user.uid)
          .collection("Notifications")
          .doc(notificationId);
      
      await docRef.update({'isProcessed': true});
      print("✅ Successfully marked as processed: $notificationId");
      return;
    } catch (e) {
      print("⚠️ Direct update failed: $e");
    }

    // CÁCH 2: Lấy tất cả và filter trong code (không cần index)
    final allNotifications = await db.collection("users")
        .doc(user.uid)
        .collection("Notifications")
        .get();

    // Tìm document chưa xử lý đầu tiên
    for (var doc in allNotifications.docs) {
      final data = doc.data();
      if (data['isProcessed'] == false) {
        await doc.reference.update({'isProcessed': true});
        print("✅ Marked first unprocessed as processed: ${doc.id}");
        return;
      }
    }

    print("❌ No unprocessed notifications found");

  } catch (e) {
    print("❌ Error in markAsProcessed: $e");
    // Không rethrow để app không crash
  }
}
  Future<void> deleteNotification(String notificationId) async {
    final user = auth.currentUser;
    if (user == null) return;
    await db.collection("users")
        .doc(user.uid)
        .collection("Notifications")
        .doc(notificationId)
        .delete();
  }

  Future<void> restoreNotification(String notificationId, UnifiedNotificationModel notification) async {
    final user = auth.currentUser;
    if (user == null) return;
    await db.collection("users")
        .doc(user.uid)
        .collection("Notifications")
        .doc(notificationId)
        .set(notification.toMap());
  }

  // Lấy số lượng thông báo chưa đọc
  Stream<int> getUnreadCount() {
    final user = auth.currentUser;
    if (user == null) return Stream.value(0);
    
    return db.collection("users")
        .doc(user.uid)
        .collection("Notifications")
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs.length);
  }

  // Lấy số lượng invitations chưa đọc
  Stream<int> getUnreadInvitationsCount() {
    final user = auth.currentUser;
    if (user == null) return Stream.value(0);
    
    return db.collection("users")
        .doc(user.uid)
        .collection("Notifications")
        .where('type', whereIn: ['invitation', 'invitation_response'])
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs.length);
  }

  // Đánh dấu invitation đã đọc
  Future<void> markInvitationAsRead(String notificationId) async {
    final user = auth.currentUser;
    if (user == null) return;
    await db.collection("users")
        .doc(user.uid)
        .collection("Notifications")
        .doc(notificationId)
        .update({'isRead': true});
  }
}