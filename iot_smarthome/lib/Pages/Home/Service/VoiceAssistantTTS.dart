import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:flutter_tts/flutter_tts_web.dart';
enum TtsState { playing, stopped, paused, continued }

class VoiceAssistantTTS extends StatefulWidget {
  const VoiceAssistantTTS({super.key});

  @override
  State<VoiceAssistantTTS> createState() => _VoiceAssistantTTSState();
}

class _VoiceAssistantTTSState extends State<VoiceAssistantTTS> {
  late FlutterTts flutterTts;
  String? language;
  String? engine;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;

  bool isCurrentLanguageInstalled = false;

  String? _newVoiceText;
  int? _inputLength;
  TtsState ttsState = TtsState.stopped;

  bool get isPlaying => ttsState == TtsState.playing;
  bool get isStopped => ttsState == TtsState.stopped;
  bool get isPaused => ttsState == TtsState.paused;
  bool get isContinued => ttsState == TtsState.continued;

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

  // Chỉ gọi setEngine trên Android/iOS
  if (!kIsWeb && Platform.isAndroid) {
    await flutterTts.setEngine("com.google.android.tts"); // Google TTS
  }

  await flutterTts.setLanguage("vi-VN");

  _setAwaitOptions();

  if (!kIsWeb && Platform.isAndroid) {
    _getDefaultEngine();
    _getDefaultVoice();
  }

  // Handlers
  flutterTts.setStartHandler(() {
    setState(() {
      print("Playing");
      ttsState = TtsState.playing;
    });
  });

  flutterTts.setCompletionHandler(() {
    setState(() {
      print("Complete");
      ttsState = TtsState.stopped;
    });
  });

  flutterTts.setCancelHandler(() {
    setState(() {
      print("Cancel");
      ttsState = TtsState.stopped;
    });
  });

  flutterTts.setPauseHandler(() {
    setState(() {
      print("Paused");
      ttsState = TtsState.paused;
    });
  });

  flutterTts.setContinueHandler(() {
    setState(() {
      print("Continued");
      ttsState = TtsState.continued;
    });
  });

  flutterTts.setErrorHandler((msg) {
    setState(() {
      print("error: $msg");
      ttsState = TtsState.stopped;
    });
  });
}


  Future<List<String>> _getLanguages() async {
  final langs = await flutterTts.getLanguages;
  if (langs is List) {
    return langs.cast<String>();
  } else {
    return [];
  }
}
Future<void> loadTTSSettings() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    pitch = prefs.getDouble('tts_pitch') ?? 1.0;
    rate = prefs.getDouble('tts_rate') ?? 0.5;
    volume = prefs.getDouble('tts_volume') ?? 1.0;
    language = prefs.getString('tts_language') ?? 'en-US';
  });
}
  Future<void> saveTTSSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_pitch', pitch);
    await prefs.setDouble('tts_rate', rate);
    await prefs.setDouble('tts_volume', volume);
    if (language != null) await prefs.setString('tts_language', language!);
    if (engine != null) await prefs.setString('tts_engine', engine!);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Đã lưu cài đặt TTS!"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

Future<List<String>> _getEngines() async {
  final engines = await flutterTts.getEngines;
  if (engines is List) {
    return engines.cast<String>();
  } else {
    return [];
  }
}


  Future<void> _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      print(engine);
    }
  }

  Future<void> _getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {
      print(voice);
    }
  }

  Future<void> _speak() async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (_newVoiceText != null) {
      if (_newVoiceText!.isNotEmpty) {
        await flutterTts.speak(_newVoiceText!);
      }
    }
  }

  Future<void> _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  Future<void> _pause() async {
    var result = await flutterTts.pause();
    if (result == 1) setState(() => ttsState = TtsState.paused);
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  List<DropdownMenuItem<String>> getEnginesDropDownMenuItems(
      List<dynamic> engines) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in engines) {
      items.add(DropdownMenuItem(
          value: type as String?, child: Text((type as String))));
    }
    return items;
  }

  void changedEnginesDropDownItem(String? selectedEngine) async {
    await flutterTts.setEngine(selectedEngine!);
    language = null;
    setState(() {
      engine = selectedEngine;
    });
  }

  List<DropdownMenuItem<String>> getLanguageDropDownMenuItems(
      List<dynamic> languages) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in languages) {
      items.add(DropdownMenuItem(
          value: type as String?, child: Text((type as String))));
    }
    return items;
  }

  void changedLanguageDropDownItem(String? selectedType) {
    setState(() {
      language = selectedType;
      flutterTts.setLanguage(language!);
      if (isAndroid) {
        flutterTts
            .isLanguageInstalled(language!)
            .then((value) => isCurrentLanguageInstalled = (value as bool));
      }
    });
  }

  void _onChange(String text) {
    setState(() {
      _newVoiceText = text;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Assistant Text-to-Speech"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.indigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _inputSection(),
            const SizedBox(height: 20),
            _engineSection(),
            const SizedBox(height: 10),
            _languageSection(),
            const SizedBox(height: 20),
            _controlButtons(),
            const SizedBox(height: 20),
            _sliderSection(),
            if (isAndroid) _getMaxSpeechInputLengthSection(),
            const SizedBox(height: 30),

            // 👉 Nút lưu ở cuối trang
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: saveTTSSettings,
                icon: const Icon(Icons.save_rounded),
                label: const Text("Lưu cài đặt"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputSection() => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            maxLines: 6,
            minLines: 4,
            onChanged: _onChange,
            decoration: const InputDecoration(
              labelText: "Nhập nội dung để đọc",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.text_fields_rounded),
            ),
          ),
        ),
      );

  Widget _engineSection() => FutureBuilder<List<String>>(
        future: _getEngines(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _dropdownCard(
              "Chọn Engine",
              snapshot.data!,
              engine,
              (val) => setState(() => engine = val),
            );
          }
          return const Text("Đang tải engines...");
        },
      );

  Widget _languageSection() => FutureBuilder<List<String>>(
        future: _getLanguages(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _dropdownCard(
              "Chọn Ngôn ngữ",
              snapshot.data!,
              language,
              (val) => setState(() => language = val),
            );
          }
          return const Text("Đang tải ngôn ngữ...");
        },
      );

  Widget _dropdownCard(String title, List<String> items, String? value, Function(String?) onChange) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: value,
                items: items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: onChange,
                decoration: InputDecoration(
                  labelText: title,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _roundButton(Icons.play_arrow, Colors.green, _speak),
          _roundButton(Icons.stop, Colors.redAccent, _stop),
          _roundButton(Icons.pause, Colors.orange, _pause),
        ],
      );

  Widget _roundButton(IconData icon, Color color, Function onTap) {
    return InkWell(
      onTap: () => onTap(),
      borderRadius: BorderRadius.circular(40),
      child: Ink(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _sliderSection() => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(top: 10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _slider("Âm lượng", volume, (v) => setState(() => volume = v), 0.0, 1.0),
              _slider("Cao độ", pitch, (v) => setState(() => pitch = v), 0.5, 2.0),
              _slider("Tốc độ", rate, (v) => setState(() => rate = v), 0.0, 1.0),
            ],
          ),
        ),
      );

  Widget _slider(String label, double value, Function(double) onChanged, double min, double max) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ${value.toStringAsFixed(2)}"),
        Slider(value: value, onChanged: onChanged, min: min, max: max),
      ],
    );
  }

  Widget _getMaxSpeechInputLengthSection() {
    return Column(
      children: [
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () async {
            setState(() => _inputLength = 500); // ví dụ
          },
          icon: const Icon(Icons.info_outline),
          label: const Text('Lấy độ dài nhập tối đa'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 6),
        Text("Độ dài tối đa: $_inputLength ký tự"),
      ],
    );
  }

}