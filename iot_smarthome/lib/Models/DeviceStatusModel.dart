/// DeviceStatus (Realtime Database)
class DeviceStatus {
  final bool status;
  final double? temperature;
  final double? humidity;
  final double? speed;
  final String? mode;
  final double? CO2;

  DeviceStatus({
    required this.status,
    this.temperature,
    this.humidity,
    this.speed,
    this.mode,
    this.CO2
  });

  factory DeviceStatus.fromMap(Map<dynamic, dynamic> map) {
    return DeviceStatus(
      status: (map["status"] ?? 0) == 1,
      temperature: map["temperature"] ,
      humidity: map["humidity"],
      speed: map["speed"],
      mode: map["mode"],
      CO2: map["CO2"]
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status ? 1 : 0,
      'temperature': temperature,
      'humidity': humidity,
      'speed': speed,
      'mode': mode,
      "CO2": CO2
    };
  }
}
