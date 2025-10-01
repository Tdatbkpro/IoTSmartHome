const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

/**
 * Khi có schedule mới được tạo trong Firestore,
 * Cloud Function sẽ chờ đến đúng giờ rồi cập nhật status của thiết bị trong Realtime Database.
 */
exports.onScheduleCreate = functions.firestore
  .document("schedules/{scheduleId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const { homeId, roomId, deviceId, action, time } = data;

    if (!homeId || !roomId || !deviceId || action === undefined || !time) {
      console.error("❌ Schedule thiếu dữ liệu:", data);
      return null;
    }

    const scheduleTime = time.toDate().getTime();
    const now = Date.now();
    const delay = scheduleTime - now;

    if (delay <= 0) {
      console.log("⏰ Thời gian đã qua, bỏ qua");
      return null;
    }

    console.log(`⏳ Sẽ cập nhật device ${deviceId} sau ${delay}ms`);

    // Lưu ý: setTimeout chỉ thích hợp cho lịch ngắn (<= 9 phút)
    setTimeout(async () => {
      try {
        await admin
          .database()
          .ref(`Status/${homeId}/${roomId}/${deviceId}`)
          .update({ status: action });
        console.log(`✅ Đã update device ${deviceId} = ${action}`);
      } catch (e) {
        console.error("❌ Lỗi khi update:", e);
      }
    }, delay);

    return null;
  });
