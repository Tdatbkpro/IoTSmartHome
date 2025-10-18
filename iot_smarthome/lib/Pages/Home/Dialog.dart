import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Config/Icons.dart';
import 'package:iot_smarthome/Controllers/DeviceController.dart';
import 'package:iot_smarthome/Controllers/PickImageController.dart';
import 'package:iot_smarthome/Models/HomeModel.dart';
import 'package:iot_smarthome/Models/RoomModel.dart';
import 'package:iot_smarthome/Pages/Home/Widget/ScanQRCodePage.dart';
import 'package:uuid/uuid.dart';

class DialogUtils {
  static final  deviceController = Get.put(DeviceController()); 
  static final auth = FirebaseAuth.instance;
  static void showEditHomeDialog(BuildContext context, HomeModel home) {
    final nameCtrl = TextEditingController(text: home.name);
    final imageCtrl = TextEditingController(text: home.image ?? "");
    final pickImageController = PickImageController();

    /// Tạo RxString để quan sát ảnh
    final RxString imageUrl = (home.image ?? "").obs;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sửa home"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Tên home"),
            ),
            const SizedBox(height: 16),

            /// Preview ảnh với Obx
            Obx(() {
              if (imageUrl.value.isNotEmpty) {
                return Image.network(
                  imageUrl.value,
                  height: 100,
                  fit: BoxFit.cover,
                );
              } else {
                return const SizedBox.shrink();
              }
            }),

            TextButton.icon(
              onPressed: () async {
                final url = await pickImageController.pickImageFileAndUpload();
                if (url != null && url.isNotEmpty) {
                  imageUrl.value = url;     // cập nhật ảnh preview
                  imageCtrl.text = url;     // cập nhật controller để lưu
                }
              },
              icon: const Icon(Icons.image),
              label: const Text("Sửa ảnh"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              final updated = HomeModel(
                id: home.id,
                name: nameCtrl.text.trim(),
                ownerId: home.ownerId,
                image: imageUrl.value.isNotEmpty ? imageUrl.value : null,
                rooms: home.rooms,
              );
              deviceController.updateHome(updated);
              Navigator.pop(context);
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

static void showAddDeviceDialog(
    BuildContext context, String homeId, String roomId) {
  final nameCtrl = TextEditingController();
  String selectedType = "Đèn";
  final formKey = GlobalKey<FormState>();

  // Map ánh xạ tiếng Việt -> tiếng Anh
  

  final deviceTypes = deviceTypeMap.keys.toList();

  showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.devices_rounded,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Thêm thiết bị mới",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Nút quét QR code
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[50]!, Colors.green[100]!],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ScanQRCodePage(homeId: homeId, roomId: roomId),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green[800],
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
                label: const Text(
                  "Quét QR Thiết Bị",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Divider với text
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.grey[300],
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "hoặc",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Colors.grey[300],
                    thickness: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Form nhập thủ công
            Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: "Tên thiết bị",
                      hintText: "Nhập tên thiết bị...",
                      prefixIcon: Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: const Icon(Icons.edit_rounded, color: Colors.grey),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 40),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.deepPurple, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    style: const TextStyle(fontSize: 16),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Vui lòng nhập tên thiết bị";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: selectedType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: "Loại thiết bị",
                      prefixIcon: Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: const Icon(Icons.category_rounded,
                            color: Colors.grey),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 40),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.deepPurple, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    dropdownColor: Colors.white,
                    icon: const Icon(Icons.arrow_drop_down_rounded,
                        color: Colors.grey),
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    items: deviceTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        getDeviceIcon(type),
                                        size: 18,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        type,
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) selectedType = val;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Nút hành động
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[400]!),
                      ),
                    ),
                    child: const Text(
                      "Hủy",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final device = Device(
                          id: const Uuid().v4(),
                          name: nameCtrl.text.trim(),
                          // 🔥 Dùng mapping để lưu tiếng Anh
                          type: deviceTypeMap[selectedType]!,
                          roomId: roomId,
                        );
                        deviceController.addDevice(homeId, roomId, device);
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Đã thêm thiết bị "${device.name}"'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: Colors.deepPurple.withOpacity(0.3),
                    ),
                    child: const Text(
                      "Thêm thiết bị",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

static Map<String, String> reverseDeviceTypeMap = {
  for (var e in deviceTypeMap.entries) e.value: e.key
};


static Map<String, String> deviceTypeMap = {
  "Đèn": "Light",
  "Quạt": "Fan",
  "TV": "TV",
  "Thùng rác": "Trash",
  "RFID": "RFID",
  "Chống trộm": "Security",
  "Loa": "Speaker",
  "Cảm biến khí gas": "Gas Sensor",
  "Cảm biến nhiệt độ và độ ẩm": "Temperature Humidity Sensor",
};

// Helper function để lấy icon cho thiết bị
static IconData getDeviceIcon(String type) {
  switch (type) {
    case "Light":
    case "Đèn":
      return Icons.lightbulb_outline_rounded;

    case "Fan":
    case "Quạt":
      return Icons.air_rounded;

    case "TV":
      return Icons.tv_rounded;

    case "Trash":
    case "Thùng rác":
      return Icons.delete_outline_rounded;

    case "RFID":
      return Icons.credit_card_rounded;

    case "Security":
    case "Chống trộm":
      return Icons.security_rounded;

    case "Speaker":
    case "Loa":
      return Icons.volume_up_rounded;

    case "Gas Sensor":
    case "Cảm biến khí gas":
      return Icons.cloud_rounded;

    case "Temperature Humidity Sensor":
    case "Cảm biến nhiệt độ và độ ẩm":
      return Icons.thermostat_rounded;

    default:
      return Icons.devices_other_rounded;
  }
}



static void showConfirmDialog(
  BuildContext context,
  String title,
  Widget content,
  VoidCallback onConfirm,
) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // bấm ra ngoài không tắt
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: content, // 👈 Truyền widget vào thay vì Text
        actions: <Widget>[
          TextButton(
            child: const Text('Hủy'),
            onPressed: () {
              Navigator.of(context).pop(); // đóng dialog
            },
          ),
          ElevatedButton(
            child: const Text('Xác nhận'),
            onPressed: () {
              Navigator.of(context).pop(); // đóng dialog
              onConfirm(); // chạy callback
            },
          ),
        ],
      );
    },
  );
}

 static void showAddRoomDialog(BuildContext context, String homeId) {
  final nameCtrl = TextEditingController();
  String? imageRoom; // lưu link ảnh
  final pickImageController = PickImageController();
  String selectedType = "Phòng khách"; // mặc định
  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Thêm phòng"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Tên phòng"),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: "Loại phòng"),
                  items: const [
                    DropdownMenuItem(
                        value: "Phòng khách", child: Text("Phòng khách")),
                    DropdownMenuItem(
                        value: "Phòng ngủ", child: Text("Phòng ngủ")),
                    DropdownMenuItem(
                        value: "Phòng ăn", child: Text("Phòng ăn")),
                    DropdownMenuItem(
                        value: "Phòng vệ sinh", child: Text("Phòng vệ sinh")),
                    DropdownMenuItem(
                        value: "Sân/Vườn", child: Text("Sân/Vườn")),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selectedType = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("Ảnh phòng"),
                    const SizedBox(width: 10),
                    if (imageRoom == null)
                      TextButton.icon(
                        onPressed: () async {
                          final url = await pickImageController
                              .pickImageFileAndUpload();
                          if (url != null && url.isNotEmpty) {
                            setState(() {
                              imageRoom = url;
                            });
                          }
                        },
                        icon: const Icon(Icons.image),
                        label: const Text("Chọn ảnh"),
                      )
                    else
                      Expanded(
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            InkWell(
                              onTap: () {
                                FullScreenImagePage(imageUrl: imageRoom!, heroTag: "Ảnh phòng");
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageRoom!,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  imageRoom = null;
                                });
                              },
                            )
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Hủy")),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final room = RoomModel(
                    id: const Uuid().v4(),
                    name: nameCtrl.text.trim(),
                    image: imageRoom, // giờ là String (link ảnh)
                    type: selectedType,
                    hoomId: homeId
                  );
                  deviceController.addRoom(homeId, room);
                  Navigator.pop(context);
                },
                child: const Text("Thêm"),
              ),
            ],
          );
        },
      );
    },
  );
}


  static void showEditRoomDialog(BuildContext context, String homeId, RoomModel room) {
  final nameCtrl = TextEditingController(text: room.name);
  String selectedType = room.type;
  String? imageUrl = room.image; // giữ ảnh cũ ban đầu
  final deviceController = Get.put(DeviceController());
  final pickImageController = PickImageController();
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Sửa phòng"),
      content: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Tên phòng"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(labelText: "Loại phòng"),
              items: const [
                DropdownMenuItem(value: "Phòng khách", child: Text("Phòng khách")),
                DropdownMenuItem(value: "Phòng ngủ", child: Text("Phòng ngủ")),
                DropdownMenuItem(value: "Phòng ăn", child: Text("Phòng ăn")),
                DropdownMenuItem(value: "Sân/Vườn", child: Text("Sân/Vườn")),
                DropdownMenuItem(value: "Phòng vệ sinh", child: Text("Phòng vệ sinh")),
              ],
              onChanged: (val) {
                if (val != null) selectedType = val;
              },
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text("Ảnh phòng:"),
                const SizedBox(width: 12),
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        child: const Icon(Icons.delete, color: Colors.red),
                        onTap: () {
                          setState(() {
                            imageUrl = null;
                          });
                        },
                      )
                    ],
                  ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () async {
                    final url = await pickImageController.pickImageFileAndUpload();
                    if (url != null && url.isNotEmpty) {
                      setState(() {
                        imageUrl = url;
                      });
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: const Text("Chọn ảnh"),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
        ElevatedButton(
          onPressed: () {
            final updated = RoomModel(
              id: room.id,
              name: nameCtrl.text.trim(),
              type: selectedType,
              image: imageUrl, // cập nhật ảnh luôn
            );
            deviceController.updateRoom(homeId, updated);
            Navigator.pop(context);
          },
          child: const Text("Lưu"),
        ),
      ],
    ),
  );
}
}
class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const FullScreenImagePage({required this.imageUrl, required this.heroTag, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          Center(
            child: Hero(
              tag: heroTag,
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
  
}

