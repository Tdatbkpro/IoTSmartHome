import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechMicPage extends StatefulWidget {
  const SpeechMicPage({super.key});

  @override
  State<SpeechMicPage> createState() => _SpeechMicPageState();
}

class _SpeechMicPageState extends State<SpeechMicPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "Nhấn giữ mic để bắt đầu nói...";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  /// Bắt đầu ghi âm
  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) => print("Status: $val"),
      onError: (val) => print("Error: $val"),
    );
    if (available) {
      setState(() {
        _isListening = true;
        _text = "🎤 Đang ghi âm...";
      });
      _speech.listen(
        localeId: "vi_VN", // nhận diện tiếng Việt
        onResult: (val) {
          setState(() {
            _text = val.recognizedWords;
          });
        },
      );
    }
  }

  /// Dừng ghi âm
  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
    // Hiện Alert thông báo
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Kết quả"),
          content: Text(_text.isNotEmpty ? _text : "Không nhận diện được"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Đóng"),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Speech to Text Demo")),
      body: Center(
        child: Text(
          _text,
          style: const TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        child: GestureDetector(
          onLongPress: _startListening, // nhấn giữ bắt đầu
          onLongPressUp: _stopListening, // thả tay thì dừng
          child: CircleAvatar(
            radius: 35,
            backgroundColor: _isListening ? Colors.red : Colors.blue,
            child: const Icon(Icons.mic, size: 40, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
