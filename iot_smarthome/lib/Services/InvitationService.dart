// services/invitation_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

import 'package:http/http.dart' as http;
import 'package:iot_smarthome/Controllers/Auth.dart';
import 'package:iot_smarthome/Models/HomeModel.dart';
import 'package:iot_smarthome/Models/InvitationNotificationModel%20.dart';

class InvitationService {
  final String _baseUrl = "http://192.168.11.14:3000"; // Thay bằng server URL thực tế
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthController authController = Get.put(AuthController());

  // Gửi lời mời thành viên
  Future<bool> sendInvitation  ({
    required String toUserEmail,
    required String homeId,
    required String homeName,
  }) async {
    try {
      final currentUser = await authController.getUserById(_auth.currentUser!.uid);
      if (currentUser == null) throw Exception('User not logged in');
      if (currentUser.email == toUserEmail) throw Exception("Không thể gửi cho chính mình -_-");
      // 🎯 THÊM KIỂM TRA KẾT NỐI INTERNET
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/api/send-invitation'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'toUserEmail': toUserEmail,
            'homeId': homeId,
            'homeName': homeName,
            'fromUserId': currentUser.id,
            'fromUserName': currentUser.name ?? 'Thành viên',
            'fromUserEmail': currentUser.email,
          }),
        ).timeout(Duration(seconds: 10));

        if (response.statusCode == 200) {
          return true;
        } else {
          final errorData = json.decode(response.body);
          throw Exception(errorData['error'] ?? 'Lỗi không xác định');
        }
      } on http.ClientException catch (e) {
        // 🎯 FALLBACK: Sử dụng Firebase trực tiếp nếu server không khả dụng
        print('⚠️ Server unavailable, using Firebase fallback: $e');
        return await _sendInvitationViaFirebase(
          toUserEmail: toUserEmail,
          homeId: homeId,
          homeName: homeName,
        );
      }
    } catch (e) {
      print('Error sending invitation: $e');
      rethrow;
    }
  }

  // 🎯 FALLBACK METHOD: Gửi invitation trực tiếp qua Firebase
  Future<bool> _sendInvitationViaFirebase({
    required String toUserEmail,
    required String homeId,
    required String homeName,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      // Tìm user bằng email
      final userQuery = await _db
          .collection('users')
          .where('email', isEqualTo: toUserEmail.toLowerCase())
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('Người dùng với email này không tồn tại');
      }

      final toUserDoc = userQuery.docs.first;
      final toUserId = toUserDoc.id;
      final toUserData = toUserDoc.data();

      // Kiểm tra xem user đã trong nhà chưa
      final homeDoc = await _db.collection('Homes').doc(homeId).get();
      if (!homeDoc.exists) throw Exception('Ngôi nhà không tồn tại');
      
      final homeData = homeDoc.data() as Map<String, dynamic>;
      final members = List<Map<String,dynamic>>.from(homeData['members'] ?? []);

      for (var member in members) {
        String userId = member['userId'];
        print('User ID: $userId'); // In ra userId
        
        if (userId == toUserId) {
          throw Exception('Người dùng đã là thành viên của ngôi nhà này');
        }
      }


      // Kiểm tra xem đã có lời mời pending chưa
      final existingInvitation = await _db
          .collection('invitations')
          .where('toUserEmail', isEqualTo: toUserEmail.toLowerCase())
          .where('homeId', isEqualTo: homeId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingInvitation.docs.isNotEmpty) {
        throw Exception('Đã có lời mời đang chờ xử lý cho người dùng này');
      }

      // Tạo invitation ID
      final invitationId = _db.collection('invitations').doc().id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Tạo invitation document
      final invitation = InvitationNotificationModel(
        id: invitationId,
        invitationId: invitationId,
        fromUserId: currentUser.uid,
        fromUserName: currentUser.displayName ?? 'Thành viên',
        fromUserEmail: currentUser.email!,
        toUserEmail: toUserEmail.toLowerCase(),
        toUserId: toUserId,
        homeId: homeId,
        homeName: homeName,
        status: 'pending',
        type: 'invitation',
        message: 'Bạn được mời tham gia ngôi nhà $homeName',
        isRead: false,
        timestamp: timestamp,
        createdAt: DateTime.now(),
      );

      // Lưu invitation vào collection chính
      //await _db.collection('invitations').doc(invitationId).set(invitation.toMap());

      // Lưu notification cho người nhận
      await _db
          .collection('users')
          .doc(toUserId)
          .collection('Notifications')
          .doc(invitationId)
          .set(invitation.toMap());

      print('✅ Invitation sent via Firebase: $invitationId');
      return true;
    } catch (e) {
      print('Error sending invitation via Firebase: $e');
      rethrow;
    }
  }

  // Future<bool> acceptInvitation(String invitationId) async {
  //   return _handleInvitationResponse(invitationId, 'accept');
  // }

  // Future<bool> rejectInvitation(String invitationId) async {
  //   return _handleInvitationResponse(invitationId, 'reject');
  // }

  // Future<bool> _handleInvitationResponse(String invitationId, String action) async {
  //   try {
  //     final currentUser = _auth.currentUser;
  //     if (currentUser == null) throw Exception('User not logged in');

  //     try {
  //       final response = await http.post(
  //         Uri.parse('$_baseUrl/api/handle-invitation'),
  //         headers: {'Content-Type': 'application/json'},
  //         body: json.encode({
  //           'invitationId': invitationId,
  //           'action': action,
  //           'currentUserId': currentUser.uid,
  //         }),
  //       ).timeout(Duration(seconds: 10));

  //       if (response.statusCode == 200) {
  //         return true;
  //       } else {
  //         final errorData = json.decode(response.body);
  //         throw Exception(errorData['error'] ?? 'Lỗi không xác định');
  //       }
  //     } on http.ClientException catch (e) {
  //       // 🎯 FALLBACK: Sử dụng Firebase trực tiếp
  //       print('⚠️ Server unavailable, using Firebase fallback: $e');
  //       return await _handleInvitationResponseViaFirebase(invitationId, action);
  //     }
  //   } catch (e) {
  //     print('Error handling invitation: $e');
  //     rethrow;
  //   }
  // }

  // // 🎯 FALLBACK: Xử lý invitation response qua Firebase
  // Future<bool> _handleInvitationResponseViaFirebase(String invitationId, String action) async {
  //   try {
  //     final status = action == 'accept' ? 'accepted' : 'rejected';
      
  //     // Lấy thông tin invitation
  //     final invitationDoc = await _db.collection('invitations').doc(invitationId).get();
  //     if (!invitationDoc.exists) throw Exception('Invitation not found');

  //     final invitationData = invitationDoc.data() as Map<String, dynamic>;
  //     final invitation = InvitationNotificationModel.fromMap(invitationData, invitationDoc.id);

  //     // Kiểm tra quyền
  //     if (invitation.toUserId != _auth.currentUser?.uid) {
  //       throw Exception('Unauthorized to update this invitation');
  //     }

  //     // Cập nhật status trong invitations collection
  //     await _db.collection('invitations').doc(invitationId).update({
  //       'status': status,
  //       'timestamp': DateTime.now().millisecondsSinceEpoch,
  //     });

  //     // Cập nhật trong user notifications của người nhận
  //     await _db
  //         .collection('users')
  //         .doc(invitation.toUserId)
  //         .collection('Notifications')
  //         .doc(invitationId)
  //         .update({
  //       'status': status,
  //       'isRead': true,
  //       'timestamp': DateTime.now().millisecondsSinceEpoch,
  //     });

  //     // Nếu accept, thêm user vào home
  //     if (status == 'accepted') {
  //       await _addUserToHome(invitation.homeId, invitation.toUserId);
  //     }

  //     // Tạo response notification cho người gửi
  //     await _notifyInviterAboutResponse(invitation, status);

  //     return true;
  //   } catch (e) {
  //     print('Error handling invitation via Firebase: $e');
  //     rethrow;
  //   }
  // }

  // // Thêm user vào home
  // Future<void> _addUserToHome(String homeId, String userId) async {
  //   await _db.collection('homes').doc(homeId).update({
  //     'members': FieldValue.arrayUnion([userId]),
  //   });
  //   print('✅ User $userId added to home $homeId');
  // }

  // // Thông báo cho người gửi về phản hồi
  // Future<void> _notifyInviterAboutResponse(
  //     InvitationNotificationModel originalInvitation, String status) async {
  //   try {
  //     final timestamp = DateTime.now().millisecondsSinceEpoch;
  //     final responseNotificationId = 'response_${originalInvitation.invitationId}';

  //     final responseNotification = InvitationNotificationModel(
  //       id: responseNotificationId,
  //       invitationId: originalInvitation.invitationId,
  //       fromUserId: originalInvitation.toUserId,
  //       fromUserName: 'Hệ thống',
  //       fromUserEmail: originalInvitation.toUserEmail,
  //       toUserEmail: originalInvitation.fromUserEmail,
  //       toUserId: originalInvitation.fromUserId,
  //       homeId: originalInvitation.homeId,
  //       homeName: originalInvitation.homeName,
  //       status: status,
  //       type: 'invitation_response',
  //       message: status == 'accepted'
  //           ? '${originalInvitation.toUserEmail} đã chấp nhận lời mời tham gia ${originalInvitation.homeName}'
  //           : '${originalInvitation.toUserEmail} đã từ chối lời mời tham gia ${originalInvitation.homeName}',
  //       isRead: false,
  //       timestamp: timestamp,
  //       createdAt: DateTime.now(),
  //     );

  //     // Lưu notification cho người gửi
  //     await _db
  //         .collection('users')
  //         .doc(originalInvitation.fromUserId)
  //         .collection('Notifications')
  //         .doc(responseNotificationId)
  //         .set(responseNotification.toMap());

  //     print('✅ Response notification created for inviter: ${originalInvitation.fromUserId}');
  //   } catch (e) {
  //     print('Error notifying inviter: $e');
  //   }
  // }

  // // Lấy danh sách invitations
  // Stream<List<InvitationNotificationModel>> getInvitationsStream() {
  //   final currentUser = _auth.currentUser;
  //   if (currentUser == null) return const Stream.empty();

  //   return _db
  //       .collection('users')
  //       .doc(currentUser.uid)
  //       .collection('Notifications')
  //       .where('type', whereIn: ['invitation', 'invitation_response'])
  //       .orderBy('timestamp', descending: true)
  //       .snapshots()
  //       .map((querySnapshot) {
  //     return querySnapshot.docs.map((doc) {
  //       return InvitationNotificationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  //     }).toList();
  //   });
  // }

  // // 🎯 Hàm mới: Lấy số lượng invitations chưa đọc
  // Stream<int> getUnreadInvitationsCount() {
  //   final currentUser = _auth.currentUser;
  //   if (currentUser == null) return Stream.value(0);

  //   return _db
  //       .collection('users')
  //       .doc(currentUser.uid)
  //       .collection('Notifications')
  //       .where('type', whereIn: ['invitation', 'invitation_response'])
  //       .where('isRead', isEqualTo: false)
  //       .snapshots()
  //       .map((querySnapshot) => querySnapshot.docs.length);
  // }

  // // 🎯 Hàm mới: Đánh dấu invitation đã đọc
  // Future<void> markInvitationAsRead(String invitationId) async {
  //   final currentUser = _auth.currentUser;
  //   if (currentUser == null) return;

  //   await _db
  //       .collection('users')
  //       .doc(currentUser.uid)
  //       .collection('Notifications')
  //       .doc(invitationId)
  //       .update({'isRead': true});
  // }
}