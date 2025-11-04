import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Config/Icons.dart';
import 'package:iot_smarthome/Models/DeviceStatusModel.dart';
import 'package:iot_smarthome/Models/HomeModel.dart';
import 'package:iot_smarthome/Models/RoomModel.dart';
import 'package:iot_smarthome/Pages/Home/Dialog.dart';
import 'package:uuid/uuid.dart';
import 'package:rxdart/rxdart.dart' as rxdart;

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

      // 🔹 Lấy danh sách room
      final roomSnap = await firestore.collection("Homes/${home.id}/Rooms").get();

      // 🔹 Với mỗi room, lấy thêm devices
      final rooms = await Future.wait(roomSnap.docs.map((r) async {
        final room = RoomModel.fromMap(r.id, r.data());

        final deviceSnap = await firestore
            .collection("Homes/${home.id}/Rooms/${r.id}/devices")
            .get();

        final devices = deviceSnap.docs
            .map((d) => Device.fromMap(d.id, d.data(), r.id))
            .toList();

        // Trả về room có devices
        return room.copyWithDevices(devices);
      }));

      tempHomes.add(HomeModel(
        id: home.id,
        members: home.members,
        name: home.name,
        ownerId: home.ownerId,
        image: home.image,
        location: home.location,
        rooms: rooms,
      ));
    }

    homes.value = tempHomes;
  });
}

  Stream<int> getTotalDevicesCountStream(String homeId) {
  return FirebaseFirestore.instance
      .collection("Homes/$homeId/Rooms")
      .snapshots()
      .asyncMap((roomsSnap) async {
    int totalDevices = 0;
    
    for (final roomDoc in roomsSnap.docs) {
      final devicesCount = await FirebaseFirestore.instance
          .collection("Homes/$homeId/Rooms/${roomDoc.id}/devices")
          .count()
          .get();
      
      totalDevices += devicesCount.count ?? 0;
    }
    
    return totalDevices;
  });
}

  /// Thêm home mới
  Future<void> addHome(HomeModel home) async {
    final homeId = home.id.isEmpty ? uuid.v4() : home.id;
    await firestore.collection("Homes").doc(homeId).set(home.toMap()..['id'] = homeId);
    streamRooms(home.ownerId);
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

  /// Stream trả về danh sách các phòng mà user được phép truy cập (bao gồm cả devices)
Stream<List<RoomModel>> streamSharedRooms() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);

  final firestore = FirebaseFirestore.instance;

  return firestore.collectionGroup('Rooms').snapshots().asyncMap((snapshot) async {
    final rooms = <RoomModel>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final room = RoomModel.fromMap(doc.id, data);
      if (room.allowedUsers.contains(uid)) {
        final devicesSnap = await doc.reference.collection('devices').get();
        final devices = devicesSnap.docs
            .map((d) => Device.fromMap(d.id, d.data(), room.id))
            .toList();
        rooms.add(room.copyWithDevices(devices));
      }
    }

    return rooms;
  });
}

 Stream<List<RoomModel>> streamRooms(String homeId) {
    final roomsRef = firestore.collection('Homes').doc(homeId).collection('Rooms');

    return roomsRef.snapshots().switchMap((roomSnap) {
      final roomStreams = roomSnap.docs.map((roomDoc) {
        final room = RoomModel.fromMap(roomDoc.id, roomDoc.data());

        final devicesStream = roomDoc.reference
            .collection('devices')
            .snapshots()
            .map((deviceSnap) => deviceSnap.docs
                .map((d) => Device.fromMap(d.id, d.data(), roomDoc.id)) // ✅ thêm roomId
                .toList());

        return devicesStream.map((devices) => room.copyWithDevices(devices));
      }).toList();

      return rxdart.Rx.combineLatestList(roomStreams);
    });
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
      await realtime.ref("Status/$homeId/$roomId/${doc.id}").remove();
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

        void handleVoiceCommand(
        BuildContext context,
        String homeId,
        String roomId,
        String command,
        void Function(List<Device>) onConfirm, // ✅ callback trả về list
      ) async {
        final devices = await streamDevices(homeId, roomId).first;
        final cmd = command.toLowerCase();

        // Ưu tiên tìm đúng cả tên + loại
        final exactMatch = devices.firstWhere(
          (d) {
            final name = (d.name ?? "").toLowerCase();
            final type = (d.type ?? "").toLowerCase();
            return cmd.contains(name) && cmd.contains(type);
          },
          orElse: () => Device(id: "", name: null, type: null, roomId: roomId),
        );

        List<Device> matchedDevices = [];

        if (exactMatch.id.isNotEmpty) {
          matchedDevices = [exactMatch];
        } else {
          matchedDevices = devices.where((d) {
            final type = (d.type ?? "").toLowerCase();
            return cmd.contains(type);
          }).toList();
        }

        // ✅ show dialog cho phép chọn
        _showListDevice(context, matchedDevices, onConfirm);
      }

        void _showListDevice(
        BuildContext context,
        List<Device> listDevice,
        void Function(List<Device>) onConfirm,
      ) {
        if (listDevice.isEmpty) {
          DialogUtils.showConfirmDialog(
            context,
            "Không tìm thấy",
            const Text("❌ Không có thiết bị nào phù hợp!"),
            () {},
          );
          return;
        }

        // giữ trạng thái thiết bị được chọn
        final selected = <Device>{};

        showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text("Chọn thiết bị để điều khiển"),
              content: SizedBox(
                width: double.maxFinite,
                height: 200,
                child: StatefulBuilder(
                  builder: (ctx, setState) {
                    return ListView.builder(
                      itemCount: listDevice.length,
                      itemBuilder: (context, index) {
                        final device = listDevice[index];
                        final isSelected = selected.contains(device);

                        return Row(
                          children: [
                            CircleAvatar(
                              maxRadius: 18,
                              backgroundColor: Colors.transparent, // nền trong suốt
                              child: Image.asset(
                                getDeviceIcon(device.type!, false) ?? "",
                                fit: BoxFit.contain,
                              ),
                            ),

                            Expanded(
                              child: CheckboxListTile(
                                value: isSelected,
                                checkColor: Colors.amberAccent,
                                title: Text(device.name ?? "Unknown", style: Theme.of(context).textTheme.bodyLarge,),
                                dense: true,
                                autofocus: true,
                                hoverColor: Colors.blueAccent,
                                subtitle: Text(device.type ?? "Unknown type", style: Theme.of(context).textTheme.bodyMedium,),
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      selected.add(device);
                                    } else {
                                      selected.remove(device);
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Hủy"),
                  onPressed: () => Navigator.pop(ctx),
                ),
                ElevatedButton(
                  child: const Text("Xác nhận"),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onConfirm(selected.toList()); // ✅ trả về list thiết bị được chọn
                  },
                ),
              ],
            );
          },
        );
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
    await realtime.ref("Status/$homeId/$roomId/$deviceId").remove();
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
      String homeId, String roomId, String deviceId, DeviceStatus deviceStatus) async {
    await realtime.ref("Status/$homeId/$roomId/$deviceId").update(
      deviceStatus.toMap()
    );
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
    "status": action == 1 ? true: false,
    "time": Timestamp.fromDate(time),
    "done": false,
    "createdAt": FieldValue.serverTimestamp(),
  });

}

}

