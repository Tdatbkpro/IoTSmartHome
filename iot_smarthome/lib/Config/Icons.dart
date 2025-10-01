class AppIcons {
  static const fanOn = "assets/icons/fan-on.png";
  static const fanOff = "assets/icons/fan-off.png";
  static const lightOn = "assets/icons/light-on.png";
  static const lightOff = "assets/icons/light-off.png";
  static const rfid = "assets/icons/RIFD.png";
  static const securityOn = "assets/icons/security_on.png";
  static const securityOff = "assets/icons/security_off.png";
  static const gas_sensorOn = "assets/icons/gas_sensor_on.png";
  static const gas_sensorOff = "assets/icons/gas_sensor_off.png";
  static const tv = "assets/icons/television.png";
  static const speaker = "assets/icons/speaker.png";
  static const tempHumidity = "assets/icons/home_temp_humidity.png";
  static const trashOpen = "assets/icons/trash_open.png";
  static const trashClose = "assets/icons/trash_close.png";
}

String? getDeviceIcon(String type, bool isOn) {
  switch (type) {
    case "Đèn":
      return isOn ? AppIcons.lightOn : AppIcons.lightOff;
    case "Quạt":
      return isOn ? AppIcons.fanOn : AppIcons.fanOff;
    case "Thùng rác":
      return isOn ? AppIcons.trashOpen : AppIcons.trashClose;
    case "TV":
      return AppIcons.tv;
    case "Chống trộm":
        return isOn ? AppIcons.securityOn : AppIcons.securityOff;
    case "RFID":
      return AppIcons.rfid;
    case "Loa (Speaker)":
      return AppIcons.speaker;
    case "Cảm biến nhiệt độ & độ ẩm":
      return AppIcons.tempHumidity;
    case "Cảm biến khí gas":
        return isOn ? AppIcons.gas_sensorOn : AppIcons.gas_sensorOff;
    default:
      return null;
  }
}
