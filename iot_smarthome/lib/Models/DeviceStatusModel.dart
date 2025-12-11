import 'package:intl/intl.dart';

class DeviceStatus {
  bool status;
  double temperature;
  double humidity;
  double speed;
  String mode;
  double CO2;
  DateTime? lastUpdate;
  DateTime? _startTime;
  double _totalUsageHours = 0;
  Map<String, double> _dailyUsage = {}; // 🆕 Lưu trữ theo ngày (YYYY-MM-DD)

  DeviceStatus({
    required this.status,
    double? temperature,
    double? humidity,
    double? speed,
    String? mode,
    double? CO2,
    this.lastUpdate,
    double? totalUsageHours,
    DateTime? startTime,
    Map<String, double>? dailyUsage, // 🆕 Nhận dailyUsage từ bên ngoài
  })  : temperature = temperature ?? 0,
        humidity = humidity ?? 0,
        speed = speed ?? 0,
        mode = mode ?? '',
        CO2 = CO2 ?? 0,
        _totalUsageHours = totalUsageHours ?? 0,
        _startTime = startTime,
        _dailyUsage = dailyUsage ?? {};

  // 🆕 PHƯƠNG THỨC CẬP NHẬT VỚI LƯU TRỮ THEO NGÀY
  DeviceStatus updateDeviceStatus(bool newStatus, {Map<String, dynamic>? otherData}) {
    final now = DateTime.now();
    final todayKey = _getDateKey(now);
    
    double newTotalUsageHours = _totalUsageHours;
    DateTime? newStartTime = _startTime;
    Map<String, double> newDailyUsage = Map.from(_dailyUsage);

    // Đảm bảo có key cho ngày hôm nay
    newDailyUsage.putIfAbsent(todayKey, () => 0);

    if (newStatus && !status) {
      // BẬT thiết bị
      print('🟢 THIẾT BỊ BẬT - Ghi nhận thời gian bắt đầu');
      newStartTime = now;
      
    } else if (!newStatus && status && _startTime != null) {
      // TẮT thiết bị - tính thời gian sử dụng
      final duration = now.difference(_startTime!);
      final hoursUsed = duration.inMinutes / 60.0;
      newTotalUsageHours += hoursUsed;
      
      // 🆕 CẬP NHẬT THEO NGÀY
      newDailyUsage[todayKey] = newDailyUsage[todayKey]! + hoursUsed;
      
      print('🔴 THIẾT BỊ TẮT - Đã sử dụng: ${hoursUsed.toStringAsFixed(2)} giờ');
      print('📊 Tổng thời gian sử dụng: ${newTotalUsageHours.toStringAsFixed(2)} giờ');
      print('📅 Sử dụng hôm nay: ${newDailyUsage[todayKey]!.toStringAsFixed(2)} giờ');
      
      newStartTime = null;
    }

    return DeviceStatus(
      status: newStatus,
      temperature: otherData?['temperature'] ?? temperature,
      humidity: otherData?['humidity'] ?? humidity,
      speed: otherData?['speed'] ?? speed,
      mode: otherData?['mode'] ?? mode,
      CO2: otherData?['CO2'] ?? CO2,
      lastUpdate: now,
      totalUsageHours: newTotalUsageHours,
      startTime: newStartTime,
      dailyUsage: newDailyUsage,
    );
  }

  // 🆕 LẤY KEY CHO NGÀY (YYYY-MM-DD)
  String _getDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // 🆕 TÍNH ĐIỆN NĂNG THEO NGÀY
  double calculateDailyEnergyConsumption(double devicePowerWatt, DateTime date) {
    final dateKey = _getDateKey(date);
    final dailyHours = _dailyUsage[dateKey] ?? 0;
    
    // 🆕 Nếu là ngày hôm nay và đang bật, tính thêm thời gian hiện tại
    if (dateKey == _getDateKey(DateTime.now()) && status && _startTime != null) {
      final currentDuration = DateTime.now().difference(_startTime!);
      final currentHours = currentDuration.inMinutes / 60.0;
      return ((dailyHours + currentHours) * devicePowerWatt) / 1000;
    }
    
    return (dailyHours * devicePowerWatt) / 1000;
  }

  // 🆕 TÍNH ĐIỆN NĂNG THEO THÁNG
  double calculateMonthlyEnergyConsumption(double devicePowerWatt, DateTime month) {
    double totalHours = 0;
    final monthKey = "${month.year}-${month.month.toString().padLeft(2, '0')}";
    
    _dailyUsage.forEach((dateKey, hours) {
      if (dateKey.startsWith(monthKey)) {
        totalHours += hours;
      }
    });
    
    // 🆕 Thêm thời gian hiện tại nếu đang trong tháng hiện tại
    final currentMonthKey = _getDateKey(DateTime.now()).substring(0, 7);
    if (monthKey == currentMonthKey && status && _startTime != null) {
      final currentDuration = DateTime.now().difference(_startTime!);
      final currentHours = currentDuration.inMinutes / 60.0;
      totalHours += currentHours;
    }
    
    return (totalHours * devicePowerWatt) / 1000;
  }

  // 🆕 LẤY TẤT CẢ NGÀY TRONG THÁNG CÓ DỮ LIỆU
  Map<DateTime, double> getDailyUsageForMonth(DateTime month) {
    final result = <DateTime, double>{};
    final monthKey = "${month.year}-${month.month.toString().padLeft(2, '0')}";
    
    _dailyUsage.forEach((dateKey, hours) {
      if (dateKey.startsWith(monthKey)) {
        final parts = dateKey.split('-');
        final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        result[date] = hours;
      }
    });
    
    return result;
  }

  double get totalUsageIncludingCurrent {
    double total = _totalUsageHours;
    if (status && _startTime != null) {
      final currentDuration = DateTime.now().difference(_startTime!);
      total += currentDuration.inMinutes / 60.0;
    }
    return total;
  }

  double get currentSessionHours {
    if (status && _startTime != null) {
      final duration = DateTime.now().difference(_startTime!);
      return duration.inMinutes / 60.0;
    }
    return 0;
  }

  // 🆕 RESET HÀNG NGÀY (giữ lại lịch sử)
  void resetDailyStats() {
    // Không reset _dailyUsage để giữ lịch sử
    // Chỉ reset các biến tạm thời nếu cần
    print('🔄 Đã giữ nguyên lịch sử sử dụng');
  }

  factory DeviceStatus.fromMap(Map<dynamic, dynamic> map) {
    final rawStatus = map["status"];
    bool parsedStatus;

    if (rawStatus is bool) {
      parsedStatus = rawStatus;
    } else if (rawStatus is num) {
      parsedStatus = rawStatus == 1;
    } else if (rawStatus is String) {
      parsedStatus = rawStatus.toLowerCase() == "true";
    } else {
      parsedStatus = false;
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    // 🆕 PARSE DAILY USAGE
    Map<String, double> parseDailyUsage(dynamic value) {
      if (value is Map) {
        final result = <String, double>{};
        value.forEach((key, value) {
          if (key is String) {
            result[key] = parseDouble(value);
          }
        });
        return result;
      }
      return {};
    }

    return DeviceStatus(
      status: parsedStatus,
      temperature: parseDouble(map["temperature"]),
      humidity: parseDouble(map["humidity"]),
      speed: parseDouble(map["speed"]),
      mode: map["mode"] ?? '',
      CO2: parseDouble(map["CO2"]),
      lastUpdate: parseDate(map["lastUpdate"]),
      totalUsageHours: parseDouble(map["totalUsageHours"]),
      startTime: parseDate(map["startTime"]),
      dailyUsage: parseDailyUsage(map["dailyUsage"]), // 🆕 Thêm dailyUsage
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'temperature': temperature,
      'humidity': humidity,
      'speed': speed,
      'mode': mode,
      'CO2': CO2,
      'lastUpdate': lastUpdate?.toIso8601String(),
      'totalUsageHours': _totalUsageHours,
      'startTime': _startTime?.toIso8601String(),
      'dailyUsage': _dailyUsage, // 🆕 Lưu dailyUsage
    };
  }

  DeviceStatus copyWith({
    bool? status,
    double? temperature,
    double? humidity,
    double? speed,
    String? mode,
    double? CO2,
    DateTime? lastUpdate,
    double? totalUsageHours,
    DateTime? startTime,
    Map<String, double>? dailyUsage,
  }) {
    return DeviceStatus(
      status: status ?? this.status,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      speed: speed ?? this.speed,
      mode: mode ?? this.mode,
      CO2: CO2 ?? this.CO2,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      totalUsageHours: totalUsageHours ?? _totalUsageHours,
      startTime: startTime ?? _startTime,
      dailyUsage: dailyUsage ?? _dailyUsage,
    );
  }

  @override
  String toString() {
    return 'DeviceStatus('
        'status: $status, '
        'temp: ${temperature}°C, '
        'hum: ${humidity}%, '
        'totalUsage: ${totalUsageIncludingCurrent.toStringAsFixed(2)}h, '
        'dailyRecords: ${_dailyUsage.length} days, '
        'lastUpdate: ${lastUpdate != null ? DateFormat('HH:mm:ss').format(lastUpdate!) : "N/A"}'
        ')';
  }
}