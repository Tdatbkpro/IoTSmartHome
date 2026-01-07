import mqtt from "mqtt";
import admin from "firebase-admin";
import DeviceStatus from "./device_status.model.js";
import InfluxData from './influx_data.js';

// Dùng createRequire để import JSON
import { createRequire } from "module";
const require = createRequire(import.meta.url);
const serviceAccount = require("./serverAccountIoTSmarthome.json");

// ========== FIREBASE INIT ==========
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://iotsmarthome-187be-default-rtdb.asia-southeast1.firebasedatabase.app",
});

const db = admin.database();
const firestore = admin.firestore()
let influxData = new InfluxData()

// ========== MQTT CONNECT ==========
const client = mqtt.connect({
  host: "h2bad201.ala.asia-southeast1.emqxsl.com",
  port: 8883,
  protocol: "mqtts",
  username: "iotsmarthome",
  password: "Tqdat22062004@",
  clientId: "nodejs_iot_server_" + Math.random().toString(16).substring(2, 8),
  clean: true,
});

// ========== MQTT EVENT ==========
client.on("connect", async () => {
  console.log("✅ Connected to HiveMQ Cloud");
  getInfoDevice();
  startFirebaseStream();
});

client.on("message", async (topic, message) => {
  const payload = message.toString().trim();
  console.log("📩 MQTT received:", topic, payload);

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
    console.log("🚨 Alert received:", data);
    const { type, deviceType, deviceName, localDevice, userId, message: alertMessage } = data;
    const [, homeId, roomId, deviceId] = topic.split("/");

    if (!userId) {
      console.error("❌ Missing userId in alert data");
      return;
    }

    try {
      const usersRef = firestore.collection("users");
      
      // Tạo notification theo unified model
      const messageData = {
        type: 'deviceAlert',
        homeId,
        roomId,
        deviceId,
        locationDevice: localDevice || "unknown",
        deviceName: deviceName || deviceType + " Sensor",
        deviceType: deviceType || "Unknown",
        message: alertMessage || `${deviceType} phát hiện sự kiện`,
        isProcessed: false,
        isRead: false,
        timestamp: Date.now(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      var deviceStatus =false;
      // Lưu notification vào Firestore với unified model
      const deviceStatusRef = await db.ref(`Status/${homeId}/${roomId}/${deviceId}`);
      deviceStatusRef.on("value", async (snap) => {
        const deviceData = snap.val();
        if (DeviceStatus.fromObject(deviceData).status === true) {
          // Ghi dữ liệu vào InfluxDB khi thiết bị bật
          deviceStatus = true;
        }
      });
      if (deviceStatus) {
          // 🎯 LƯU VÀO FIRESTORE VÀ LẤY DOCUMENT ID
          const notificationDoc = await usersRef.doc(userId).collection("Notifications").add(messageData);
          const documentId = notificationDoc.id; // 🎯 AUTO-GENERATED ID
          console.log(` Alert saved to Firestore with ID: ${documentId}`);
          
          // Gửi FCM notification
          let title = " Cảnh báo thiết bị!";
          let body = alertMessage || `Thiết bị ${deviceName || deviceType} phát hiện sự kiện`;
          
          if (deviceType === "Trash") {
            title = " Cảnh báo thùng rác!";
            body = alertMessage || "Thùng rác thông minh phát hiện sự kiện";
          }

          const fcmMessage = {
            notification: {
              title: title,
              body: body,
            },
            android: {
              priority: "high",
              notification: {
                sound: "default",
                channelId: "alert_channel_v2",
                priority: "max",
                vibrateTimingsMillis: [0, 500, 500, 500],
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: "default",
                  badge: 1,
                  contentAvailable: true,
                },
              },
            },
            data: {
              type: 'deviceAlert',
              homeId: homeId,
              roomId: roomId,
              deviceId: deviceId,
              deviceName: deviceName || deviceType + " Sensor",
              deviceType: deviceType || "Unknown",
              locationDevice: localDevice || "unknown",
              message: alertMessage || `${deviceType} phát hiện sự kiện`,
              timestamp: String(Date.now()),
              userId: userId,
              click_action: "FLUTTER_NOTIFICATION_CLICK",
              firestoreId: documentId, //  THÊM FIRESTORE ID VÀO PAYLOAD
              docId: documentId, //  ALIAS
            },
            topic: `alert_${userId}`,
          };

          const response = await admin.messaging().send(fcmMessage);
          console.log(`Alert saved & FCM sent to user: ${userId}`, response);
        }

    } catch (err) {
      console.error(" Error handling alert:", err);
    }
    return;
  }

  // ---------- STATUS DEVICE ----------
  if (topic.startsWith("Status/")) {
    try {
      const statusDevice = DeviceStatus.fromObject(data);
      const [, homeId, roomId, deviceId] = topic.split("/");

      // ========== GHI DỮ LIỆU VÀO INFLUXDB ==========
      // Ghi dữ liệu DHT vào InfluxDB
      if (data.temperature != null && data.humidity != null) {
        try {
          await influxData.writeSensorData("dht", data.temperature, data.humidity);
          console.log(`📊 DHT data saved to InfluxDB: ${data.temperature}°C, ${data.humidity}%`);
        } catch (err) {
          console.error("⚠️ Write DHT to InfluxDB failed:", err);
        }
      }
      // Cập nhật Firebase Realtime Database
      const ref = db.ref(`Status/${homeId}/${roomId}/${deviceId}`);
      await ref.update(statusDevice.toJSON());
      console.log(`Updated Firebase: ${topic}`);
    } catch (err) {
      console.error(" Error updating device status:", err);
    }
  }
});

async function getInfoDevice() {
  console.log(" Listening Firestore devices in realtime...");

  const homesRef = firestore.collection("Homes");

  homesRef.onSnapshot(async (homesSnap) => {
    for (const homeDoc of homesSnap.docs) {
      const homeId = homeDoc.id;
      const homeName = homeDoc.data().name || "unnamed";
      const ownerHomeId = homeDoc.data().ownerId;
      const roomsRef = firestore.collection(`Homes/${homeId}/Rooms`);

      roomsRef.onSnapshot(async (roomsSnap) => {
        for (const roomDoc of roomsSnap.docs) {
          const roomName = roomDoc.data().name || "unnamed";
          const roomId = roomDoc.id;
          const devicesRef = firestore.collection(`Homes/${homeId}/Rooms/${roomId}/devices`);

          devicesRef.onSnapshot(async (devicesSnap) => {
            if (devicesSnap.empty) return;

            devicesSnap.forEach(async (doc) => {
              const deviceId = doc.id;
              const data = doc.data();
              const type = data.type || "unknown";
              const name = data.name || "unnamed";
              const localDevice = `${homeName}-${roomName}`;
              
              const payload = {
                ownerHomeId,
                homeId, 
                roomId, 
                deviceId,
                localDevice
              };
              
              var topic = "";
              
              // Xác định topic dựa trên loại thiết bị
              if (type === "Security") {
                topic = `alert/${homeId}/${roomId}/${deviceId}`;
              } else if (type === "Trash") {
                // Thùng rác sẽ subscribe cả status và control topic
                const getDeviceTopic = `getDevice/${type}/${name}`;
                client.publish(getDeviceTopic, JSON.stringify(payload), { qos: 1, retain: true });
                console.log(`Published Trash device: ${name} (${type}) - User: ${ownerHomeId}`);
                
                // Subscribe control topic cho Thùng rác
                const controlTopic = `Status/${homeId}/${roomId}/${deviceId}`;
                client.subscribe(controlTopic, { qos: 1 }, (err) => {
                  if (err) {
                    console.error(` Failed to subscribe Trash control ${controlTopic}:`, err.message);
                  } else {
                    console.log(`Subscribed to Trash control: ${controlTopic}`);
                  }
                });
                
                return; // Skip the generic subscribe below for Trash
              } else {
                topic = `Status/${homeId}/${roomId}/${deviceId}`;
              }
              
              const getDeviceTopic = `getDevice/${type}/${name}`;
              client.publish(getDeviceTopic, JSON.stringify(payload), { qos: 1, retain: true });
              console.log(`📤 Published Firestore device: ${name} (${type}) - User: ${ownerHomeId}`);

              client.subscribe(topic, { qos: 1 }, (err) => {
                if (err) {
                  console.error(` Failed to subscribe ${topic}:`, err.message);
                } else {
                  console.log(` Subscribed to ${topic}`);
                }
              });
              if (type === "RFID") {
                const rfidTopicAlert = `alert/${homeId}/${roomId}/${deviceId}`;
                client.subscribe(rfidTopicAlert, { qos: 1 }, (err) => {
                if (err) {
                  console.error(` Failed to subscribe ${rfidTopicAlert}:`, err.message);
                } else {
                  console.log(` Subscribed to ${rfidTopicAlert}`);
                }
              });
                }
            });
          });
        }
      });
    }
  });
}

function startFirebaseStream() {
  console.log("📡 Listening for Firebase realtime changes (per device)...");
  const homesRef = db.ref("Status");

  homesRef.once("value", (homesSnap) => {
    homesSnap.forEach((homeSnap) => {
      const homeId = homeSnap.key;
      homeSnap.forEach((roomSnap) => {
        const roomId = roomSnap.key;
        roomSnap.forEach((deviceSnap) => {
          const deviceId = deviceSnap.key;
          const deviceRef = db.ref(`Status/${homeId}/${roomId}/${deviceId}`);

          deviceRef.on("value", async (snap) => {
                  try {
                    const deviceData = snap.val();

                    if (!deviceData) {
                      console.log(` Device ${homeId}/${roomId}/${deviceId} deleted -> stop publishing`);
                      deviceRef.off("value");
                      return;
                    }

                    const topic = `${homeId}/${roomId}/${deviceId}`;

                    const deviceSnap = await firestore
                      .collection(`Homes/${homeId}/Rooms/${roomId}/devices`)
                      .doc(deviceId)
                      .get();

                    if (!deviceSnap.exists) {
                      console.warn(` Firestore device not found: ${deviceId}`);
                      return; //  dừng, KHÔNG publish
                    }

                    const deviceInfo = deviceSnap.data();

                    if (!deviceInfo || !deviceInfo.type) {
                      console.warn(` Invalid deviceInfo:`, deviceInfo);
                      return;
                    }

                    // 🎯 XỬ LÝ RIÊNG THÙNG RÁC
                    if (deviceInfo.type === "Trash") {
                      const controlPayload = {
                        status: Boolean(deviceData.status),
                        mode: deviceData.mode ?? "auto"
                      };

                      client.publish(topic, JSON.stringify(controlPayload), {
                        qos: 1,
                        retain: true
                      });

                      console.log(` Trash Control published: ${topic}`, controlPayload);

                      // 🔔 Gửi notification nếu mở
                      if (deviceData.status === true) {
                        const homeDoc = await firestore.collection("Homes").doc(homeId).get();
                        if (homeDoc.exists) {
                          const ownerId = homeDoc.data().ownerId;
                          sendTrashNotification(ownerId, homeId, roomId, deviceId, "OPEN");
                        }
                      }

                    } else {
                      //  Thiết bị thường
                      client.publish(topic, JSON.stringify(deviceData), {
                        qos: 1,
                        retain: true
                      });

                      console.log(` Published device changed: ${topic}`);
                    }

                  } catch (err) {
                    console.error(" Device listener error:", err);
                  }
                });

        });
      });
    });
  });

  homesRef.on("child_added", (homeSnap) => {
    const homeId = homeSnap.key;
    console.log(` New home detected: ${homeId}`);

    const roomsRef = db.ref(`Status/${homeId}`);
    roomsRef.on("child_added", (roomSnap) => {
      const roomId = roomSnap.key;
      console.log(`🛏️ New room detected: ${homeId}/${roomId}`);

      const devicesRef = db.ref(`Status/${homeId}/${roomId}`);
      devicesRef.on("child_added", (deviceSnap) => {
        const deviceId = deviceSnap.key;
        console.log(` Listening new device: ${homeId}/${roomId}/${deviceId}`);

        const deviceRef = db.ref(`Status/${homeId}/${roomId}/${deviceId}`);
        deviceRef.on("value", (snap) => {
          const deviceData = snap.val();
          if (deviceData === null) {
            console.log(` Device ${homeId}/${roomId}/${deviceId} deleted -> stop publishing`);
            deviceRef.off("value");
            return;
          }

          const topic = `${homeId}/${roomId}/${deviceId}`;
          
          //  XỬ LÝ ĐẶC BIỆT CHO THÙNG RÁC
          if (deviceData.deviceType === "Trash") {
            const controlPayload = {
              status: deviceData.status || false,
              mode: deviceData.mode || "auto"
            };
            
            client.publish(topic, JSON.stringify(controlPayload), { qos: 1, retain: true });
            console.log(` New Trash Control published: ${topic}`);
          } else {
            client.publish(topic, JSON.stringify(deviceData), { qos: 1, retain: true });
            console.log(` Published device changed: ${topic}`);
          }
        });
      });

      devicesRef.on("child_removed", (deviceSnap) => {
        const deviceId = deviceSnap.key;
        console.log(` Device removed: ${homeId}/${roomId}/${deviceId}`);
        db.ref(`Status/${homeId}/${roomId}/${deviceId}`).off("value");
      });
    });
  });
}

// ========== HÀM GỬI NOTIFICATION CHO THÙNG RÁC ==========
async function sendTrashNotification(userId, homeId, roomId, deviceId, action) {
  try {
    const usersRef = firestore.collection("users");
    
    const messageData = {
      type: 'trashStatus',
      homeId,
      roomId,
      deviceId,
      deviceName: "Thùng rác thông minh",
      deviceType: "Trash",
      message: `Thùng rác đã được ${action === 'OPEN' ? 'mở' : 'đóng'}`,
      action: action,
      isProcessed: false,
      isRead: false,
      timestamp: Date.now(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Lưu notification vào Firestore
    await usersRef.doc(userId).collection("Notifications").add(messageData);

    // Gửi FCM notification
    const fcmMessage = {
      notification: {
        title: ` Thùng rác ${action === 'OPEN' ? 'Đã mở' : 'Đã đóng'}`,
        body: `Thùng rác thông minh ${action === 'OPEN' ? 'đã mở' : 'đã đóng'} thành công`,
      },
      android: {
        priority: "normal",
        notification: {
          sound: "default",
          channelId: "daily_channel",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
      data: {
        type: 'trashStatus',
        homeId: homeId,
        roomId: roomId,
        deviceId: deviceId,
        deviceName: "Thùng rác thông minh",
        deviceType: "Trash",
        action: action,
        timestamp: String(Date.now()),
        userId: userId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      topic: `alert_${userId}`,
    };

    const response = await admin.messaging().send(fcmMessage);
    console.log(` Trash notification sent to user: ${userId}`, response);
    return response;
    
  } catch (err) {
    console.error(" Error sending trash notification:", err);
  }
}

// ========== HÀM GỬI CẢNH BÁO THÙNG RÁC ĐẦY ==========
async function sendTrashFullNotification(userId, homeId, roomId, deviceId, fillLevel) {
  try {
    const usersRef = firestore.collection("users");
    
    let title = " Thùng rác sắp đầy!";
    let body = `Thùng rác đã đầy ${fillLevel}%`;
    
    if (fillLevel >= 95) {
      title = " THÙNG RÁC ĐÃ ĐẦY!";
      body = `Thùng rác đã đầy ${fillLevel}%. Vui lòng dọn dẹp ngay!`;
    }

    const messageData = {
      type: 'trashAlert',
      homeId,
      roomId,
      deviceId,
      deviceName: "Thùng rác thông minh",
      deviceType: "Trash",
      message: body,
      fillLevel: fillLevel,
      isProcessed: false,
      isRead: false,
      timestamp: Date.now(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Lưu notification vào Firestore
    await usersRef.doc(userId).collection("Notifications").add(messageData);

    // Gửi FCM notification
    const fcmMessage = {
      notification: {
        title: title,
        body: body,
      },
      android: {
        priority: fillLevel >= 95 ? "high" : "normal",
        notification: {
          sound: "default",
          channelId: fillLevel >= 95 ? "alert_channel_v2" : "daily_channel",
          priority: fillLevel >= 95 ? "max" : "high",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
      data: {
        type: 'trashAlert',
        homeId: homeId,
        roomId: roomId,
        deviceId: deviceId,
        deviceName: "Thùng rác thông minh",
        deviceType: "Trash",
        fillLevel: String(fillLevel),
        message: body,
        timestamp: String(Date.now()),
        userId: userId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      topic: `alert_${userId}`,
    };

    const response = await admin.messaging().send(fcmMessage);
    console.log(`Trash full notification sent to user: ${userId} (${fillLevel}%)`, response);
    return response;
    
  } catch (err) {
    console.error(" Error sending trash full notification:", err);
  }
}

// ========== HÀM LẤY LỊCH SỬ THÙNG RÁC ==========
async function getTrashHistory(userId, homeId, deviceId, limit = 50) {
  try {
    const historyRef = firestore
      .collection("users")
      .doc(userId)
      .collection("Notifications")
      .where("type", "in", ["trashStatus", "trashAlert"])
      .where("homeId", "==", homeId)
      .where("deviceId", "==", deviceId)
      .orderBy("timestamp", "desc")
      .limit(limit);

    const snapshot = await historyRef.get();
    const history = [];
    
    snapshot.forEach(doc => {
      history.push({
        id: doc.id,
        ...doc.data()
      });
    });
    
    return history;
  } catch (err) {
    console.error("Error getting trash history:", err);
    throw err;
  }
}

//  SỬA LẠI: Hàm gửi invitation notification theo unified model
async function sendInvitationNotification(invitationData) {
  try {
    const {
      toUserId,
      fromUserName,
      fromUserEmail,
      homeName,
      homeId,
      invitationId
    } = invitationData;

    //  TẠO NOTIFICATION THEO UNIFIED MODEL
    const notificationData = {
      type: 'invitation',
      invitationId: invitationId,
      fromUserId: invitationData.fromUserId,
      fromUserName: fromUserName,
      fromUserEmail: fromUserEmail,
      toUserEmail: invitationData.toUserEmail,
      toUserId: toUserId,
      homeId: homeId,
      homeName: homeName,
      status: 'pending',
      message: `${fromUserName} mời bạn tham gia ngôi nhà ${homeName}`,
      isRead: false,
      isProcessed: false,
      timestamp: Date.now(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Lưu vào user notifications
    await firestore
      .collection("users")
      .doc(toUserId)
      .collection("Notifications")
      .doc(invitationId)
      .set(notificationData);

    // Gửi FCM
    const message = {
      notification: {
        title: "📨 Lời mời tham gia ngôi nhà",
        body: `${fromUserName} mời bạn tham gia ngôi nhà ${homeName}`,
      },
      android: {
        priority: "high",
        notification: {
          sound: "default",
          channelId: "daily_channel",
          priority: "high",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
      data: {
        type: "invitation",
        invitationId: invitationId,
        fromUserName: fromUserName,
        fromUserEmail: fromUserEmail,
        homeName: homeName,
        homeId: homeId,
        timestamp: String(Date.now()),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        userId: toUserId,
      },
      topic: `alert_${toUserId}`,
    };

    const response = await admin.messaging().send(message);
    console.log(` Invitation notification sent to user: ${toUserId}`);
    return response;
  } catch (error) {
    console.error(" Error sending invitation notification:", error);
    throw error;
  }
}

// 🎯 SỬA LẠI: Hàm gửi invitation response theo unified model
async function sendInvitationResponseNotification(responseData) {
  try {
    const {
      toUserId,
      fromUserEmail,
      fromUserId,
      homeName,
      homeId,
      invitationId,
      status
    } = responseData;

    const title = status === 'accepted' 
      ? ' Lời mời được chấp nhận' 
      : ' Lời mời bị từ chối';
    
    const body = status === 'accepted'
      ? `${fromUserEmail} đã tham gia ngôi nhà ${homeName}`
      : `${fromUserEmail} đã từ chối lời mời tham gia ${homeName}`;

    //  TẠO RESPONSE NOTIFICATION THEO UNIFIED MODEL
    const notificationData = {
      type: 'invitation_response',
      invitationId: invitationId,
      fromUserId: fromUserId,
      fromUserName: 'Hệ thống',
      fromUserEmail: fromUserEmail,
      toUserEmail: responseData.toUserEmail,
      toUserId: toUserId,
      homeId: homeId,
      homeName: homeName,
      status: status,
      message: body,
      isRead: false,
      isProcessed: false,
      timestamp: Date.now(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Lưu vào user notifications của người gửi
    await firestore
      .collection("users")
      .doc(toUserId)
      .collection("Notifications")
      .doc(`response_${invitationId}`)
      .set(notificationData);

    // Gửi FCM
    const message = {
      notification: {
        title: title,
        body: body,
      },
      android: {
        priority: "normal",
        notification: {
          sound: "default",
          channelId: "daily_channel",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
      data: {
        type: "invitation_response",
        invitationId: invitationId,
        status: status,
        fromUserEmail: fromUserEmail,
        homeName: homeName,
        homeId: homeId,
        timestamp: String(Date.now()),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        userId: toUserId,
      },
      topic: `alert_${toUserId}`,
    };

    const response = await admin.messaging().send(message);
    console.log(` Response notification sent to: ${toUserId}`);
    return response;
  } catch (error) {
    console.error(" Error sending response notification:", error);
    throw error;
  }
}

// Thêm Express để tạo API
import express from "express";
const app = express();
app.use(express.json());

// ========== API CHO THÙNG RÁC ==========
// API lấy lịch sử thùng rác
app.get("/api/trash-history/:userId/:homeId/:deviceId", async (req, res) => {
  try {
    const { userId, homeId, deviceId } = req.params;
    const limit = parseInt(req.query.limit) || 50;
    
    const history = await getTrashHistory(userId, homeId, deviceId, limit);
    
    res.json({
      success: true,
      data: history
    });
  } catch (error) {
    console.error("Error getting trash history:", error);
    res.status(500).json({ error: error.message });
  }
});

// API điều khiển thùng rác từ xa
app.post("/api/control-trash", async (req, res) => {
  try {
    const { userId, homeId, roomId, deviceId, status, mode } = req.body;
    
    if (!userId || !homeId || !roomId || !deviceId) {
      return res.status(400).json({ error: "Thiếu thông tin bắt buộc" });
    }
    
    // Cập nhật trạng thái thùng rác trên Firebase
    const trashRef = db.ref(`Status/${homeId}/${roomId}/${deviceId}`);
    const updateData = {
      status: status || false,
      mode: mode || "manual",
      lastControlBy: userId,
      lastControlAt: Date.now(),
      timestamp: Date.now(),
      deviceType: "Trash",
      deviceName: "Thùng rác thông minh"
    };
    
    await trashRef.update(updateData);
    
    console.log(` Trash control updated by ${userId}: ${JSON.stringify(updateData)}`);
    
    // Gửi notification
    await sendTrashNotification(userId, homeId, roomId, deviceId, status ? "OPEN" : "CLOSE");
    
    res.json({
      success: true,
      message: `Thùng rác ${status ? 'đã mở' : 'đã đóng'} thành công`,
      data: updateData
    });
    
  } catch (error) {
    console.error("Error controlling trash:", error);
    res.status(500).json({ error: error.message });
  }
});

// API lấy trạng thái thùng rác hiện tại
app.get("/api/trash-status/:homeId/:roomId/:deviceId", async (req, res) => {
  try {
    const { homeId, roomId, deviceId } = req.params;
    
    const trashRef = db.ref(`Status/${homeId}/${roomId}/${deviceId}`);
    const snapshot = await trashRef.once("value");
    
    if (!snapshot.exists()) {
      return res.status(404).json({ error: "Thùng rác không tìm thấy" });
    }
    
    const trashData = snapshot.val();
    
    res.json({
      success: true,
      data: trashData
    });
    
  } catch (error) {
    console.error("Error getting trash status:", error);
    res.status(500).json({ error: error.message });
  }
});

// API gửi cảnh báo thùng rác đầy thủ công
app.post("/api/trash-full-alert", async (req, res) => {
  try {
    const { userId, homeId, roomId, deviceId, fillLevel } = req.body;
    
    if (!userId || !homeId || !roomId || !deviceId || fillLevel === undefined) {
      return res.status(400).json({ error: "Thiếu thông tin bắt buộc" });
    }
    
    await sendTrashFullNotification(userId, homeId, roomId, deviceId, fillLevel);
    
    res.json({
      success: true,
      message: `Đã gửi cảnh báo thùng rác đầy ${fillLevel}%`
    });
    
  } catch (error) {
    console.error("Error sending trash full alert:", error);
    res.status(500).json({ error: error.message });
  }
});

//  API gửi lời mời - sử dụng unified model
app.post("/api/send-invitation", async (req, res) => {
  try {
    const {
      toUserEmail,
      homeId,
      homeName,
      fromUserId,
      fromUserName,
      fromUserEmail
    } = req.body;

    if (!toUserEmail || !homeId || !homeName || !fromUserId) {
      return res.status(400).json({ error: "Thiếu thông tin bắt buộc" });
    }

    // Tìm user bằng email
    const userQuery = await firestore
      .collection("users")
      .where("email", "==", toUserEmail.toLowerCase())
      .get();

    if (userQuery.empty) {
      return res.status(404).json({ error: "Người dùng không tồn tại" });
    }

    const toUserDoc = userQuery.docs[0];
    const toUserId = toUserDoc.id;

    // Kiểm tra xem user đã trong nhà chưa
    const homeDoc = await firestore.collection("Homes").doc(homeId).get();
    if (!homeDoc.exists) {
      return res.status(404).json({ error: "Ngôi nhà không tồn tại" });
    }

    const homeData = homeDoc.data();
    const members = homeData.members || [];

    // Kiểm tra xem userId đã tồn tại trong mảng members chưa
    const isUserAlreadyMember = members.some(member => member.userId === toUserId);

    if (isUserAlreadyMember) {
      return res.status(400).json({ error: "Người dùng đã là thành viên" });
    }

    // Kiểm tra invitation tồn tại
    const existingInvitation = await firestore
      .collection("users")
      .doc(toUserId)
      .collection("Notifications")
      .where("type", "==", "invitation")
      .where("homeId", "==", homeId)
      .where("status", "==", "pending")
      .get();

    if (!existingInvitation.empty) {
      return res.status(400).json({ error: "Đã có lời mời đang chờ xử lý" });
    }

    // Tạo invitation ID
    const invitationId = firestore.collection("invitations").doc().id;

    // Gửi notification
    await sendInvitationNotification({
      toUserId,
      fromUserId,
      fromUserName,
      fromUserEmail,
      toUserEmail: toUserEmail.toLowerCase(),
      homeName,
      homeId,
      invitationId
    });

    res.json({
      success: true,
      message: "Đã gửi lời mời thành công",
      invitationId,
    });

  } catch (error) {
    console.error("Error sending invitation:", error);
    res.status(500).json({ error: error.message });
  }
});

// API xử lý invitation response - sử dụng unified model
app.post("/api/handle-invitation", async (req, res) => {
  try {
    const { invitationId, action, currentUserId } = req.body;
    
    if (!invitationId || !action || !currentUserId) {
      return res.status(400).json({ error: "Thiếu thông tin bắt buộc" });
    }

    // Lấy invitation từ user notifications
    const invitationDoc = await firestore
      .collection("users")
      .doc(currentUserId)
      .collection("Notifications")
      .doc(invitationId)
      .get();

    if (!invitationDoc.exists) {
      return res.status(404).json({ error: "Không tìm thấy lời mời" });
    }

    const invitation = invitationDoc.data();

    // Kiểm tra quyền
    if (invitation.toUserId !== currentUserId) {
      return res.status(403).json({ error: "Không có quyền xử lý lời mời này" });
    }

    const status = action === 'accept' ? 'accepted' : 'rejected';

    // Cập nhật status trong user notifications
    await firestore
      .collection("users")
      .doc(currentUserId)
      .collection("Notifications")
      .doc(invitationId)
      .update({
        status: status,
        isRead: true,
        timestamp: Date.now(),
      });

    // Gửi notification response cho người gửi
    await sendInvitationResponseNotification({
      toUserId: invitation.fromUserId,
      fromUserId: currentUserId,
      fromUserEmail: invitation.toUserEmail,
      toUserEmail: invitation.fromUserEmail,
      homeName: invitation.homeName,
      homeId: invitation.homeId,
      invitationId: invitationId,
      status: status
    });

    res.json({ 
      success: true, 
      message: `Đã ${action === 'accept' ? 'chấp nhận' : 'từ chối'} lời mời`,
      status: status
    });

  } catch (error) {
    console.error("Error handling invitation:", error);
    res.status(500).json({ error: error.message });
  }
});

// Khởi động server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(` Server running on port ${PORT}`);
  console.log(` MQTT-WebSocket available at: wss://${process.env.HOST || 'localhost'}:${PORT}/mqtt`);
});

client.on("error", (err) => {
  console.error(" MQTT Connection Error:", err);
});