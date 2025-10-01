import 'dart:convert';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';

class PickImageController extends GetxController {
  // ------------------- Chọn ảnh từ gallery -------------------
  Future<String> pickAndUploadImage() async {
    String? selectedImageUrl;
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85, // nén nhẹ nếu muốn
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      selectedImageUrl = await uploadToCloudinary(bytes, pickedFile.name);
    }
    return selectedImageUrl ?? "";
  }

  // ------------------- Chọn file ảnh (jpg, png) -------------------
  Future<String?> pickImageFileAndUpload() async {
    String? uploadedUrl;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      withData: true, // bắt buộc để lấy bytes
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      final filename = result.files.single.name;
      uploadedUrl = await uploadToCloudinary(bytes, filename);
    }
    return uploadedUrl;
  }

  // ------------------- Upload lên Cloudinary chung -------------------
  Future<String?> uploadToCloudinary(Uint8List bytes, String filename) async {
    final uri = Uri.parse("https://api.cloudinary.com/v1_1/dux65mgqh/upload");
    final request = http.MultipartRequest("POST", uri)
      ..fields['upload_preset'] = 'IoTSmartHome';

    final mimeType = lookupMimeType(filename)?.split('/');
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: mimeType != null ? MediaType(mimeType[0], mimeType[1]) : null,
      ),
    );

    final resp = await request.send();
    final respStr = await resp.stream.bytesToString();

    if (resp.statusCode == 200) {
      final data = jsonDecode(respStr);
      return data['secure_url'];
    } else {
      print('Upload failed: ${resp.statusCode} -> $respStr');
      return null;
    }
  }
}
