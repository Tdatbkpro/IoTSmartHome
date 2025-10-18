import 'dart:ui';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Config/Icons.dart';
import 'package:iot_smarthome/Config/MyException.dart';
import 'package:iot_smarthome/Controllers/DeviceController.dart';
import 'package:iot_smarthome/Controllers/TTSController.dart';
import 'package:iot_smarthome/Controllers/VoiceAssistantController.dart';
import 'package:iot_smarthome/Models/DeviceStatusModel.dart';
import 'package:iot_smarthome/Models/RoomModel.dart';
import 'package:iot_smarthome/Pages/Home/Dialog.dart';
import 'package:iot_smarthome/Pages/Home/HomePage.dart';
import 'package:iot_smarthome/Pages/Home/Service/ScheduleService.dart';
import 'package:iot_smarthome/Pages/Home/Widget/CustomTimePicker.dart';
import 'package:lottie/lottie.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
class RoomDetailPage extends StatefulWidget {
  final String homeId;
  final RoomModel room;
  final List<Device> devices;

  const RoomDetailPage({
    super.key,
    required this.room,
    required this.devices,
    required this.homeId,
  });

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  final deviceController = Get.put(DeviceController());
   late stt.SpeechToText _speech;
  bool _isListening = false;
  final RxBool isEditing = false.obs;
late TextEditingController controller;
  String _text = "Nhấn giữ mic để bắt đầu nói...";
  Function(String)? _updateDialogText; // callback để update text trong dialog
  @override
  void initState() {
    super.initState();
     _speech = stt.SpeechToText();
     controller = TextEditingController(text: _text);
  }
  void _showListeningDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          // gán callback để onResult gọi trực tiếp update dialog
          _updateDialogText = (String newText) {
            setStateDialog(() {
              _text = newText;
            });
          };

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Trợ lý giọng nói",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/lotties/voice.json',
                  width: 80,
                  height: 80,
                  repeat: true,
                ),
                const SizedBox(height: 10),
                Text(
                  _text,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Lottie.asset(
                  'assets/lotties/recording.json',
                  repeat: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _stopListening();
                },
                child: const Text("Dừng lại"),
              )
            ],
          );
        },
      );
    },
  ).then((_) {
    // reset callback khi dialog đóng
    _updateDialogText = null;
  });
}

void _startListening() async {
  TTSController.instance.speak("Xin chào, tôi là trợ lý ra lệnh bằng giọng nói");

  bool available = await _speech.initialize(
    onStatus: (val) => print("Status: $val"),
    onError: (val) => print("Error: $val"),
  );
  if (available) {
    _isListening = true;
    _text = "🎤 Đang ghi âm...";
    _showListeningDialog();

    _speech.listen(
      localeId: "vi_VN", // Tiếng Việt
      //listenFor: const Duration(seconds: 10),
      listenMode: stt.ListenMode.confirmation,
      onResult: (val) {
        if (_updateDialogText != null) {
          _text = val.recognizedWords;        // cập nhật dữ liệu class
          _updateDialogText!(val.recognizedWords); // cập nhật UI dialog
        }
      },

    );
  }
}

  /// Dừng ghi âm
   void result() {
  deviceController.handleVoiceCommand(
    context,
    widget.homeId,
    widget.room.id,
    _text,
    (selectedDevices) async {
      final commands = VoiceAssistantController.parseMultipleCommands(_text);

            for (var d in selectedDevices) {
              print("👉 Điều khiển thiết bị: ${d.name} (${d.type})");

              // Lấy trạng thái hiện tại
              DeviceStatus statusDevice = await deviceController
                  .getDeviceStatus(widget.homeId, widget.room.id, d.id)
                  .first;

              // Xử lý từng lệnh
              for (var cmd in commands) {
                final action = cmd['action'] as DeviceAction;
                final value = cmd['value'];

                switch (action) {
                  case DeviceAction.turnOn:
                    statusDevice.status = true;
                    break;
                  case DeviceAction.turnOff:
                    statusDevice.status = false;
                    break;
                  case DeviceAction.setHumidity:
                    if (value == null) throw MyCustomException("Không tìm thấy giá trị cần điều chỉnh độ ẩm");
                    statusDevice.humidity = value.toDouble();
                    break;
                  case DeviceAction.setTemperature:
                    if (value == null) throw MyCustomException("Không tìm thấy giá trị cần điều chỉnh nhiệt độ");
                    statusDevice.temperature = value.toDouble();
                    break;
                  case DeviceAction.setSpeed:
                    if (value == null) throw MyCustomException("Không tìm thấy giá trị cần điều chỉnh tốc độ");
                    if (statusDevice.status) {
                      statusDevice.speed = value.toDouble();
                    } else {
                      throw MyCustomException("${d.type} ${d.name} đang tắt");
                    }
                    
                    break;
                  case DeviceAction.setMode:
                    statusDevice.mode = "Mạnh"; // hoặc tùy theo logic
                    break;

                  case DeviceAction.increaseTemperature:
                    if (value == null) throw MyCustomException("Không tìm thấy giá trị tăng nhiệt độ");
                    statusDevice.temperature += value.toDouble();
                    break;
                  case DeviceAction.decreaseTemperature:
                    if (value == null) throw MyCustomException("Không tìm thấy giá trị giảm nhiệt độ");
                    statusDevice.temperature -= value.toDouble();
                    break;
                  case DeviceAction.increaseHumidity:
                    if (value == null) throw MyCustomException("Không tìm thấy giá trị tăng độ ẩm");
                    statusDevice.humidity += value.toDouble();
                    break;
                  case DeviceAction.decreaseHumidity:
                    if (value == null) throw MyCustomException("Không tìm thấy giá trị giảm độ ẩm");
                    statusDevice.humidity -= value.toDouble();
                    break;
                  case DeviceAction.increaseSpeed:
                    if (value == null) throw MyCustomException("Không tìm thấy giá trị tăng tốc độ");
                    statusDevice.speed += value.toDouble();
                    break;
                  case DeviceAction.decreaseSpeed:
                    if (value == null) throw MyCustomException("Không tìm thấy giá trị giảm tốc độ");
                    statusDevice.speed -= value.toDouble();
                    break;
                }
              }

              // Cập nhật trạng thái thiết bị
              await deviceController.updateStatus(widget.homeId, widget.room.id, d.id, statusDevice);
              TTSController.instance.speak("Đã thực hiện ${_text}");

            };
    }
  );
}

void _stopListening() async {
  await _speech.stop();
  _isListening = false;

  if (context.mounted) {
    controller.text = _text;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text("Bạn đã ra lệnh"),
          content: Obx(() {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: isEditing.value
                      ? TextField(
                          controller: controller,
                          autofocus: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          maxLines: null,
                        )
                      : Text(
                          controller.text.isNotEmpty
                              ? controller.text
                              : "Không nhận diện được",
                        ),
                ),
                IconButton(
                  icon: Icon(isEditing.value ? Icons.check : Icons.edit),
                  onPressed: () {
                    if (isEditing.value) {
                      // ✅ Lưu lại text khi bấm check
                      _text = controller.text;
                    }
                    isEditing.toggle(); // ✅ toggle trạng thái
                  },
                ),
              ],
            );
          }),
          actions: [
            TextButton(
              child: const Text("Hủy"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("Xác nhận"),
              onPressed: () {
                try {
                  _text = controller.text;
                Navigator.of(context).pop();
                result();
                }  catch (e, stackTrace) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                      debugPrintStack(stackTrace: stackTrace);
                    }// gọi hàm xử lý voice
              },
            ),
          ],
        );
      },
    );
  }
}

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: ConvexAppBar(
          style: TabStyle.react,
          backgroundColor: Colors.white,
          activeColor: _isListening ? Colors.red : Colors.blue,
          items: [
            TabItem(
              // bọc icon mic bằng GestureDetector để nhấn giữ
              icon: GestureDetector(
                onTap: _startListening,
                child: Lottie.asset(
                      'assets/lotties/voice.json',
                      width: 70,
                      height: 70,
                      repeat: true,
                      onLoaded: (composition) {
                        Future.delayed(const Duration(seconds: 3), () {
                          // Navigator.pushReplacementNamed(context, '/home');
                        });
                      },
                    )
              ),
              title: 'Voice assistant',
              
            ),

          ],
          initialActiveIndex: 0, // mic mặc định ở giữa
          onTap: (index) {
            
          },
        ),

      body: CustomScrollView(
        slivers: [
          // ================== AppBar ==================
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "${widget.room.type} - ${widget.room.name}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 6,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
              collapseMode: CollapseMode.parallax,
              background: widget.room.image != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.room.image!,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                                Colors.black.withOpacity(0.5),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(color: Colors.grey[800]),
            ),
          ),

          // ================== Grid ==================
          SliverPadding(
          padding: const EdgeInsets.all(10),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = (constraints.crossAxisExtent / 200).floor();
              if (crossAxisCount < 1) crossAxisCount = 1;

              return StreamBuilder<List<Device>>(
                stream: deviceController.streamDevices(widget.homeId, widget.room.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final devices = snapshot.data!;

                  return SliverStaggeredGrid.countBuilder(
                    addAutomaticKeepAlives: true,
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return StreamBuilder<DeviceStatus>(
                        stream: deviceController.getDeviceStatus(
                          widget.homeId,
                          widget.room.id,
                          device.id,
                        ),
                        builder: (context, snap) {
                          final data = snap.data ?? DeviceStatus(status: false);

                          final child = switch (device.type) {
                            "Temperature Humidity Sensor" => _buildTempHumidityCard(data),
                            "Gas Sensor" => _buildGaugeCard(
                              title: "Khí gas",
                              value: double.tryParse(data.mode) ?? 0,
                              unit: "ppm",
                              color: Colors.redAccent,
                              min: 0,
                              max: 1000,
                            ),
                            "Fan" => _buildFanCard(
                              data.speed,
                              device.id,
                              data.status,
                            ),
                            _ => _buildSwitchCard(
                              device.name ?? "Unknown",
                              data.status,
                              getDeviceIcon(device.type ?? "", data.status),
                              device.id,
                            ),
                          };

                          return Stack(
                            children: [
                              SizedBox.expand(child: child),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: PopupMenuButton<String>(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: "edit",
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 10),
                                          Text("Sửa"),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: "delete",
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete),
                                          SizedBox(width: 10),
                                          Text("Xóa"),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: "alarm",
                                      child: Row(
                                        children: [
                                          Icon(Icons.alarm),
                                          SizedBox(width: 10),
                                          Text("Hẹn giờ ${data.status ? "tắt" : "bật"}"),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) async {
                                    if (value == "delete") {
                                      DialogUtils.showConfirmDialog(
                                        context,
                                        "Xác nhận hủy",
                                        Text("Thiết bị ${device.type} - ${device.name}"),
                                        () async {
                                          await deviceController.deleteDevice(
                                            widget.homeId,
                                            widget.room.id,
                                            device.id,
                                          );
                                        },
                                      );
                                    } else if (value == "alarm") {
                                      DatePicker.showPicker(
                                        context,
                                        showTitleActions: true,
                                        pickerModel: CustomPicker(
                                          currentTime: DateTime.now()
                                        ),
                                        onChanged: (time) {
                                          //
                                        },
                                        onConfirm: (time) async {
                                          if (!mounted) return; // <- thêm dòng này
                                          print("Xác nhận: $time"); 
                                          ScheduleService.start(widget.homeId, widget.room.id);
                                          ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text("Bạn đã chọn: $time")), );
                                         await deviceController.addSchedule(
                                        homeId: widget.homeId,
                                        roomId: widget.room.id,
                                        deviceId: device.id,
                                        action: data.status ? 0 : 1, // 1 = bật, 0 = tắt
                                        time: time,
                                          );
                                        },
                                        );
                                    }
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    staggeredTileBuilder: (index) {
                      final device = devices[index];
                      if (device.type == "Temperature Humidity Sensor") {
                        return const StaggeredTile.count(2, 1);
                      }
                      return const StaggeredTile.count(1, 1);
                    },
                  );
                },
              );
            },
          ),
        ),


        ],
      ),
    );
  }

  // ================== Widgets ==================

  Widget _buildTempHumidityCard(DeviceStatus data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(2, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: _buildGaugeCard(
              title: "Nhiệt độ",
              value: (data.temperature ?? 0).toDouble(),
              unit: "°C",
              color: Colors.deepOrangeAccent,
              min: 0,
              max: 100,
            ),
          ),
          Expanded(
            child: _buildGaugeCard(
              title: "Độ ẩm",
              value: (data.humidity ?? 0).toDouble(),
              unit: "%",
              color: Colors.blueAccent,
              min: 0,
              max: 100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeCard({
    required String title,
    required double value,
    required String unit,
    required Color color,
    required double min,
    required double max,
  }) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[200]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                )),
            Expanded(
              child: SfRadialGauge(
                axes: [
                  RadialAxis(
                    minimum: min,
                    maximum: max,
                    axisLineStyle: const AxisLineStyle(
                      thickness: 0.15,
                      thicknessUnit: GaugeSizeUnit.factor,
                    ),
                    ranges: [
                      GaugeRange(
                        startValue: min,
                        endValue: max,
                        color: color.withOpacity(0.3),
                      ),
                    ],
                    pointers: [NeedlePointer(value: value, needleColor: color)],
                    annotations: [
                      GaugeAnnotation(
                        widget: Text(
                          "${value.toStringAsFixed(1)} $unit",
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        angle: 90,
                        positionFactor: 0.7,
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchCard(
      String name, bool initial, String? iconPath, String deviceId) {
    ValueNotifier<bool> switchValue = ValueNotifier(initial);

    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[200]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconPath != null)
              Image.asset(iconPath, width: 50, height: 50, fit: BoxFit.contain)
            else
              const Icon(Icons.device_unknown, size: 40, color: Colors.black87),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<bool>(
              valueListenable: switchValue,
              builder: (_, val, __) => Switch(
                value: val,
                activeColor: Colors.green,
                onChanged: (v) {
                  switchValue.value = v;
                  deviceController.updateStatus(
                    widget.homeId,
                    widget.room.id,
                    deviceId,
                    DeviceStatus(status:  switchValue.value ? true : false)
                  );
                  
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFanCard(double speed, String deviceId, bool isOn) {
    ValueNotifier<bool> switchValue = ValueNotifier(isOn);
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[200]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            const Text(
              "Quạt",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            Expanded(
              child: SleekCircularSlider(
                appearance: CircularSliderAppearance(
                  customColors: CustomSliderColors(
                    progressBarColor: Colors.green,
                    dotColor: Colors.greenAccent,
                    trackColor: Colors.black12,
                  ),
                  size: 160,
                ),
                min: 0,
                max: 100,
                initialValue: speed.toDouble(),
                onChangeEnd: isOn
                    ? (val) {
                        deviceController.updateStatus(
                          widget.homeId,
                          widget.room.id,
                          deviceId,
                          DeviceStatus(status: isOn, speed: val),
                        );
                      }
                    : null,
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: switchValue,
              builder: (_, val, __) => Switch(
                value: val,
                activeColor: Colors.green,
                onChanged: (v) {
                  switchValue.value = v;
                  deviceController.updateStatus(
                    widget.homeId,
                    widget.room.id,
                    deviceId,
                    DeviceStatus(status: switchValue.value ? true : false)
                  );
                },
              ),
            ),
            if (!isOn)
              const Text(
                "Quạt đang tắt",
                style: TextStyle(color: Colors.redAccent),
              ),
          ],
        ),
      ),
    );
  }
}
