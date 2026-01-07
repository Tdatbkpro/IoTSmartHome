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
  final String _baseUrl = "https://92d97c3390eb.ngrok-free.app"; // Thay bằng server URL thực tế
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

}