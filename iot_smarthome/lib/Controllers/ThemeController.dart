import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsModel {
  // Theme & Appearance
  bool isDarkMode;
  
  // Security & Privacy
  bool biometricEnabled;
  bool twoFactorAuth;
  bool autoLogout;
  bool dataEncryption;
  bool usageAnalytics;
  bool remoteAccess;
  bool cameraRecording;
  bool micAccess;
  bool locationTracking;
  bool deviceSharing;
  int autoLogoutTime;
  String securityLevel;
  
  // TTS Settings
  double ttsVolume;
  double ttsPitch;
  double ttsRate;
  String ttsLanguage;
  String ttsEngine;
  
  // Notification Settings
  bool pushNotifications;
  bool emailNotifications;
  bool soundEnabled;
  bool vibrationEnabled;
  
  // General Settings
  String language;
  bool autoSync;
  bool batterySaver;

  SettingsModel({
    // Theme
    this.isDarkMode = false,
    
    // Security
    this.biometricEnabled = false,
    this.twoFactorAuth = false,
    this.autoLogout = true,
    this.dataEncryption = true,
    this.usageAnalytics = false,
    this.remoteAccess = true,
    this.cameraRecording = true,
    this.micAccess = false,
    this.locationTracking = false,
    this.deviceSharing = true,
    this.autoLogoutTime = 15,
    this.securityLevel = 'Trung bình',
    
    // TTS
    this.ttsVolume = 0.5,
    this.ttsPitch = 1.0,
    this.ttsRate = 0.5,
    this.ttsLanguage = 'vi-VN',
    this.ttsEngine = '',
    
    // Notifications
    this.pushNotifications = true,
    this.emailNotifications = false,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    
    // General
    this.language = 'vi',
    this.autoSync = true,
    this.batterySaver = false,
  });

  Map<String, dynamic> toMap() {
    return {
      // Theme
      'isDarkMode': isDarkMode,
      
      // Security
      'biometricEnabled': biometricEnabled,
      'twoFactorAuth': twoFactorAuth,
      'autoLogout': autoLogout,
      'dataEncryption': dataEncryption,
      'usageAnalytics': usageAnalytics,
      'remoteAccess': remoteAccess,
      'cameraRecording': cameraRecording,
      'micAccess': micAccess,
      'locationTracking': locationTracking,
      'deviceSharing': deviceSharing,
      'autoLogoutTime': autoLogoutTime,
      'securityLevel': securityLevel,
      
      // TTS
      'ttsVolume': ttsVolume,
      'ttsPitch': ttsPitch,
      'ttsRate': ttsRate,
      'ttsLanguage': ttsLanguage,
      'ttsEngine': ttsEngine,
      
      // Notifications
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      
      // General
      'language': language,
      'autoSync': autoSync,
      'batterySaver': batterySaver,
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      // Theme
      isDarkMode: map['isDarkMode'] ?? false,
      
      // Security
      biometricEnabled: map['biometricEnabled'] ?? false,
      twoFactorAuth: map['twoFactorAuth'] ?? false,
      autoLogout: map['autoLogout'] ?? true,
      dataEncryption: map['dataEncryption'] ?? true,
      usageAnalytics: map['usageAnalytics'] ?? false,
      remoteAccess: map['remoteAccess'] ?? true,
      cameraRecording: map['cameraRecording'] ?? true,
      micAccess: map['micAccess'] ?? false,
      locationTracking: map['locationTracking'] ?? false,
      deviceSharing: map['deviceSharing'] ?? true,
      autoLogoutTime: map['autoLogoutTime'] ?? 15,
      securityLevel: map['securityLevel'] ?? 'Trung bình',
      
      // TTS
      ttsVolume: map['ttsVolume']?.toDouble() ?? 0.5,
      ttsPitch: map['ttsPitch']?.toDouble() ?? 1.0,
      ttsRate: map['ttsRate']?.toDouble() ?? 0.5,
      ttsLanguage: map['ttsLanguage'] ?? 'vi-VN',
      ttsEngine: map['ttsEngine'] ?? '',
      
      // Notifications
      pushNotifications: map['pushNotifications'] ?? true,
      emailNotifications: map['emailNotifications'] ?? false,
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      
      // General
      language: map['language'] ?? 'vi',
      autoSync: map['autoSync'] ?? true,
      batterySaver: map['batterySaver'] ?? false,
    );
  }
}

class ThemeController extends GetxController {
  // Rx variables for reactive updates
  Rx<ThemeMode> themeMode = ThemeMode.light.obs;
  Rx<SettingsModel> settings = SettingsModel().obs;

  @override
  void onInit() {
    super.onInit();
    _loadAllSettings();
  }

  // 🔄 Toggle theme
  void toggleTheme(bool isDark) {
    settings.update((val) {
      val!.isDarkMode = isDark;
    });
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    Get.changeThemeMode(themeMode.value);
    _saveAllSettings();
  }

  // 🔒 Security Settings
  void updateSecuritySettings({
    bool? biometricEnabled,
    bool? twoFactorAuth,
    bool? autoLogout,
    bool? dataEncryption,
    bool? usageAnalytics,
    bool? remoteAccess,
    bool? cameraRecording,
    bool? micAccess,
    bool? locationTracking,
    bool? deviceSharing,
    int? autoLogoutTime,
    String? securityLevel,
  }) {
    settings.update((val) {
      val!.biometricEnabled = biometricEnabled ?? val.biometricEnabled;
      val.twoFactorAuth = twoFactorAuth ?? val.twoFactorAuth;
      val.autoLogout = autoLogout ?? val.autoLogout;
      val.dataEncryption = dataEncryption ?? val.dataEncryption;
      val.usageAnalytics = usageAnalytics ?? val.usageAnalytics;
      val.remoteAccess = remoteAccess ?? val.remoteAccess;
      val.cameraRecording = cameraRecording ?? val.cameraRecording;
      val.micAccess = micAccess ?? val.micAccess;
      val.locationTracking = locationTracking ?? val.locationTracking;
      val.deviceSharing = deviceSharing ?? val.deviceSharing;
      val.autoLogoutTime = autoLogoutTime ?? val.autoLogoutTime;
      val.securityLevel = securityLevel ?? val.securityLevel;
    });
    _saveAllSettings();
  }

  // 🎵 TTS Settings
  void updateTTSSettings({
    double? volume,
    double? pitch,
    double? rate,
    String? language,
    String? engine,
  }) {
    settings.update((val) {
      val!.ttsVolume = volume ?? val.ttsVolume;
      val.ttsPitch = pitch ?? val.ttsPitch;
      val.ttsRate = rate ?? val.ttsRate;
      val.ttsLanguage = language ?? val.ttsLanguage;
      val.ttsEngine = engine ?? val.ttsEngine;
    });
    _saveAllSettings();
  }

  // 🔔 Notification Settings
  void updateNotificationSettings({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    settings.update((val) {
      val!.pushNotifications = pushNotifications ?? val.pushNotifications;
      val.emailNotifications = emailNotifications ?? val.emailNotifications;
      val.soundEnabled = soundEnabled ?? val.soundEnabled;
      val.vibrationEnabled = vibrationEnabled ?? val.vibrationEnabled;
    });
    _saveAllSettings();
  }

  // ⚙️ General Settings
  void updateGeneralSettings({
    String? language,
    bool? autoSync,
    bool? batterySaver,
  }) {
    settings.update((val) {
      val!.language = language ?? val.language;
      val.autoSync = autoSync ?? val.autoSync;
      val.batterySaver = batterySaver ?? val.batterySaver;
    });
    _saveAllSettings();
  }

  // 💾 Save all settings to SharedPreferences
  Future<void> _saveAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsMap = settings.value.toMap();
    
    settingsMap.forEach((key, value) async {
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    });
  }

  // 📥 Load all settings from SharedPreferences
  Future<void> _loadAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final loadedSettings = SettingsModel(
      // Theme
      isDarkMode: prefs.getBool('isDarkMode') ?? false,
      
      // Security
      biometricEnabled: prefs.getBool('biometricEnabled') ?? false,
      twoFactorAuth: prefs.getBool('twoFactorAuth') ?? false,
      autoLogout: prefs.getBool('autoLogout') ?? true,
      dataEncryption: prefs.getBool('dataEncryption') ?? true,
      usageAnalytics: prefs.getBool('usageAnalytics') ?? false,
      remoteAccess: prefs.getBool('remoteAccess') ?? true,
      cameraRecording: prefs.getBool('cameraRecording') ?? true,
      micAccess: prefs.getBool('micAccess') ?? false,
      locationTracking: prefs.getBool('locationTracking') ?? false,
      deviceSharing: prefs.getBool('deviceSharing') ?? true,
      autoLogoutTime: prefs.getInt('autoLogoutTime') ?? 15,
      securityLevel: prefs.getString('securityLevel') ?? 'Trung bình',
      
      // TTS
      ttsVolume: prefs.getDouble('ttsVolume') ?? 0.5,
      ttsPitch: prefs.getDouble('ttsPitch') ?? 1.0,
      ttsRate: prefs.getDouble('ttsRate') ?? 0.5,
      ttsLanguage: prefs.getString('ttsLanguage') ?? 'vi-VN',
      ttsEngine: prefs.getString('ttsEngine') ?? '',
      
      // Notifications
      pushNotifications: prefs.getBool('pushNotifications') ?? true,
      emailNotifications: prefs.getBool('emailNotifications') ?? false,
      soundEnabled: prefs.getBool('soundEnabled') ?? true,
      vibrationEnabled: prefs.getBool('vibrationEnabled') ?? true,
      
      // General
      language: prefs.getString('language') ?? 'vi',
      autoSync: prefs.getBool('autoSync') ?? true,
      batterySaver: prefs.getBool('batterySaver') ?? false,
    );

    settings.value = loadedSettings;
    themeMode.value = loadedSettings.isDarkMode ? ThemeMode.dark : ThemeMode.light;
    Get.changeThemeMode(themeMode.value);
  }

  // 🔄 Reset all settings to default
  Future<void> resetToDefault() async {
    settings.value = SettingsModel();
    themeMode.value = ThemeMode.light;
    Get.changeThemeMode(themeMode.value);
    await _saveAllSettings();
    
    Get.snackbar(
      "Thành công",
      "✅ Đã đặt lại tất cả cài đặt về mặc định!",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.primary,
      colorText: Colors.white,
    );
  }

  // 📊 Get specific setting groups
  SettingsModel get securitySettings => SettingsModel(
    biometricEnabled: settings.value.biometricEnabled,
    twoFactorAuth: settings.value.twoFactorAuth,
    autoLogout: settings.value.autoLogout,
    dataEncryption: settings.value.dataEncryption,
    usageAnalytics: settings.value.usageAnalytics,
    remoteAccess: settings.value.remoteAccess,
    cameraRecording: settings.value.cameraRecording,
    micAccess: settings.value.micAccess,
    locationTracking: settings.value.locationTracking,
    deviceSharing: settings.value.deviceSharing,
    autoLogoutTime: settings.value.autoLogoutTime,
    securityLevel: settings.value.securityLevel,
  );

  SettingsModel get ttsSettings => SettingsModel(
    ttsVolume: settings.value.ttsVolume,
    ttsPitch: settings.value.ttsPitch,
    ttsRate: settings.value.ttsRate,
    ttsLanguage: settings.value.ttsLanguage,
    ttsEngine: settings.value.ttsEngine,
  );

  SettingsModel get notificationSettings => SettingsModel(
    pushNotifications: settings.value.pushNotifications,
    emailNotifications: settings.value.emailNotifications,
    soundEnabled: settings.value.soundEnabled,
    vibrationEnabled: settings.value.vibrationEnabled,
  );

  // ✅ Check if specific setting is enabled
  bool get isDarkMode => settings.value.isDarkMode;
  bool get isBiometricEnabled => settings.value.biometricEnabled;
  bool get isTwoFactorEnabled => settings.value.twoFactorAuth;
  bool get isAutoLogoutEnabled => settings.value.autoLogout;
  bool get isDataEncrypted => settings.value.dataEncryption;
  bool get isRemoteAccessEnabled => settings.value.remoteAccess;
  bool get isCameraRecordingEnabled => settings.value.cameraRecording;
  bool get isMicAccessEnabled => settings.value.micAccess;
  bool get isLocationTrackingEnabled => settings.value.locationTracking;
  bool get isDeviceSharingEnabled => settings.value.deviceSharing;
  bool get arePushNotificationsEnabled => settings.value.pushNotifications;
  bool get isAutoSyncEnabled => settings.value.autoSync;
}