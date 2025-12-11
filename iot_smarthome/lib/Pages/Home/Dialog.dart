

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

static void showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Lỗi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

static void showAddDeviceDialog(
    BuildContext context, String homeId, String roomId ,{
        bool editDevice = false,
        Device? device,

    }) {
  final nameCtrl = TextEditingController(text: device?.name ?? '');
  final powerCtrl = TextEditingController(
    text: device?.power != null ? device!.power.toString() : ''
  );
  String selectedType =
      device != null ? deviceTypeMap[device.type] ?? "Đèn" : "Đèn";
  final formKey = GlobalKey<FormState>();

  final deviceTypes = deviceTypeMap.keys.toList();
  showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isSmallScreen = constraints.maxWidth < 400;
          final double horizontalPadding = isSmallScreen ? 16 : 24;
          final double verticalPadding = isSmallScreen ? 20 : 24;
          final double iconSize = isSmallScreen ? 18 : 20;
          final double fontSize = isSmallScreen ? 14 : 16;
          final double buttonFontSize = isSmallScreen ? 14 : 16;

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? 350 : 450,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header - Responsive
                  Row(
                    children: [
                      Container(
                        width: isSmallScreen ? 36 : 40,
                        height: isSmallScreen ? 36 : 40,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.devices_rounded,
                          color: Colors.deepPurple,
                          size: iconSize,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Expanded(
                        child: Text(
                          editDevice ? "Chỉnh sửa thiết bị" : "Thêm thiết bị mới",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 24),

                  // Nút quét QR code - Responsive
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
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 14 : 16,
                          horizontal: isSmallScreen ? 12 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(Icons.qr_code_scanner_rounded, 
                          size: isSmallScreen ? 20 : 24),
                      label: Text(
                        "Quét QR Thiết Bị",
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 16 : 20),

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
                            fontSize: isSmallScreen ? 12 : 14,
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

                  SizedBox(height: isSmallScreen ? 16 : 20),

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
                              child: Icon(Icons.edit_rounded, 
                                  color: Colors.grey, size: iconSize),
                            ),
                            prefixIconConstraints: 
                                const BoxConstraints(minWidth: 40),
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
                              borderSide: const BorderSide(
                                  color: Colors.deepPurple, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: isSmallScreen ? 12 : 16,
                            ),
                          ),
                          style: TextStyle(fontSize: fontSize),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Vui lòng nhập tên thiết bị";
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: isSmallScreen ? 12 : 16),

                        // Thêm trường nhập công suất
                        TextFormField(
                          controller: powerCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Công suất tiêu thụ (W)",
                            hintText: "Nhập công suất...",
                            prefixIcon: Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: Icon(Icons.bolt_rounded, 
                                  color: Colors.orange, size: iconSize),
                            ),
                            prefixIconConstraints: 
                                const BoxConstraints(minWidth: 40),
                            suffixText: "W",
                            suffixStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: fontSize,
                            ),
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
                              borderSide: const BorderSide(
                                  color: Colors.deepPurple, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: isSmallScreen ? 12 : 16,
                            ),
                          ),
                          style: TextStyle(fontSize: fontSize),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Vui lòng nhập công suất";
                            }
                            final power = double.tryParse(value);
                            if (power == null || power <= 0) {
                              return "Công suất phải là số dương";
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: isSmallScreen ? 12 : 16),

                        DropdownButtonFormField<String>(
                          value: selectedType,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: "Loại thiết bị",
                            prefixIcon: Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: Icon(Icons.category_rounded,
                                  color: Colors.grey, size: iconSize),
                            ),
                            prefixIconConstraints: 
                                const BoxConstraints(minWidth: 40),
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
                              borderSide: const BorderSide(
                                  color: Colors.deepPurple, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: isSmallScreen ? 12 : 16,
                            ),
                          ),
                          dropdownColor: Colors.white,
                          icon: Icon(Icons.arrow_drop_down_rounded,
                              color: Colors.grey, size: iconSize + 4),
                          style: TextStyle(fontSize: fontSize, 
                              color: Colors.black87),
                          items: deviceTypes
                              .map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: isSmallScreen ? 2 : 4),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: isSmallScreen ? 28 : 32,
                                            height: isSmallScreen ? 28 : 32,
                                            decoration: BoxDecoration(
                                              color: Colors.deepPurple
                                                  .withOpacity(0.1),
                                              borderRadius: 
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              getDeviceIcon(type),
                                              size: isSmallScreen ? 16 : 18,
                                              color: Colors.deepPurple,
                                            ),
                                          ),
                                          SizedBox(width: isSmallScreen ? 8 : 12),
                                          Flexible(
                                            child: Text(
                                              type,
                                              style: TextStyle(
                                                  fontSize: isSmallScreen 
                                                      ? 13 : 14),
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

                  SizedBox(height: isSmallScreen ? 20 : 24),

                  // Nút hành động - Responsive layout
                  if (isSmallScreen) 
                    Column(
                      children: [
                        ElevatedButton(
                            onPressed: () {
                              if (editDevice) {
                                _updateDevice(context, formKey, nameCtrl, powerCtrl,
                                    selectedType, homeId, roomId, device!);
                              } else {
                                _addDevice(context, formKey, nameCtrl, powerCtrl,
                                    selectedType, homeId, roomId);
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
                            child: Text(
                              editDevice ? "Cập nhật thiết bị" : "Thêm thiết bị",
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                        SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[400]!),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: Text(
                            "Hủy",
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  else 
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
                            child: Text(
                              "Hủy",
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _addDevice(context, formKey, nameCtrl, powerCtrl, 
                                  selectedType, homeId, roomId);
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
                            child: Text(
                              "Thêm thiết bị",
                              style: TextStyle(
                                fontSize: buttonFontSize,
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
          );
        },
      ),
    ),
  );
}

// Hàm xử lý thêm thiết bị
static void _updateDevice(
  BuildContext context,
  GlobalKey<FormState> formKey,
  TextEditingController nameCtrl,
  TextEditingController powerCtrl,
  String selectedType,
  String homeId,
  String roomId,
  Device oldDevice,
) {
  if (formKey.currentState!.validate()) {
    final updatedDevice = oldDevice.copyWith(
      name: nameCtrl.text.trim(),
      power: double.parse(powerCtrl.text),
      type: deviceTypeMap[selectedType]!,
    );

    deviceController.updateDevice(homeId, roomId, updatedDevice);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã cập nhật thiết bị "${updatedDevice.name}"'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

static void _addDevice(
  BuildContext context,
  GlobalKey<FormState> formKey,
  TextEditingController nameCtrl,
  TextEditingController powerCtrl,
  String selectedType,
  String homeId,
  String roomId,
) {
  if (formKey.currentState!.validate()) {
    final device = Device(
      id: const Uuid().v4(),
      name: nameCtrl.text.trim(),
      type: deviceTypeMap[selectedType]!,
      roomId: roomId,
      power: double.parse(powerCtrl.text),
    );
    deviceController.addDevice(homeId, roomId, device);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm thiết bị "${device.name}"'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

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

static Map<String, String> reverseDeviceTypeMap = {
  for (var e in deviceTypeMap.entries) e.value: e.key
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
                  initialValue: selectedType,
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
              initialValue: selectedType,
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

class AddRoomDialog {
  static void show(BuildContext context, String homeId) {
    final nameCtrl = TextEditingController();
    String? imageRoom;
    final pickImageController = Get.put(PickImageController());
    String selectedType = "Phòng khách";
    final DeviceController deviceController = Get.put(DeviceController());

    // Danh sách loại phòng với icon
    final List<Map<String, dynamic>> roomTypes = [
      {
        'value': 'Phòng khách',
        'label': 'Phòng khách',
        'icon': Icons.living_outlined,
        'color': Colors.blue,
      },
      {
        'value': 'Phòng ngủ',
        'label': 'Phòng ngủ',
        'icon': Icons.bed_outlined,
        'color': Colors.purple,
      },
      {
        'value': 'Phòng ăn',
        'label': 'Phòng ăn',
        'icon': Icons.dining_outlined,
        'color': Colors.orange,
      },
      {
        'value': 'Nhà bếp',
        'label': 'Nhà bếp',
        'icon': Icons.kitchen_outlined,
        'color': Colors.green,
      },
      {
        'value': 'Phòng tắm',
        'label': 'Phòng tắm',
        'icon': Icons.bathtub_outlined,
        'color': Colors.teal,
      },
      {
        'value': 'Phòng làm việc',
        'label': 'Phòng làm việc',
        'icon': Icons.work_outline,
        'color': Colors.indigo,
      },
      {
        'value': 'Sân/Vườn',
        'label': 'Sân/Vườn',
        'icon': Icons.yard_outlined,
        'color': Colors.lightGreen,
      },
      {
        'value': 'Hành lang',
        'label': 'Hành lang',
        'icon': Icons.door_front_door_outlined,
        'color': Colors.brown,
      },
    ];

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width > 600 ? 500 : double.infinity,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).dialogBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Thêm Phòng Mới",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tên phòng
                            Text(
                              "Tên phòng *",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: nameCtrl,
                              decoration: InputDecoration(
                                hintText: "Nhập tên phòng...",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[400]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Loại phòng
                            Text(
                              "Loại phòng",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 200,
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: MediaQuery.of(context).size.width > 400 ? 4 : 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 0.8,
                                ),
                                itemCount: roomTypes.length,
                                itemBuilder: (context, index) {
                                  final type = roomTypes[index];
                                  final isSelected = selectedType == type['value'];
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedType = type['value'] as String;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                            ? (type['color'] as Color).withOpacity(0.1)
                                            : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected 
                                              ? type['color'] as Color
                                              : Colors.grey[300]!,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            type['icon'] as IconData,
                                            color: isSelected 
                                                ? type['color'] as Color
                                                : Colors.grey[600],
                                            size: 24,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            type['label'] as String,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: isSelected 
                                                  ? type['color'] as Color
                                                  : Colors.grey[700],
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Ảnh phòng
                            Text(
                              "Ảnh phòng",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            if (imageRoom == null)
                              Container(
                                width: double.infinity,
                                height: 120,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    style: BorderStyle.solid,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextButton(
                                  onPressed: () async {
                                    final url = await pickImageController.pickImageFileAndUpload();
                                    if (url != null && url.isNotEmpty) {
                                      setState(() {
                                        imageRoom = url;
                                      });
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt_outlined,
                                        color: Colors.grey[400],
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Thêm ảnh phòng",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                height: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Stack(
                                  children: [
                                    // Ảnh
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        imageRoom!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.error_outline,
                                              color: Colors.red,
                                              size: 40,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    
                                    // Nút xóa ảnh
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              imageRoom = null;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    
                                    // Nút đổi ảnh
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.camera_alt_outlined,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: () async {
                                            final url = await pickImageController.pickImageFileAndUpload();
                                            if (url != null && url.isNotEmpty) {
                                              setState(() {
                                                imageRoom = url;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Buttons
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.grey[200]!)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey[700],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: BorderSide(color: Colors.grey[400]!),
                                ),
                                child: const Text(
                                  "Hủy",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: nameCtrl.text.trim().isEmpty ? null : () {
                                  final room = RoomModel(
                                    id: const Uuid().v4(),
                                    name: nameCtrl.text.trim(),
                                    image: imageRoom,
                                    type: selectedType,
                                    hoomId: homeId,
                                  );
                                  deviceController.addRoom(homeId, room);
                                  Navigator.pop(context);
                                  
                                  // Hiển thị thông báo thành công
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Đã thêm phòng "${nameCtrl.text.trim()}"'),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  "Thêm Phòng",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class EditRoomDialog {
  static void show(BuildContext context, String homeId, RoomModel room) {
    final nameCtrl = TextEditingController(text: room.name);
    String selectedType = room.type ?? "Phòng khách";
    String? imageUrl = room.image;
    final DeviceController deviceController = Get.put(DeviceController());
    final PickImageController pickImageController = Get.put(PickImageController());

    // Danh sách loại phòng với icon (giống dialog thêm phòng)
    final List<Map<String, dynamic>> roomTypes = [
      {
        'value': 'Phòng khách',
        'label': 'Phòng khách',
        'icon': Icons.living_outlined,
        'color': Colors.blue,
      },
      {
        'value': 'Phòng ngủ',
        'label': 'Phòng ngủ',
        'icon': Icons.bed_outlined,
        'color': Colors.purple,
      },
      {
        'value': 'Phòng ăn',
        'label': 'Phòng ăn',
        'icon': Icons.dining_outlined,
        'color': Colors.orange,
      },
      {
        'value': 'Nhà bếp',
        'label': 'Nhà bếp',
        'icon': Icons.kitchen_outlined,
        'color': Colors.green,
      },
      {
        'value': 'Phòng tắm',
        'label': 'Phòng tắm',
        'icon': Icons.bathtub_outlined,
        'color': Colors.teal,
      },
      {
        'value': 'Phòng làm việc',
        'label': 'Phòng làm việc',
        'icon': Icons.work_outline,
        'color': Colors.indigo,
      },
      {
        'value': 'Sân/Vườn',
        'label': 'Sân/Vườn',
        'icon': Icons.yard_outlined,
        'color': Colors.lightGreen,
      },
      {
        'value': 'Hành lang',
        'label': 'Hành lang',
        'icon': Icons.door_front_door_outlined,
        'color': Colors.brown,
      },
    ];

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width > 600 ? 500 : double.infinity,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).dialogBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Chỉnh Sửa Phòng",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tên phòng
                            Text(
                              "Tên phòng *",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: nameCtrl,
                              decoration: InputDecoration(
                                hintText: "Nhập tên phòng...",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[400]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Loại phòng
                            Text(
                              "Loại phòng",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 200,
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: MediaQuery.of(context).size.width > 400 ? 4 : 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 0.8,
                                ),
                                itemCount: roomTypes.length,
                                itemBuilder: (context, index) {
                                  final type = roomTypes[index];
                                  final isSelected = selectedType == type['value'];
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedType = type['value'] as String;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                            ? (type['color'] as Color).withOpacity(0.1)
                                            : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected 
                                              ? type['color'] as Color
                                              : Colors.grey[300]!,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            type['icon'] as IconData,
                                            color: isSelected 
                                                ? type['color'] as Color
                                                : Colors.grey[600],
                                            size: 24,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            type['label'] as String,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: isSelected 
                                                  ? type['color'] as Color
                                                  : Colors.grey[700],
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Ảnh phòng
                            Text(
                              "Ảnh phòng",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            if (imageUrl == null)
                              Container(
                                width: double.infinity,
                                height: 120,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    style: BorderStyle.solid,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextButton(
                                  onPressed: () async {
                                    final url = await pickImageController.pickImageFileAndUpload();
                                    if (url != null && url.isNotEmpty) {
                                      setState(() {
                                        imageUrl = url;
                                      });
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt_outlined,
                                        color: Colors.grey[400],
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Thêm ảnh phòng",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                height: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Stack(
                                  children: [
                                    // Ảnh
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        imageUrl!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.error_outline,
                                                  color: Colors.red,
                                                  size: 40,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  "Không thể tải ảnh",
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    
                                    // Nút xóa ảnh
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              imageUrl = null;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    
                                    // Nút đổi ảnh
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.camera_alt_outlined,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: () async {
                                            final url = await pickImageController.pickImageFileAndUpload();
                                            if (url != null && url.isNotEmpty) {
                                              setState(() {
                                                imageUrl = url;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Buttons
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.grey[200]!)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey[700],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: BorderSide(color: Colors.grey[400]!),
                                ),
                                child: const Text(
                                  "Hủy",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: nameCtrl.text.trim().isEmpty ? null : () {
                                  final updatedRoom = RoomModel(
                                    id: room.id,
                                    name: nameCtrl.text.trim(),
                                    type: selectedType,
                                    image: imageUrl,
                                    hoomId: room.hoomId,
                                    devices: room.devices, // Giữ nguyên devices
                                  );
                                  
                                  deviceController.updateRoom(homeId, updatedRoom);
                                  Navigator.pop(context);
                                  
                                  // Hiển thị thông báo thành công
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Đã cập nhật phòng "${nameCtrl.text.trim()}"'),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  "Lưu Thay Đổi",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const FullScreenImagePage({required this.imageUrl, required this.heroTag, super.key});

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

