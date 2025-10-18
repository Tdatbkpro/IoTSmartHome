import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Models/NotificationModel.dart';

class NotificationController extends GetxController {
  final auth = FirebaseAuth.instance.currentUser;
  final db = FirebaseFirestore.instance;
  Stream<List<NotificationModel>> getNotificationStream() {
    if (auth == null) {
      return const Stream.empty();
    }

    return db.collection("users").
      doc(auth!.uid).
      collection("Notifications").
      orderBy("timestamp", descending: true).
      snapshots().
      map((querySnapshot) {
        return querySnapshot.docs.map((doc) {
          return NotificationModel.fromMap(doc.data(), doc.id);
        }).toList();
      });
  }

  Future<void> markAsRead(String notificationId) async {
    if (auth == null) {
      return;
    }

    await db.collection("users").
      doc(auth!.uid).
      collection("Notifications").
      doc(notificationId).
      update({'isRead': true});
  }

  Future<void> deleteNotification(String notificationId) async {
    if (auth == null) {
      return;
    }

    await db.collection("users").
      doc(auth!.uid).
      collection("Notifications").
      doc(notificationId).
      delete();
  }

  Future<void> restoreNotification(String notificationId, NotificationModel notification) async {
    if (auth == null) {
      return;
    }

    await db.collection("users").
      doc(auth!.uid).
      collection("Notifications").
      doc(notificationId).
      set(notification.toMap());
  }
  
}