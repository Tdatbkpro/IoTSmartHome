import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Models/DeviceStatusModel.dart';
import 'package:iot_smarthome/Models/HomeModel.dart';
import 'package:iot_smarthome/Models/RoomModel.dart';
import 'package:uuid/uuid.dart';

class DeviceController extends GetxController {
  final firestore = FirebaseFirestore.instance;
  final realtime = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: "https://iotsmarthome-187be-default-rtdb.asia-southeast1.firebasedatabase.app/",
  );

  final uuid = const Uuid();

  RxList<HomeModel> homes = <HomeModel>[].obs;

  /// Stream Homes + Rooms realtime
  void streamHomes(String userId) {
    firestore
        .collection("Homes")
        .where("ownerId", isEqualTo: userId)
        .snapshots()
        .listen((snap) async {
      List<HomeModel> tempHomes = [];
      for (var doc in snap.docs) {
        final home = HomeModel.fromMap(doc.id, doc.data());

        // Stream rooms cho từng home
        final roomSnap = await firestore.collection("Homes/${home.id}/Rooms").get();
        final rooms = roomSnap.docs
            .map((r) => RoomModel.fromMap(r.id, r.data()))
            .toList();

        tempHomes.add(HomeModel(
            id: home.id, name: home.name, ownerId: home.ownerId, rooms: rooms,image: home.image));
      }
      homes.value = tempHomes;
    });
  }

  /// Thêm home mới
  Future<void> addHome(HomeModel home) async {
    final homeId = home.id.isEmpty ? uuid.v4() : home.id;
    await firestore.collection("Homes").doc(homeId).set(home.toMap()..['id'] = homeId);
    await streamRooms(home.ownerId);
  }

    /// Cập nhật thông tin home (bao gồm cả image)
    Future<void> updateHome(HomeModel home) async {
      try {
        await firestore.collection("Homes").doc(home.id).update(home.toMap());
        
        // Sau khi update thì load lại danh sách homes
        streamHomes(home.ownerId);
      } catch (e) {
        print("Error updating home: $e");
      }
    }



  /// Xóa home và tất cả rooms + devices bên trong
 Future<void> deleteHome(String homeId) async {
  // Lấy tất cả rooms của home
  final roomsSnap = await firestore.collection("Homes/$homeId/Rooms").get();

  for (var roomDoc in roomsSnap.docs) {
    final roomId = roomDoc.id;

    // Lấy tất cả devices trong room
    final devicesSnap = await firestore
        .collection("Homes/$homeId/Rooms/$roomId/devices")
        .get();

    for (var deviceDoc in devicesSnap.docs) {
      final deviceId = deviceDoc.id;

      // Xóa status trong Realtime Database
      await realtime.ref("Status/$homeId/$roomId/$deviceId").remove();

      // Xóa device trong Firestore
      await firestore
          .collection("Homes/$homeId/Rooms/$roomId/devices")
          .doc(deviceId)
          .delete();
    }

    // Xóa room
    await firestore.collection("Homes/$homeId/Rooms").doc(roomId).delete();
  }

  // Xóa home
  await firestore.collection("Homes").doc(homeId).delete();

  // Cập nhật RxList homes
  homes.removeWhere((h) => h.id == homeId);
}



  // ==================== ROOMS ====================
  Stream<List<RoomModel>> streamRooms(String homeId) {
  return firestore.collection("Homes/$homeId/Rooms").snapshots().map(
    (snap) => snap.docs
        .map((doc) => RoomModel.fromMap(doc.id, doc.data()))
        .toList(),
  );
}


  Future<void> addRoom(String homeId, RoomModel room) async {
    final roomId = room.id.isEmpty ? uuid.v4() : room.id;
    await firestore.collection("Homes/$homeId/Rooms").doc(roomId).set(room.toMap()..['id'] = roomId);
  }

  Future<void> updateRoom(String homeId, RoomModel room) async {
    await firestore.collection("Homes/$homeId/Rooms").doc(room.id).update(room.toMap());
  }

  Future<void> deleteRoom(String homeId, String roomId) async {
    final devicesSnap = await firestore.collection("Homes/$homeId/Rooms/$roomId/devices").get();

    for (var doc in devicesSnap.docs) {
      await realtime.ref("Status/$roomId/${doc.id}").remove();
      await firestore.doc("Homes/$homeId/Rooms/$roomId/devices/${doc.id}").delete();
    }

    await firestore.collection("Homes/$homeId/Rooms").doc(roomId).delete();
  }

  // ==================== DEVICES ====================
  Stream<List<Device>> streamDevices(String homeId, String roomId) {
    return firestore
        .collection("Homes/$homeId/Rooms/$roomId/devices")
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Device.fromMap(doc.id, doc.data(), roomId))
            .toList());
  }

  Future<void> addDevice(String homeId, String roomId, Device device) async {
    final deviceId = device.id.isEmpty ? uuid.v4() : device.id;
    await firestore
        .collection("Homes/$homeId/Rooms/$roomId/devices")
        .doc(deviceId)
        .set(device.toMap()..['id'] = deviceId);
  }

  Future<void> updateDevice(String homeId, String roomId, Device device) async {
    await firestore
        .collection("Homes/$homeId/Rooms/$roomId/devices")
        .doc(device.id)
        .update(device.toMap());
  }

  Future<void> deleteDevice(String homeId, String roomId, String deviceId) async {
    await firestore.doc("Homes/$homeId/Rooms/$roomId/devices/$deviceId").delete();
    await realtime.ref("Status/$roomId/$deviceId").remove();
  }

  // ==================== STATUS ====================
  Stream<DeviceStatus> getDeviceStatus(String homeId, String roomId, String deviceId) {
  return realtime.ref("Status/$homeId/$roomId/$deviceId").onValue.map((event) {
    if (event.snapshot.value != null) {
      return DeviceStatus.fromMap(Map<String, dynamic>.from(event.snapshot.value as Map));
    }
    return DeviceStatus(status: false);
  });
}


  Future<void> updateStatus(
      String homeId, String roomId, String deviceId, Map<String, dynamic> data) async {
    await realtime.ref("Status/$homeId/$roomId/$deviceId").update(data);
  }
  Future<void> addSchedule({
  required String homeId,
  required String roomId,
  required String deviceId,
  required int action, // 1 = bật, 0 = tắt
  required DateTime time,
}) async {
  await firestore
  .collection("Homes/$homeId/Rooms/$roomId/schedules")
  .add({
    "deviceId": deviceId,
    "status": action,
    "time": Timestamp.fromDate(time),
    "done": false,
    "createdAt": FieldValue.serverTimestamp(),
  });

}

}

