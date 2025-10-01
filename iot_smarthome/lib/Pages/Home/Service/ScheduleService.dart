import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Controllers/DeviceController.dart';

class ScheduleService {
  static final deviceController = Get.put(DeviceController());
  static void start(String homeId, String roomId) {
    const checkInterval = Duration(seconds: 10);

    Timer.periodic(checkInterval, (timer) async {
      final now = DateTime.now().toUtc();

      final snap = await FirebaseFirestore.instance
          .collection("Homes/$homeId/Rooms/$roomId/schedules")
          .where("done", isEqualTo: false)
          .get();

      for (var doc in snap.docs) {
        final data = doc.data();
        final deviceId = data["deviceId"];
        final status = data["status"];
        final scheduleTime = (data["time"] as Timestamp).toDate();

        final diffSeconds = now.difference(scheduleTime).inSeconds;

        // Nếu lịch hẹn trong vòng 10 giây kể từ mốc hẹn, thực hiện
        if (diffSeconds >= 0 && diffSeconds <= checkInterval.inSeconds) {
          // Cập nhật trạng thái thiết bị
          await deviceController.updateStatus(homeId, roomId, deviceId, {
            "status":status
          });

          // Đánh dấu schedule đã thực hiện
          await doc.reference.update({"done": true});
        }
      }
    });
  }
}
