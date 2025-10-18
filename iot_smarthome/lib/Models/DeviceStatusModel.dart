class DeviceStatus {
  bool status;
  double temperature;
  double humidity;
  double speed;
  String mode;
  double CO2;

  DeviceStatus({
    required this.status,
    double? temperature,
    double? humidity,
    double? speed,
    String? mode,
    double? CO2,
  })  : temperature = temperature ?? 0,
        humidity = humidity ?? 0,
        speed = speed ?? 0,
        mode = mode ?? "",
        CO2 = CO2 ?? 0;

  factory DeviceStatus.fromMap(Map<dynamic, dynamic> map) {
  final dynamic rawStatus = map["status"];

  bool parsedStatus;
  if (rawStatus is bool) {
    parsedStatus = rawStatus; // ✅ true/false
  } else if (rawStatus is num) {
    parsedStatus = rawStatus == 1; // ✅ 1/0
  } else if (rawStatus is String) {
    parsedStatus = rawStatus.toLowerCase() == "true"; // ✅ "true"/"false"
  } else {
    parsedStatus = false; // fallback
  }

  return DeviceStatus(
    status: parsedStatus,
    temperature: (map["temperature"] ?? 0).toDouble(),
    humidity: (map["humidity"] ?? 0).toDouble(),
    speed: (map["speed"] ?? 0).toDouble(),
    mode: map["mode"] ?? "",
    CO2: (map["CO2"] ?? 0).toDouble(),
  );
}


  Map<String, dynamic> toMap() {
  return {
    'status': status, // Flutter sẽ tự gửi kiểu bool
    'temperature': temperature,
    'humidity': humidity,
    'speed': speed,
    'mode': mode,
    'CO2': CO2,
  };
}

}
