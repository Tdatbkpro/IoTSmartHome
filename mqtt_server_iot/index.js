const mqtt = require("mqtt");
const admin = require("firebase-admin");
const DeviceStatus = require("./device_status.model.js");
const serviceAccount = require("./serverAccountIoTSmarthome.json");

// ========== FIREBASE INIT ==========
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://iotsmarthome-187be-default-rtdb.asia-southeast1.firebasedatabase.app",
});

const db = admin.database();
const firestore = admin.firestore()

// ========== MQTT CONNECT ==========
const client = mqtt.connect({
  host: "f77821b7736f49aa84073592a70eab84.s1.eu.hivemq.cloud",
  port: 8883,
  protocol: "mqtts",
  username: "datbkpro",
  password: "Tqdat22062004@",
    clientId: "nodejs_iot_server_01", // Bắt buộc nếu clean: false
  clean: false,
});

// ========== MQTT EVENT ==========
client.on("connect",async  ()  =>  {
  console.log("✅ Connected to HiveMQ Cloud");
  getInfoDevice();
  

//   const usersRef = firestore.collection("users");
// const userId = "Qk5UlvH5VHZBrePCZ271tEmxUld2"; // Lấy từ dữ liệu home/device
// const homeId = "494f5ca4-c8a2-4872-8bbd-15a27fc720c6";
// const roomId = "ade07324-9411-41c4-b8b3-dbeae131ebf7";
// const deviceId = "8d8e3b8d-5de5-4fbf-97ad-6ea6039e00b9";
// const deviceType = "Light";
// const deviceName = "Đèn phòng khách";
// const messageData = {
//   homeId,
//   roomId,
//   deviceId,
//   deviceName,
//   deviceType,
//   type: "Error",
//   message: "Đèn bị lỗi!",
//   isRead: false,
//   createdAt: admin.firestore.FieldValue.serverTimestamp(),
//   timestamp: Date.now(),
// };

// // Lưu vào Firestore
// await usersRef.doc(userId).collection("Notifications").add(messageData);

// // Gửi FCM
// await admin.messaging().send({
//   notification: {
//     title: "🚨 Cảnh báo chuyển động!",
//     body: messageData.message,
//   },
//   topic: "alert_pir",
//   android: { priority: "high" },
//   data: {
//     type: messageData.type,
//     homeId,
//     roomId,
//     deviceId,
//   },
// });

   startFirebaseStream()
});


client.on("message", async (topic, message) => {
  const payload = message.toString().trim();
  console.log("DEBUG MQTT received:", topic, payload);

  if (!payload) return;

  let data;
  try {
    data = JSON.parse(payload);
  } catch (err) {
    console.error(`❌ Invalid JSON from ${topic}:`, payload);
    return;
  }

  // ---------- ALERT PIR ----------
  if (topic.startsWith("alert/")) {
    const { homeId, roomId, deviceId, userId, type, status } = data;
    if (!userId) return;

    try {
      const usersRef = firestore.collection("users");
      const messageData = {
        homeId,
        roomId,
        deviceId,
        deviceName: "Thiết bị",
        deviceType: "Security",
        type: type || "pir_alert",
        message: status === "active" ? "PIR phát hiện người" : "PIR trạng thái khác",
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        timestamp: Date.now(),
      };

      await usersRef.doc(userId).collection("Notifications").add(messageData);

      await admin.messaging().send({
        notification: { title: "🚨 Cảnh báo PIR!", body: messageData.message },
        topic: "alert_pir",
        android: { priority: "high" },
        data: { type: messageData.type, homeId, roomId, deviceId },
      });

      console.log(`✅ Alert saved & FCM sent: ${topic}`);
    } catch (err) {
      console.error("🔥 Error handling alert:", err);
    }

    return;
  }

  // ---------- STATUS DEVICE ----------
  if (topic.startsWith("Status/")) {
    try {
      const statusDevice = DeviceStatus.fromObject(data);
      const [_, homeId, roomId, deviceId] = topic.split("/");

      const ref = db.ref(`Status/${homeId}/${roomId}/${deviceId}`);
      await ref.update(statusDevice.toJSON());
      console.log(`✅ Updated Firebase: ${topic}`);
    } catch (err) {
      console.error("🔥 Error updating device status:", err);
    }
  }
});

// ---------- ERROR HANDLER ----------
client.on("error", (err) => {
  console.error("❌ MQTT Error:", err);
});

//
async function getInfoDevice() {
  console.log("📡 Listening Firestore devices in realtime...");

  const homesRef = firestore.collection("Homes");

  // 🔄 Lắng nghe tất cả Home
  homesRef.onSnapshot(async (homesSnap) => {
    for (const homeDoc of homesSnap.docs) {
      const homeId = homeDoc.id;
      const owerHomeId = homeDoc.data().ownerId;
      const roomsRef = firestore.collection(`Homes/${homeId}/Rooms`);

      // 🔄 Lắng nghe tất cả Room trong Home
      roomsRef.onSnapshot(async (roomsSnap) => {
        for (const roomDoc of roomsSnap.docs) {
          const roomId = roomDoc.id;
          const devicesRef = firestore.collection(`Homes/${homeId}/Rooms/${roomId}/devices`);

          // 🔄 Lắng nghe tất cả devices trong Room
          devicesRef.onSnapshot(async (devicesSnap) => {
            if (devicesSnap.empty) return;

            devicesSnap.forEach(async (doc) => {
              const deviceId = doc.id;
              const data = doc.data();
              const type = data.type || "unknown";
              const name = data.name || "unnamed";
              
              const payload = {owerHomeId, homeId, roomId, deviceId };
              var topic = "";
              console.log("DEBUG Device found:", name, type);
              if (type == "Security") {
                topic = `alert/${homeId}/${roomId}/${deviceId}`;
              } else {
                topic = `Status/${homeId}/${roomId}/${deviceId}`
              }
              const getDeviceTopic = `getDevice/${type}/${name}`;
              // 🟢 Publish device info để ESP nhận
              client.publish(getDeviceTopic, JSON.stringify(payload), { qos: 1, retain : true });
              console.log(`📤 Published Firestore device: ${name} (${type})`);

              // 🟣 Đăng ký topic Status nếu chưa có
              client.subscribe(topic, { qos: 1 }, (err) => {
                if (err) {
                  console.error(`❌ Failed to subscribe ${topic}:`, err.message);
                  
                } else {
                  startFirebaseStream();
                  console.log(`✅ Subscribed to ${topic}`);
                }
              });
            });
          });
        }
      });
    }
  });
}


// ========== STREAM FIREBASE REALTIME ==========
function startFirebaseStream() {
  console.log("📡 Listening for Firebase realtime changes (per device)...");

  const homesRef = db.ref("Status");

  homesRef.once("value",  (homesSnap) => {
    homesSnap.forEach((homeSnap) => {
      const homeId = homeSnap.key;


      homeSnap.forEach((roomSnap) => {
        const roomId = roomSnap.key;

        roomSnap.forEach((deviceSnap) => {
          const deviceId = deviceSnap.key;
          const deviceRef = db.ref(`Status/${homeId}/${roomId}/${deviceId}`);

          // ✅ Lắng nghe riêng từng thiết bị
          deviceRef.on("value", (snap) => {
            const deviceData = snap.val();

            // ⚠️ Nếu thiết bị bị xóa (node = null)
            if (deviceData === null) {
              console.log(`🛑 Device ${homeId}/${roomId}/${deviceId} deleted -> stop publishing`);
              // Ngắt luôn listener của thiết bị đó
              deviceRef.off("value");
              return;
            }

            const topic = `${homeId}/${roomId}/${deviceId}`;
            client.publish(topic, JSON.stringify(deviceData), { qos: 1, retain: true });
            console.log(`📤 Published device changed: ${topic}`);
          });
        });
      });
    });
  });

  // Khi có thêm home mới
  homesRef.on("child_added", (homeSnap) => {
    const homeId = homeSnap.key;
    console.log(`🏠 New home detected: ${homeId}`);

    const roomsRef = db.ref(`Status/${homeId}`);

    roomsRef.on("child_added", (roomSnap) => {
      const roomId = roomSnap.key;
      console.log(`🛏️ New room detected: ${homeId}/${roomId}`);

      const devicesRef = db.ref(`Status/${homeId}/${roomId}`);

      devicesRef.on("child_added", (deviceSnap) => {
        const deviceId = deviceSnap.key;
        console.log(`💡 Listening new device: ${homeId}/${roomId}/${deviceId}`);

        const deviceRef = db.ref(`Status/${homeId}/${roomId}/${deviceId}`);
        deviceRef.on("value", (snap) => {
          const deviceData = snap.val();

          // ⚠️ Nếu bị xóa => ngắt publish + tắt listener
          if (deviceData === null) {
            console.log(`🛑 Device ${homeId}/${roomId}/${deviceId} deleted -> stop publishing`);
            deviceRef.off("value");
            return;
          }

          const topic = `${homeId}/${roomId}/${deviceId}`;
          client.publish(topic, JSON.stringify(deviceData), { qos: 1, retain: true });
          console.log(`📤 Published device changed: ${topic}`);
        });
      });

      // Khi có thiết bị bị xóa
      devicesRef.on("child_removed", (deviceSnap) => {
        const deviceId = deviceSnap.key;
        console.log(`🗑️ Device removed: ${homeId}/${roomId}/${deviceId}`);
        db.ref(`Status/${homeId}/${roomId}/${deviceId}`).off("value");
      });
    });
  });
}


// ========== XỬ LÝ LỖI ==========
client.on("error", (err) => {
  console.error("❌ MQTT Connection Error:", err);
});
