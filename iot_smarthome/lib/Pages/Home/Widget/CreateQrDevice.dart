import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:kf_drawer/kf_drawer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

class CreateDeviceQRPage extends StatefulWidget {
  const CreateDeviceQRPage({super.key});

  @override
  State<CreateDeviceQRPage> createState() => _CreateDeviceQRPageState();
}

class _CreateDeviceQRPageState extends State<CreateDeviceQRPage> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedType = "Đèn";
  String _qrData = "";
  bool _isQRGenerated = false;
  final GlobalKey _qrKey = GlobalKey();

  final List<String> deviceTypes = [
    "Đèn",
    "Quạt",
    "TV",
    "Thùng rác",
    "RFID",
    "Chống trộm",
    "Loa",
    "Cảm biến khí gas",
    "Cảm biến nhiệt độ và độ ẩm",
  ];

  Future<Uint8List?> _captureQRCode() async {
    try {
      RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print("Lỗi khi chụp QR code: $e");
      return null;
    }
  }

  Future<void> _downloadQRCode() async {
    try {
      PermissionStatus status;

      if (Theme.of(context).platform == TargetPlatform.iOS) {
        status = await Permission.photos.status;
        if (!status.isGranted) {
          status = await Permission.photos.request();
        }
      } else {
        status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
      }

      if (status.isGranted) {
        final Uint8List? qrBytes = await _captureQRCode();
        if (qrBytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Lỗi khi tạo QR code"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final result = await ImageGallerySaverPlus.saveImage(
          qrBytes,
          name: 'QR_Device_${_nameController.text}',
          quality: 100,
        );

        if (result['isSuccess'] == true || result['filePath'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Đã lưu QR code vào thư viện ảnh"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("❌ Lỗi khi lưu vào thư viện ảnh"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Cần cấp quyền truy cập thư viện ảnh để lưu QR"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi khi lưu: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _generateQRCode() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập tên thiết bị"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final deviceData = {
      "deviceId": const Uuid().v4(),
      "name": _nameController.text,
      "type": _selectedType,
      "createdAt": DateTime.now().millisecondsSinceEpoch,
    };

    setState(() {
      _qrData = jsonEncode(deviceData);
      _isQRGenerated = true;
    });
  }

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _selectedType = "Đèn";
      _qrData = "";
      _isQRGenerated = false;
    });
  }

  Future<void> _shareQRCode() async {
    try {
      final Uint8List? qrBytes = await _captureQRCode();
      if (qrBytes != null) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/qr_device_${_nameController.text}_${DateTime.now().millisecondsSinceEpoch}.png';
        final File imageFile = File(filePath);
        await imageFile.writeAsBytes(qrBytes);

        await Share.shareXFiles(
          [XFile(imageFile.path)],
          text: 'QR Code Thiết Bị ${_nameController.text} - Loại: $_selectedType\nQuét mã QR để thêm thiết bị vào hệ thống',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi khi tạo QR code để chia sẻ"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi khi chia sẻ: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => KFDrawer.of(context)?.toggle(),
        ),
        title: const Text(
          "Tạo QR Code Thiết Bị",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          if (_isQRGenerated)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _resetForm,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_2_rounded,
                    size: 50,
                    color: Colors.deepPurple[600],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Tạo QR Code Thiết Bị Mới",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Quét mã QR này để thêm thiết bị vào hệ thống",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Form nhập thông tin
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Thông tin thiết bị",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tên thiết bị
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Tên thiết bị",
                      hintText: "Nhập tên thiết bị...",
                      prefixIcon: const Icon(Icons.devices_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.deepPurple),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Loại thiết bị
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Loại thiết bị",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedType,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: deviceTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedType = newValue!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Nút tạo QR
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _generateQRCode,
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
                        "Tạo QR Code",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Hiển thị QR Code
            if (_isQRGenerated)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "QR Code Thiết Bị",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // QR Code với RepaintBoundary để chụp ảnh
                    RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: QrImageView(
                          data: _qrData,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Thông tin thiết bị
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow("Tên thiết bị:", _nameController.text),
                          const SizedBox(height: 8),
                          _buildInfoRow("Loại thiết bị:", _selectedType),
                          const SizedBox(height: 8),
                          _buildInfoRow("ID:", jsonDecode(_qrData)["deviceId"]),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Nút hành động - ĐÃ SỬA
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _resetForm,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                                child: const Text(
                                  "Tạo mới",
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
                                onPressed: _downloadQRCode, // ĐÃ SỬA: gọi _downloadQRCode
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "Lưu QR",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _shareQRCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.share_rounded),
                            label: const Text(
                              "Chia sẻ QR Code",
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}