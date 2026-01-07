

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Controllers/DeviceController.dart';
import 'package:iot_smarthome/Models/RoomModel.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:qr_code_tools/qr_code_tools.dart';



class ScanQRCodePage extends StatefulWidget {
  final String? homeId;
  final String? roomId;
  
  const ScanQRCodePage({super.key, this.homeId, this.roomId});

  @override
  State<ScanQRCodePage> createState() => _ScanQRCodePageState();
}
enum ScanMode {
    room,
    device
  }
class _ScanQRCodePageState extends State<ScanQRCodePage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isProcessing = false;
  bool _flashOn = false;
  Map<String, dynamic>? _scannedData;
  bool _showConfirmDialog = false;
  final ImagePicker _imagePicker = ImagePicker();
  
  // Thêm state cho scan mode
  ScanMode _scanMode = ScanMode.room; // room hoặc device

  

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (isProcessing || _showConfirmDialog) return;
      await _processQRCode(scanData.code);
    });
  }

  Future<void> _processQRCode(String? qrCode) async {
    if (isProcessing || _showConfirmDialog) return;
    isProcessing = true;
    
    HapticFeedback.mediumImpact();
    
    try {
      if (qrCode == null || qrCode.isEmpty) {
        _showResultDialog(
          "Không tìm thấy mã QR",
          Icons.error_outline,
          Colors.orange,
        );
        return;
      }

      final data = jsonDecode(qrCode);
      
      // Xác định loại QR code (room hoặc device)
      if (data["homeId"] != null && data["roomId"] != null) {
        // QR code phòng
        _scanMode = ScanMode.room;
        await _processRoomQR(data);
      } else if (data["deviceId"] != null && data["type"] != null) {
        // QR code thiết bị
        _scanMode = ScanMode.device;
        await _processDeviceQR(data);
      } else {
        _showResultDialog(
          "QR Code không hợp lệ",
          Icons.error_outline,
          Colors.red,
        );
      }

    } catch (e) {
      _showResultDialog(
        "QR Code không hợp lệ: $e",
        Icons.error_outline,
        Colors.red,
      );
    } finally {
      isProcessing = false;
    }
  }

  Future<void> _processRoomQR(Map<String, dynamic> data) async {
    final homeId = data["homeId"];
    final roomId = data['roomId'];
    final expire = data['expire'];
    final now = DateTime.now().millisecondsSinceEpoch;

    if (expire != null && now > expire) {
      _showResultDialog(
        "QR Code đã hết hạn",
        Icons.error_outline,
        Colors.orange,
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _validateAndShowRoomConfirmation(homeId, roomId, uid);
  }

  Future<void> _processDeviceQR(Map<String, dynamic> data) async {
    final deviceId = data["deviceId"];
    final deviceName = data["name"];
    final deviceType = data["type"];
    
    // Kiểm tra xem có homeId và roomId từ widget không
    if (widget.homeId == null || widget.roomId == null) {
      _showResultDialog(
        "Vui lòng chọn phòng trước khi thêm thiết bị",
        Icons.error_outline,
        Colors.orange,
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _validateAndShowDeviceConfirmation(deviceId, deviceName, deviceType, uid);
  }

  Future<void> _validateAndShowRoomConfirmation(String homeId, String roomId, String uid) async {
    final homeRef = FirebaseFirestore.instance.collection('Homes').doc(homeId);
    final homeSnapshot = await homeRef.get();

    if (!homeSnapshot.exists) {
      _showResultDialog(
        "Home không tồn tại",
        Icons.error_outline,
        Colors.red,
      );
      return;
    }

    final roomRef = homeRef.collection('Rooms').doc(roomId);
    final roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists) {
      _showResultDialog(
        "Room không tồn tại trong home",
        Icons.error_outline,
        Colors.red,
      );
      return;
    }

    final roomData = roomSnapshot.data();
    final allowedUsers = List<String>.from(roomData?['allowedUsers'] ?? []);
    
    if (allowedUsers.contains(uid)) {
      _showResultDialog(
        "Bạn đã có quyền truy cập phòng này",
        Icons.info_outline,
        Colors.blue,
      );
      return;
    }

    final roomName = roomData?['name'] ?? 'Không xác định';
    final homeName = homeSnapshot.data()?['name'] ?? 'Không xác định';

    setState(() {
      _scannedData = {
        'homeId': homeId,
        'roomId': roomId,
        'homeName': homeName,
        'roomName': roomName,
        'uid': uid,
        'type': 'room'
      };
      _showConfirmDialog = true;
    });

    _showConfirmJoinDialog(homeName, roomName);
  }

  Future<void> _validateAndShowDeviceConfirmation(String deviceId, String deviceName, String deviceType, String uid) async {
    // Kiểm tra xem thiết bị đã tồn tại chưa
    final deviceRef = FirebaseFirestore.instance
        .collection('Homes')
        .doc(widget.homeId)
        .collection('Rooms')
        .doc(widget.roomId)
        .collection('Devices')
        .doc(deviceId);

    final deviceSnapshot = await deviceRef.get();

    if (deviceSnapshot.exists) {
      _showResultDialog(
        "Thiết bị đã tồn tại trong phòng",
        Icons.info_outline,
        Colors.blue,
      );
      return;
    }

    // Lấy thông tin phòng và home
    final homeSnapshot = await FirebaseFirestore.instance
        .collection('Homes')
        .doc(widget.homeId)
        .get();
    final roomSnapshot = await FirebaseFirestore.instance
        .collection('Homes')
        .doc(widget.homeId)
        .collection('Rooms')
        .doc(widget.roomId)
        .get();

    final homeName = homeSnapshot.data()?['name'] ?? 'Không xác định';
    final roomName = roomSnapshot.data()?['name'] ?? 'Không xác định';

    setState(() {
      _scannedData = {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'deviceType': deviceType,
        'homeId': widget.homeId,
        'roomId': widget.roomId,
        'homeName': homeName,
        'roomName': roomName,
        'uid': uid,
        'type': 'device'
      };
      _showConfirmDialog = true;
    });

    _showConfirmAddDeviceDialog(deviceName, deviceType, roomName);
  }

  // Xử lý chọn ảnh từ thư viện
  Future<void> _pickImageFromGallery() async {
    try {
      controller?.pauseCamera();
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        _showProcessingDialog("Đang phân tích QR Code từ ảnh...");
        
        final String? qrCode = await _scanQRCodeFromImage(File(image.path));
        
        Navigator.pop(context);
        
        if (qrCode != null && qrCode.isNotEmpty) {
          await _processQRCode(qrCode);
        } else {
          _showManualQRInputDialog();
        }
        
      } else {
        controller?.resumeCamera();
      }
    } catch (e) {
      Navigator.pop(context);
      _showResultDialog(
        "Lỗi khi đọc QR code từ ảnh: $e",
        Icons.error_outline,
        Colors.red,
      );
      controller?.resumeCamera();
    }
  }

  Future<String?> _scanQRCodeFromImage(File imageFile) async {
    try {
      final result = await QrCodeToolsPlugin.decodeFrom(imageFile.path);
      if (result != null && result.isNotEmpty) {
        return result;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  void _showManualQRInputDialog() {
    TextEditingController qrController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_rounded,
                    size: 30,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  _scanMode == ScanMode.room 
                    ? "Nhập mã QR phòng" 
                    : "Nhập mã QR thiết bị",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                
                Text(
                  _scanMode == ScanMode.room
                    ? "Nhập mã QR code phòng thủ công:"
                    : "Nhập mã QR code thiết bị thủ công:",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                
                TextField(
                  controller: qrController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: _scanMode == ScanMode.room
                      ? '{"homeId": "abc", "roomId": "123", "expire": 123456789}'
                      : '{"deviceId": "xyz", "name": "Tên thiết bị", "type": "Loại thiết bị"}',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  _scanMode == ScanMode.room
                    ? "Định dạng: JSON với homeId, roomId, expire"
                    : "Định dạng: JSON với deviceId, name, type",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          controller?.resumeCamera();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: const Text(
                          "Hủy",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (qrController.text.trim().isNotEmpty) {
                            Navigator.pop(context);
                            _processQRCode(qrController.text.trim());
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Vui lòng nhập mã QR code"),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          "Xác nhận",
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
        );
      },
    );
  }

  void _showConfirmJoinDialog(String homeName, String roomName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.meeting_room_rounded,
                    size: 40,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 20),
                
                const Text(
                  "Tham gia phòng?",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow("🏠 Home:", homeName),
                      const SizedBox(height: 8),
                      _buildInfoRow("🚪 Phòng:", roomName),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  "Bạn sẽ được cấp quyền truy cập vào phòng này",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _showConfirmDialog = false;
                            _scannedData = null;
                          });
                          controller?.resumeCamera();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: const Text(
                          "Hủy",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _addUserToRoom,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          "Đồng ý",
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
        );
      },
    );
  }

  void _showConfirmAddDeviceDialog(String deviceName, String deviceType, String roomName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.devices_rounded,
                    size: 40,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                
                const Text(
                  "Thêm thiết bị?",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow("📱 Thiết bị:", deviceName),
                      const SizedBox(height: 8),
                      _buildInfoRow("🔧 Loại:", deviceType),
                      const SizedBox(height: 8),
                      _buildInfoRow("🚪 Phòng:", roomName),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  "Thiết bị sẽ được thêm vào phòng hiện tại",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _showConfirmDialog = false;
                            _scannedData = null;
                          });
                          controller?.resumeCamera();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: const Text(
                          "Hủy",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _addDeviceToRoom,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
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
        );
      },
    );
  }

  Future<void> _addUserToRoom() async {
    if (_scannedData == null) return;

    try {
      Navigator.pop(context);
      _showProcessingDialog("Đang thêm vào phòng...");

      final homeId = _scannedData!['homeId'];
      final roomId = _scannedData!['roomId'];
      final uid = _scannedData!['uid'];

      final roomRef = FirebaseFirestore.instance
          .collection('Homes')
          .doc(homeId)
          .collection('Rooms')
          .doc(roomId);

      await roomRef.update({
        "allowedUsers": FieldValue.arrayUnion([uid])
      });

      Navigator.pop(context);
      _showResultDialog(
        "Thành công! Bạn đã được cấp quyền truy cập phòng",
        Icons.check_circle_outline,
        Colors.green,
        isSuccess: true,
      );

    } catch (e) {
      Navigator.pop(context);
      _showResultDialog(
        "Có lỗi xảy ra: $e",
        Icons.error_outline,
        Colors.red,
      );
    } finally {
      setState(() {
        _showConfirmDialog = false;
        _scannedData = null;
      });
    }
  }

  Future<void> _addDeviceToRoom() async {
    if (_scannedData == null) return;
    final deviceController = Get.put(DeviceController());
    try {
      Navigator.pop(context);
      _showProcessingDialog("Đang thêm thiết bị...");

      final deviceId = _scannedData!['deviceId'];
      final deviceName = _scannedData!['deviceName'];
      final deviceType = _scannedData!['deviceType'];
      final homeId = _scannedData!['homeId'];
      final roomId = _scannedData!['roomId'];

      Device device = Device(id: deviceId, name: deviceName,roomId: roomId,type: deviceType);
      await deviceController.addDevice(homeId, roomId, device);

      Navigator.pop(context);
      _showResultDialog(
        "Thành công! Thiết bị đã được thêm vào phòng",
        Icons.check_circle_outline,
        Colors.green,
        isSuccess: true,
      );

    } catch (e) {
      Navigator.pop(context);
      _showResultDialog(
        "Có lỗi xảy ra: $e",
        Icons.error_outline,
        Colors.red,
      );
    } finally {
      setState(() {
        _showConfirmDialog = false;
        _scannedData = null;
      });
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  void _showProcessingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showResultDialog(String message, IconData icon, Color color, {bool isSuccess = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: color,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isSuccess ? "Thành công!" : "Thông báo",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (isSuccess) {
                        Navigator.pop(context);
                      } else {
                        controller?.resumeCamera();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      isSuccess ? "Hoàn tất" : "Thử lại",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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

  void _toggleFlash() {
    if (controller != null) {
      setState(() {
        _flashOn = !_flashOn;
      });
      controller?.toggleFlash();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanArea = size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.homeId != null ? "Quét QR Thiết Bị" : "Quét QR Phòng",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: widget.homeId != null ? Colors.greenAccent : Colors.deepPurpleAccent,
              borderRadius: 16,
              borderLength: 40,
              borderWidth: 6,
              cutOutSize: scanArea,
              overlayColor: Colors.black.withOpacity(0.7),
            ),
          ),
          
          if (!_showConfirmDialog)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          color: widget.homeId != null ? Colors.green[600] : Colors.deepPurple[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.homeId != null ? "Quét mã QR thiết bị" : "Quét mã QR phòng",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: widget.homeId != null ? Colors.green[600] : Colors.deepPurple[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.homeId != null 
                        ? "Đặt mã QR thiết bị vào khung để thêm vào phòng"
                        : "Đặt mã QR phòng vào khung để kết nối với phòng",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ... (phần còn lại của UI giữ nguyên)
          if (!_showConfirmDialog)
            Positioned(
              top: (size.height - scanArea) / 2 - 20,
              left: (size.width - scanArea) / 2 - 20,
              child: _buildCornerDecoration(true, false, widget.homeId != null),
            ),
          if (!_showConfirmDialog)
            Positioned(
              top: (size.height - scanArea) / 2 - 20,
              right: (size.width - scanArea) / 2 - 20,
              child: _buildCornerDecoration(false, false, widget.homeId != null),
            ),
          if (!_showConfirmDialog)
            Positioned(
              bottom: (size.height - scanArea) / 2 - 20,
              left: (size.width - scanArea) / 2 - 20,
              child: _buildCornerDecoration(true, true, widget.homeId != null),
            ),
          if (!_showConfirmDialog)
            Positioned(
              bottom: (size.height - scanArea) / 2 - 20,
              right: (size.width - scanArea) / 2 - 20,
              child: _buildCornerDecoration(false, true, widget.homeId != null),
            ),

          if (!_showConfirmDialog)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      "Đảm bảo mã QR nằm trong khung hình",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton(
                        icon: Icons.photo_library_rounded,
                        label: "Thư viện",
                        onTap: _pickImageFromGallery,
                        isDeviceMode: widget.homeId != null,
                      ),
                      const SizedBox(width: 40),
                      _buildActionButton(
                        icon: Icons.flash_on_rounded,
                        label: _flashOn ? "Tắt đèn" : "Bật đèn",
                        onTap: _toggleFlash,
                        isDeviceMode: widget.homeId != null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCornerDecoration(bool isLeft, bool isTop, bool isDeviceMode) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isDeviceMode ? Colors.greenAccent : Colors.deepPurpleAccent,
            width: isLeft ? 4 : 0,
          ),
          top: BorderSide(
            color: isDeviceMode ? Colors.greenAccent : Colors.deepPurpleAccent,
            width: isTop ? 4 : 0,
          ),
          right: BorderSide(
            color: isDeviceMode ? Colors.greenAccent : Colors.deepPurpleAccent,
            width: !isLeft ? 4 : 0,
          ),
          bottom: BorderSide(
            color: isDeviceMode ? Colors.greenAccent : Colors.deepPurpleAccent,
            width: !isTop ? 4 : 0,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDeviceMode,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: isDeviceMode ? Colors.green : Colors.deepPurple),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}