import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Config/Icons.dart';
import 'package:iot_smarthome/Controllers/DeviceController.dart';
import 'package:iot_smarthome/Controllers/PickImageController.dart';
import 'package:iot_smarthome/Models/HomeModel.dart';
import 'package:iot_smarthome/Models/RoomModel.dart';
import 'package:uuid/uuid.dart';

class DialogUtils {
  static final  deviceController = Get.put(DeviceController());
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
  String selectedType = "Đèn"; // mặc định
  final formKey = GlobalKey<FormState>(); // ✅ form key

  final deviceTypes = [
    "Đèn",
    "Quạt",
    "TV",
    "Thùng rác",
    "RFID",
    "Chống trộm",
    "Loa (Speaker)",
    "Cảm biến khí gas",
    "Cảm biến nhiệt độ & độ ẩm",
  ];

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Thêm thiết bị"),
      content: SingleChildScrollView(
        child: Form(
          key: formKey, // ✅ bọc Form
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: "Tên thiết bị",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
                  isExpanded: true, // ✅ tránh overflow ngang
                  decoration: InputDecoration(
                    labelText: "Loại thiết bị",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: deviceTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Image.asset(
                                  getDeviceIcon(type, false) ??
                                      "assets/icons/security_on.png",
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    type,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
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
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Hủy"),
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
                      type: selectedType,
                      roomId: roomId,
                    );
                    deviceController.addDevice(homeId, roomId, device);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Thêm"),
              ),
            ),
          ],
        ),
      ],
    ),
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
static void showConfirmDialog(BuildContext context, String title, String content, VoidCallback onConfirm) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // bấm ra ngoài không tắt
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
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