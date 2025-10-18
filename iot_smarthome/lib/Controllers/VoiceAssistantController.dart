import 'package:get/get.dart';
enum DeviceAction {
  turnOn,
  turnOff,
  setTemperature,
  setHumidity,
  setSpeed,
  setMode,
  increaseTemperature,
  decreaseTemperature,
  increaseHumidity,
  decreaseHumidity,
  increaseSpeed,
  decreaseSpeed,
}


class VoiceAssistantController extends GetxController {
   static int? extractNumber(String command) {
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(command);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }
 static DeviceAction? detectAction(String command) {
  final normalized = command.toLowerCase();

  // Bật / tắt
  if (["bật", "mở", "bật lên"].any((kw) => normalized.contains(kw))) {
    return DeviceAction.turnOn;
  }
  if (["tắt", "ngắt", "đóng"].any((kw) => normalized.contains(kw))) {
    return DeviceAction.turnOff;
  }

  // Tăng / giảm với từ “xuống / lên”
  if (normalized.contains("tăng") || normalized.contains("lên")) {
    if (normalized.contains("nhiệt độ")) return DeviceAction.increaseTemperature;
    if (normalized.contains("tốc độ")) return DeviceAction.increaseSpeed;
    if (normalized.contains("độ ẩm")) return DeviceAction.increaseHumidity;
  }

  if (normalized.contains("giảm") || normalized.contains("xuống")) {
    if (normalized.contains("nhiệt độ")) return DeviceAction.decreaseTemperature;
    if (normalized.contains("tốc độ")) return DeviceAction.decreaseSpeed;
    if (normalized.contains("độ ẩm")) return DeviceAction.decreaseHumidity;
  }

  // Đặt trực tiếp
  if (normalized.contains("nhiệt độ")) return DeviceAction.setTemperature;
  if (normalized.contains("tốc độ")) return DeviceAction.setSpeed;
  if (normalized.contains("chế độ")) return DeviceAction.setMode;
  if (normalized.contains("độ ẩm")) return DeviceAction.setHumidity;

  return null;
}


static List<Map<String, dynamic>> parseMultipleCommands(String command) {
  final parts = command.split(RegExp(r'[,.]| và | rồi | sau đó | tiếp '));
  List<Map<String, dynamic>> result = [];

  for (var part in parts) {
    part = part.trim();
    if (part.isEmpty) continue;

    // loại bỏ phần sau "của" nếu có
    if (part.contains(" của ")) {
      part = part.split(" của ").first.trim();
    }

    final number = extractNumber(part);
    final action = detectAction(part);

    if (action != null) {
      result.add({
        "action": action,
        "value": number, // có thể null nếu không có số
        "text": part,
      });
    }
  }

  return result;
}



}



 
