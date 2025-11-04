import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Controllers/ThemeController.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TtsState { playing, stopped, paused, continued }
class TTSController extends GetxController {
  final RxString language = 'vi-VN'.obs;
  final RxString engine = ''.obs;
  final RxDouble volume = 0.5.obs;
  final RxDouble pitch = 1.0.obs;
  final RxDouble rate = 0.5.obs;
  final RxString newVoiceText = ''.obs; // Đổi tên để tránh conflict
  final Rx<TtsState> ttsState = TtsState.stopped.obs;

  void changeLanguage(String newLanguage) {
    language.value = newLanguage;
    update(); // Thêm update() để rebuild widgets
  }

  void changeEngine(String newEngine) {
    engine.value = newEngine;
    update(); // Thêm update() để rebuild widgets
  }

  void changeVoiceText(String text) {
    newVoiceText.value = text;
  }

  // Thêm method để update slider values
  void updateVolume(double value) {
    volume.value = value;
    update();
  }

  void updatePitch(double value) {
    pitch.value = value;
    update();
  }

  void updateRate(double value) {
    rate.value = value;
    update();
  }
}
class VoiceAssistantTTS extends StatefulWidget {
  const VoiceAssistantTTS({super.key});

  @override
  State<VoiceAssistantTTS> createState() => _VoiceAssistantTTSState();
}

class _VoiceAssistantTTSState extends State<VoiceAssistantTTS> {
  late FlutterTts flutterTts;
  final TTSController ttsController = Get.put(TTSController());
  
  bool isCurrentLanguageInstalled = false;

  bool get isPlaying => ttsController.ttsState.value == TtsState.playing;
  bool get isStopped => ttsController.ttsState.value == TtsState.stopped;
  bool get isPaused => ttsController.ttsState.value == TtsState.paused;
  bool get isContinued => ttsController.ttsState.value == TtsState.continued;

  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isWeb => kIsWeb;

  @override
  initState() {
    super.initState();
    loadTTSSettings();
    initTts();
  }

  dynamic initTts() async {
    flutterTts = FlutterTts();

    if (!kIsWeb && Platform.isAndroid) {
      await flutterTts.setEngine("com.google.android.tts");
    }

    await flutterTts.setLanguage(ttsController.language.value);
    _setAwaitOptions();

    if (!kIsWeb && Platform.isAndroid) {
      _getDefaultEngine();
      _getDefaultVoice();
    }

    // Handlers
    flutterTts.setStartHandler(() {
      ttsController.ttsState.value = TtsState.playing;
    });

    flutterTts.setCompletionHandler(() {
      ttsController.ttsState.value = TtsState.stopped;
    });

    flutterTts.setCancelHandler(() {
      ttsController.ttsState.value = TtsState.stopped;
    });

    flutterTts.setPauseHandler(() {
      ttsController.ttsState.value = TtsState.paused;
    });

    flutterTts.setContinueHandler(() {
      ttsController.ttsState.value = TtsState.continued;
    });

    flutterTts.setErrorHandler((msg) {
      ttsController.ttsState.value = TtsState.stopped;
    });
  }

  Future<List<String>> _getLanguages() async {
    try {
      final langs = await flutterTts.getLanguages;
      if (langs is List) {
        return langs.cast<String>();
      } else {
        return ['vi-VN', 'en-US']; // Fallback languages
      }
    } catch (e) {
      return ['vi-VN', 'en-US']; // Fallback languages
    }
  }

  Future<void> loadTTSSettings() async {
    final themeController = Get.put(ThemeController());
    ttsController.language.value = themeController.ttsSettings.language ?? "vi-VN";
    ttsController.engine.value = themeController.ttsSettings.ttsEngine ?? "";
    ttsController.pitch.value = themeController.ttsSettings.ttsPitch ?? 1.0;
    ttsController.rate.value = themeController.ttsSettings.ttsRate ?? 0.5;
    ttsController.volume.value = themeController.ttsSettings.ttsVolume ?? 1.0;
  }


  Future<void> saveTTSSettings() async {
    final themeController = Get.put(ThemeController());
    themeController.updateTTSSettings(
      volume: ttsController.volume.value, 
      pitch: ttsController.pitch.value,
      rate: ttsController.rate.value, 
      language: ttsController.language.value,
      engine: ttsController.engine.value
    );

    Get.snackbar(
      "Thành công",
      "✅ Đã lưu cài đặt TTS!",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.primary,
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
    );
  }


  Future<List<String>> _getEngines() async {
    try {
      final engines = await flutterTts.getEngines;
      if (engines is List) {
        return engines.cast<String>();
      } else {
        return []; // Return empty list instead of null
      }
    } catch (e) {
      return []; // Return empty list on error
    }
  }

  Future<void> _getDefaultEngine() async {
    try {
      var defaultEngine = await flutterTts.getDefaultEngine;
      if (defaultEngine != null) {
        ttsController.engine.value = defaultEngine;
      }
    } catch (e) {
      print("Error getting default engine: $e");
    }
  }

  Future<void> _getDefaultVoice() async {
    try {
      var voice = await flutterTts.getDefaultVoice;
      if (voice != null) {
        print(voice);
      }
    } catch (e) {
      print("Error getting default voice: $e");
    }
  }

  Future<void> _speak() async {
  await flutterTts.setVolume(ttsController.volume.value);
  await flutterTts.setSpeechRate(ttsController.rate.value);
  await flutterTts.setPitch(ttsController.pitch.value);

  if (ttsController.newVoiceText.value.isNotEmpty) { // Sử dụng newVoiceText
    await flutterTts.speak(ttsController.newVoiceText.value);
  } else {
    Get.snackbar(
      "Thông báo",
      "Vui lòng nhập nội dung để đọc",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Colors.white,
    );
  }
}
  Future<void> _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) ttsController.ttsState.value = TtsState.stopped;
  }

  Future<void> _pause() async {
    var result = await flutterTts.pause();
    if (result == 1) ttsController.ttsState.value = TtsState.paused;
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

 void changedEnginesDropDownItem(String? selectedEngine) async {
  if (selectedEngine != null && selectedEngine.isNotEmpty) {
    try {
      await flutterTts.setEngine(selectedEngine);
      ttsController.changeEngine(selectedEngine);
      
      // THÊM DÒNG NÀY: Lưu ngay vào ThemeController
      final themeController = Get.find<ThemeController>();
      themeController.updateTTSSettings(engine: selectedEngine);
    } catch (e) {
      print("Error setting engine: $e");
    }
  }
}

  void changedLanguageDropDownItem(String? selectedType) {
  if (selectedType != null && selectedType.isNotEmpty) {
    try {
      ttsController.changeLanguage(selectedType);
      flutterTts.setLanguage(selectedType);
      
      // THÊM DÒNG NÀY: Lưu ngay vào ThemeController
      final themeController = Get.find<ThemeController>();
      themeController.updateTTSSettings(language: selectedType);
      
      if (isAndroid) {
        flutterTts
            .isLanguageInstalled(selectedType)
            .then((value) => isCurrentLanguageInstalled = (value as bool));
      }
    } catch (e) {
      print("Error setting language: $e");
    }
  }
}

  void _onChange(String text) {
    ttsController.changeVoiceText(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title:  Text(
          "Trợ lý giọng nói",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
            ),
          
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeaderSection(theme),
            const SizedBox(height: 24),

            // Input Section
            _buildInputSection(theme),
            const SizedBox(height: 24),

            // Engine & Language Section
            _buildEngineLanguageSection(theme),
            const SizedBox(height: 24),

            // Control Buttons với Obx
            _buildControlButtons(theme),
            const SizedBox(height: 24),

            // Settings Sliders với Obx
            _buildSettingsSection(theme),
            const SizedBox(height: 24),

            // Save Button
            _buildSaveButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.record_voice_over_rounded,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            "Text-to-Speech Assistant",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Chuyển văn bản thành giọng nói để điều khiển thiết bị thông minh",
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_fields_rounded, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Nội dung văn bản",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              maxLines: 4,
              minLines: 3,
              onChanged: _onChange,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: "Nhập nội dung bạn muốn chuyển thành giọng nói...",
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineLanguageSection(ThemeData theme) {
  return Column(
    children: [
      // Engine Dropdown với GetBuilder
      GetBuilder<TTSController>(
        builder: (controller) {
          return FutureBuilder<List<String>>(
            future: _getEngines(),
            builder: (context, snapshot) {
              final engines = snapshot.data ?? [];
              final hasData = snapshot.hasData && engines.isNotEmpty;
              
              String? currentEngineValue;
              if (hasData && engines.contains(controller.engine.value)) {
                currentEngineValue = controller.engine.value;
              } else if (hasData) {
                currentEngineValue = engines.first;
              } else {
                currentEngineValue = null;
              }

              return _buildDropdownCard(
                theme,
                "Engine TTS",
                Icons.engineering_rounded,
                engines,
                currentEngineValue,
                (val) {
                  if (val != null) {
                    changedEnginesDropDownItem(val);
                  }
                },
                hasData,
                hintText: hasData ? null : "Không có engine nào",
              );
            },
          );
        },
      ),
      const SizedBox(height: 12),
      // Language Dropdown với GetBuilder
      GetBuilder<TTSController>(
        builder: (controller) {
          return FutureBuilder<List<String>>(
            future: _getLanguages(),
            builder: (context, snapshot) {
              final languages = snapshot.data ?? ['vi-VN', 'en-US'];
              final hasData = snapshot.hasData && languages.isNotEmpty;
              
              String? currentLanguageValue;
              if (hasData && languages.contains(controller.language.value)) {
                currentLanguageValue = controller.language.value;
              } else if (hasData) {
                currentLanguageValue = languages.first;
              } else {
                currentLanguageValue = 'vi-VN';
              }

              return _buildDropdownCard(
                theme,
                "Ngôn ngữ",
                Icons.language_rounded,
                languages,
                currentLanguageValue,
                (val) {
                  if (val != null) {
                    changedLanguageDropDownItem(val);
                  }
                },
                hasData,
                hintText: hasData ? null : "Đang tải...",
              );
            },
          );
        },
      ),
    ],
  );
}
  Widget _buildDropdownCard(
    ThemeData theme,
    String title,
    IconData icon,
    List<String> items,
    String? value,
    Function(String?) onChange,
    bool hasData, {
    String? hintText,
  }) {
    // Tạo danh sách items unique để tránh lỗi duplicate
    final uniqueItems = items.toSet().toList();
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down_rounded, color: theme.colorScheme.primary),
                  underline: const SizedBox(),
                  items: uniqueItems.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: hasData ? onChange : null,
                  hint: hintText != null ? Text(hintText) : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons(ThemeData theme) {
  return GetBuilder<TTSController>(
    builder: (controller) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              "Điều khiển phát",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  theme,
                  Icons.play_arrow_rounded,
                  "Phát",
                  Colors.green,
                  _speak,
                  controller.ttsState.value == TtsState.playing,
                ),
                _buildControlButton(
                  theme,
                  Icons.pause_rounded,
                  "Tạm dừng",
                  Colors.orange,
                  _pause,
                  controller.ttsState.value == TtsState.paused,
                ),
                _buildControlButton(
                  theme,
                  Icons.stop_rounded,
                  "Dừng",
                  Colors.red,
                  _stop,
                  controller.ttsState.value == TtsState.stopped,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor(theme, controller.ttsState.value),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusText(controller.ttsState.value),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
  Widget _buildControlButton(
    ThemeData theme,
    IconData icon,
    String label,
    Color color,
    Function onTap,
    bool isActive,
  ) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(isActive ? 0.9 : 0.7),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => onTap(),
            icon: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(ThemeData theme) {
  return GetBuilder<TTSController>(
    builder: (controller) {
      return Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.settings_rounded, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Cài đặt giọng nói",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSliderSetting(
                theme,
                "Âm lượng",
                Icons.volume_up_rounded,
                controller.volume.value,
                (v) {
                  controller.volume.value = v;
                  controller.update(); // Force update
                },
                0.0,
                1.0,
              ),
              const SizedBox(height: 16),
              _buildSliderSetting(
                theme,
                "Cao độ",
                Icons.graphic_eq_rounded,
                controller.pitch.value,
                (v) {
                  controller.pitch.value = v;
                  controller.update(); // Force update
                },
                0.5,
                2.0,
              ),
              const SizedBox(height: 16),
              _buildSliderSetting(
                theme,
                "Tốc độ",
                Icons.speed_rounded,
                controller.rate.value,
                (v) {
                  controller.rate.value = v;
                  controller.update(); // Force update
                },
                0.0,
                1.0,
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildSliderSetting(
    ThemeData theme,
    String label,
    IconData icon,
    double value,
    Function(double) onChanged,
    double min,
    double max,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          onChanged: onChanged,
          min: min,
          max: max,
          activeColor: theme.colorScheme.primary,
          inactiveColor: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: saveTTSSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_rounded, size: 20),
            SizedBox(width: 8),
            Text(
              "Lưu cài đặt",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ThemeData theme, TtsState state) {
  switch (state) {
    case TtsState.playing:
      return Colors.green;
    case TtsState.paused:
      return Colors.orange;
    case TtsState.continued:
      return Colors.blue;
    case TtsState.stopped:
      return Colors.grey;
    default:
      return theme.colorScheme.primary;
  }
}

String _getStatusText(TtsState state) {
  switch (state) {
    case TtsState.playing:
      return "Đang phát";
    case TtsState.paused:
      return "Tạm dừng";
    case TtsState.continued:
      return "Tiếp tục";
    case TtsState.stopped:
      return "Đã dừng";
    default:
      return "Sẵn sàng";
  }
}
}