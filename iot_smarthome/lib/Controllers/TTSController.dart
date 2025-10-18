import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TTSController {
  static final TTSController instance = TTSController._internal();
  factory TTSController() => instance;

  late FlutterTts flutterTts;
  bool _initialized = false;

  double volume = 1.0;
  double pitch = 1.0;
  double rate = 0.5;
  String language = "vi-VN";

  TTSController._internal();

  Future<void> init() async {
    if (_initialized) return;
    flutterTts = FlutterTts();

    // Tải cấu hình cache
    final prefs = await SharedPreferences.getInstance();
    pitch = prefs.getDouble('tts_pitch') ?? 1.0;
    rate = prefs.getDouble('tts_rate') ?? 0.5;
    volume = prefs.getDouble('tts_volume') ?? 1.0;
    language = prefs.getString('tts_language') ?? "vi-VN";

    await flutterTts.setLanguage(language);
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    _initialized = true;
  }

  Future<void> speak(String text) async {
    await init();
    if (text.isNotEmpty) {
      await flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    await flutterTts.stop();
  }
}
