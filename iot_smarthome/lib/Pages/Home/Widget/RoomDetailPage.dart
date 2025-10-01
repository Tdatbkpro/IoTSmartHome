import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Config/Icons.dart';
import 'package:iot_smarthome/Controllers/DeviceController.dart';
import 'package:iot_smarthome/Models/DeviceStatusModel.dart';
import 'package:iot_smarthome/Models/RoomModel.dart';
import 'package:iot_smarthome/Pages/Home/Dialog.dart';
import 'package:iot_smarthome/Pages/Home/HomePage.dart';
import 'package:iot_smarthome/Pages/Home/Service/ScheduleService.dart';
import 'package:iot_smarthome/Pages/Home/Widget/CustomTimePicker.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

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
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                            "Cảm biến nhiệt độ & độ ẩm" => _buildTempHumidityCard(data),
                            "Cảm biến khí gas" => _buildGaugeCard(
                              title: "Khí gas",
                              value: double.tryParse(data.mode ?? "0") ?? 0,
                              unit: "ppm",
                              color: Colors.redAccent,
                              min: 0,
                              max: 1000,
                            ),
                            "Quạt" => _buildFanCard(
                              data.speed ?? 50,
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
                                        "Thiết bị ${device.type} - ${device.name}",
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
                      if (device.type == "Cảm biến nhiệt độ & độ ẩm") {
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
                    {"status": switchValue.value ? 1 : 0},
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
                          {"speed": val},
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
                    {"status": switchValue.value ? 1 : 0},
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
