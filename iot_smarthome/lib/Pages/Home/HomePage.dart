
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/intl.dart';
import 'package:iot_smarthome/Pages/Home/Widget/ConfigHome.dart';
import 'package:iot_smarthome/Pages/Home/Widget/CreateQrDevice.dart';
import 'package:iot_smarthome/Pages/Home/Widget/EnergyConsumptionPage.dart';
import 'package:iot_smarthome/Pages/Home/Widget/WeatherInfo.dart';
import 'package:iot_smarthome/Pages/Notification/NotificationsPage.dart';
import 'package:iot_smarthome/Providers/AuthProvider.dart';
import 'package:iot_smarthome/Providers/Location&WeatherProvider.dart';
import 'package:iot_smarthome/Services/WeatherService.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:animations/animations.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/rendering.dart';
import 'package:flutter_timer_countdown/flutter_timer_countdown.dart';

import 'package:image_picker/image_picker.dart';
import 'package:iot_smarthome/Config/Icons.dart';
import 'package:iot_smarthome/Controllers/DeviceController.dart';
import 'package:iot_smarthome/Controllers/PickImageController.dart';
import 'package:iot_smarthome/Models/DeviceStatusModel.dart';
import 'package:iot_smarthome/Models/HomeModel.dart';
import 'package:iot_smarthome/Models/RoomModel.dart';
import 'package:iot_smarthome/Pages/Home/Dialog.dart';
import 'package:iot_smarthome/Pages/Profile/ProfilePage.dart';
import 'package:iot_smarthome/Pages/Home/Widget/RoomDetailPage.dart';
import 'package:iot_smarthome/Pages/Settings/SettingPage.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
//import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:uuid/uuid.dart';
import '../../Models/UserModel.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Config/Images.dart';
import 'package:iot_smarthome/Config/Texts.dart';
import 'package:iot_smarthome/Controllers/Auth.dart';
import 'package:kf_drawer/kf_drawer.dart';

// ---------------- Home Dashboard ----------------
class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({super.key});

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard> {
  final authController = Get.put(AuthController());
  final deviceController = Get.put(DeviceController());
  final firebaseUser = FirebaseAuth.instance.currentUser;
  final showPersistentHeaderProvider = StateProvider<bool>((ref) => false);


  @override
  void initState() {
    super.initState();
    if (firebaseUser != null) {
      deviceController.streamAllHomes(firebaseUser!.uid);
    }

    
  }

 Widget _buildBackground() {
  return ImageFiltered(
    imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade800,
            Colors.blue.shade600,
            Colors.lightBlue.shade400,
          ],
        ),
      ),
      child: Image.asset(
        "assets/images/banner_homepage.png",
        fit: BoxFit.cover,
        color: Colors.black.withOpacity(0.3),
        colorBlendMode: BlendMode.darken,
      ),
    ),
  );
}

Widget _buildContent(double percent, double avatarSize, double topPadding, double offsetX, double offsetY) {
  return Padding(
    padding: EdgeInsets.fromLTRB(16, topPadding, 16, 16),
    child: Consumer(
      builder: (context, ref, child) {
        final userAsync = ref.watch(currentUserDataProvider);
        final addressAsync = ref.watch(currentAddressProvider);
        final weatherAsync = ref.watch(weatherDataProvider);

        return userAsync.when(
          loading: () => _buildUserInfo(percent, avatarSize, "Loading...", null, addressAsync, weatherAsync,ref),
          error: (error, stack) => _buildUserInfo(percent, avatarSize, "Guest", null, addressAsync, weatherAsync,ref),
          data: (user) {
            final userName = _getUserName(user);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Transform.translate(
                    offset: Offset(offsetX, offsetY),
                    child: _buildUserInfo(percent, avatarSize, userName, user, addressAsync, weatherAsync,ref),
                  ),
                ),
                _buildQRButton(percent),
              ],
            );
          },
        );
      },
    ),
  );
}
Widget _buildUserInfo(
  double percent, 
  double avatarSize, 
  String userName, 
  User? user, 
  AsyncValue<String> addressAsync,
  AsyncValue<WeatherData> weatherAsync,
  WidgetRef ref
) {
  return Row(
    children: [
      CircleAvatar(
        radius: avatarSize / 2,
        backgroundImage: _getUserImage(user),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Greeting and user name
            Text(
              _getGreeting(),
              style: TextStyle(
                fontSize: 16 * percent.clamp(0.8, 1.0),
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              userName,
              style: TextStyle(
                fontSize: 20 * percent.clamp(0.8, 1.0),
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 8),
            
            // Location and weather info
           if (percent > 0.9) ...[
             _buildLocationWeatherInfo(percent, addressAsync, weatherAsync,ref),
            
            const SizedBox(height: 4),
            
            // Time info
            _buildTimeInfo(percent),
           ]
          ],
        ),
      ),
    ],
  );
}

Widget _buildLocationWeatherInfo(
  double percent, 
  AsyncValue<String> addressAsync,
  AsyncValue<WeatherData> weatherAsync,
  WidgetRef ref
) {
  return Row(
    children: [
      Icon(Icons.location_on, size: 14 * percent, color: Colors.white70),
      const SizedBox(width: 4),
      Expanded(
        child: addressAsync.when(
          loading: () => Text(
            "Đang lấy vị trí...",
            style: TextStyle(
              fontSize: 12 * percent.clamp(0.7, 1.0),
              color: Colors.white70,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          error: (error, stack) => Text(
            "Không thể lấy vị trí",
            style: TextStyle(
              fontSize: 12 * percent.clamp(0.7, 1.0),
              color: Colors.white70,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          data: (address) => Text(
            address,
            style: TextStyle(
              fontSize: 12 * percent.clamp(0.7, 1.0),
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
      const SizedBox(width: 8),
      
      // Weather info
      weatherAsync.when(
        loading: () => _buildWeatherItem("--°", "☀️", "--%", percent),
        error: (error, stack) => _buildWeatherItem("--°", "☀️", "--%", percent),
        data: (weather) {
          final weatherService = ref.read(weatherServiceProvider);
          final icon = weatherService.getWeatherIcon(weather.condition);
          return _buildWeatherItem(
            "${weather.temperature.toStringAsFixed(0)}°",
            icon,
            "${weather.humidity}%",
            percent,
          );
        },
      ),
    ],
  );
}

Widget _buildWeatherItem(String temp, String icon, String humidity, double percent) {
  return Row(
    children: [
      Text(
        temp,
        style: TextStyle(
          fontSize: 14 * percent.clamp(0.7, 1.0),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(width: 2),
      Text(
        icon,
        style: TextStyle(fontSize: 12 * percent.clamp(0.7, 1.0)),
      ),
      const SizedBox(width: 6),
      Icon(Icons.water_drop, size: 12 * percent, color: Colors.lightBlue.shade200),
      const SizedBox(width: 2),
      Text(
        humidity,
        style: TextStyle(
          fontSize: 12 * percent.clamp(0.7, 1.0),
          color: Colors.white70,
        ),
      ),
    ],
  );
}

Widget _buildTimeInfo(double percent) {
  return StreamBuilder<DateTime>(
    stream: Stream.periodic(const Duration(seconds: 1), (i) => DateTime.now()),
    builder: (context, snapshot) {
      final now = snapshot.data ?? DateTime.now();
      
      return Row(
        children: [
          Icon(Icons.access_time, size: 12 * percent, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            DateFormat('HH:mm • dd/MM/yyyy').format(now),
            style: TextStyle(
              fontSize: 12 * percent.clamp(0.7, 1.0),
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    },
  );
}

Widget _buildQRButton(double percent) {
  final size = 56 * percent.clamp(0.7, 1.0);

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
    ),
    child: IconButton(
      icon: Icon(
        Icons.qr_code_scanner_outlined,
        color: Colors.white,
        size: 24 * percent.clamp(0.7, 1.0),
      ),
      onPressed: () => Navigator.pushNamed(context, "/scan"),
    ),
  );
}

// Helper methods giữ nguyên
String _getUserName(User? user) {
  return user?.name ??
      FirebaseAuth.instance.currentUser?.displayName ??
      FirebaseAuth.instance.currentUser?.email ??
      "Guest";
}

ImageProvider _getUserImage(User? user) {
  if (user?.profileImage != null && user!.profileImage!.isNotEmpty) {
    return NetworkImage(user.profileImage!);
  }
  return const AssetImage("assets/images/default_avatar.png");
}

String _getGreeting() {
  final hour = DateTime.now().hour;
  
  if (hour < 12) {
    return "Chào buổi sáng 🌞";
  } else if (hour < 18) {
    return "Chào buổi chiều ☀️";
  } else {
    return "Chào buổi tối 🌙";
  }
}


  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: CustomScrollView(
      slivers: [
        // SliverAppBar không cần nằm trong Obx
        SliverAppBar(
          pinned: true,
          expandedHeight: 200,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => KFDrawer.of(context)?.toggle(),
          ),
          flexibleSpace: LayoutBuilder(
            builder: (context, constraints) {
              final percent = (constraints.maxHeight - kToolbarHeight) /
                  (200 - kToolbarHeight);
              // SỬA: percent < 0.9 thì hiện, >= 0.9 thì ẩn
              final shouldShowHeader = percent < 0.9;
              
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(showPersistentHeaderProvider.notifier).state = shouldShowHeader;
              });
              
              final avatarSize = 56 * percent.clamp(0.5, 1.0);
              final topPadding = 50 * percent.clamp(0.0, 1.0);
              final offsetX = (1 - percent) * 50;
              final offsetY = (1 - percent) * 25;

              return Stack(
                fit: StackFit.expand,
                children: [
                  _buildBackground(),
                  Container(color: Colors.black.withOpacity(0.3)),
                  _buildContent(percent, avatarSize, topPadding, offsetX, offsetY),
                ],
              );
            },
          ),
        ),
        
        // Weather Header - Consumer riêng
        Consumer(
          builder: (context, ref, child) {
            final isShowPersistentHeader = ref.watch(showPersistentHeaderProvider);
            
            return SliverAnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isShowPersistentHeader ? 1.0 : 0.0,
              sliver: isShowPersistentHeader
                  ? SliverPersistentHeader(
                      pinned: true,
                      delegate: WeatherInfoHeaderDelegate(),
                    )
                  : const SliverToBoxAdapter(child: SizedBox.shrink()),
            );
          },
        ),
        
        // Homes Content - Obx riêng chỉ cho phần homes
        Obx(() {
          final homes = deviceController.homes;
          final joinedHomes = deviceController.homeJoineds;
          
          if (homes.isEmpty && joinedHomes.isEmpty) {
            return const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.home_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "Chưa có home nào",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          
          return SliverList(
            delegate: SliverChildListDelegate([
              // My Homes Section
              if (homes.isNotEmpty) ...[
                _buildSectionHeader(
                  title: "Home của tôi",
                  icon: Icons.home_outlined,
                ),
                ...homes.map((home) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: _buildHomeSection(home),
                )).toList(),
              ],
              
              // Joined Homes Section
              if (joinedHomes.isNotEmpty) ...[
                _buildSectionHeader(
                  title: "Home đã tham gia",
                  icon: Icons.group_outlined,
                ),
                ...joinedHomes.map((joinedHome) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: _buildHomeSection(joinedHome),
                )).toList(),
              ],
            ]),
          );
        }),

        // Shared Rooms Section - Sliver riêng
        SliverToBoxAdapter(
          child: StreamBuilder<List<RoomModel>>(
            stream: deviceController.streamSharedRooms(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final sharedRooms = snapshot.data!;
              if (sharedRooms.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 40),
                    const Text(
                      "🔗 Phòng được chia sẻ với tôi",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...sharedRooms.map(
                      (room) => _buildSharedRoomCard(room, room.hoomId!),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        AddHomePage(isAddHome: true).show(context);
      },
      child: const Icon(Icons.add_rounded),
    ),
  );
}

// Widget cho section header
Widget _buildSectionHeader({required String title, required IconData icon}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  );
}
Future<void> _shareRoom(BuildContext context, HomeModel home, String roomId) async {
  final expireTime = DateTime.now().add(const Duration(minutes: 15));

  final dataMap = {
    "roomId": roomId,
    "homeId": home.id,
    "ownerId": home.ownerId,
    "expire": expireTime.millisecondsSinceEpoch,
  };

  final dataJson = jsonEncode(dataMap);

  // Tạo global key cho QR code
  final qrKey = GlobalKey();

  // Hàm chụp ảnh QR code
  Future<Uint8List?> captureQRCode() async {
    try {
      final RenderRepaintBoundary boundary = qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();
      return pngBytes;
    } catch (e) {
      print('Lỗi chụp QR: $e');
      return null;
    }
  }

  // Hàm tải QR code và lưu vào gallery
  Future<void> downloadQRCode() async {
  try {
    // 🔹 Kiểm tra và xin quyền lưu ảnh
    PermissionStatus status;

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
      }
    } else {
      // 🔹 Android 13+ dùng quyền "mediaLibrary" hoặc "storage"
      status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
    }

    if (status.isGranted) {
      // 🔹 Tạo ảnh QR từ widget (nếu có)
      final Uint8List? qrBytes = await captureQRCode();
      if (qrBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi khi tạo QR code"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 🔹 Lưu ảnh vào thư viện
      final result = await ImageGallerySaverPlus.saveImage(
        qrBytes,
        name: 'QR_Phong_${home.name}_$roomId',
        quality: 100,
      );

      if (result['isSuccess'] == true || result['filePath'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Đã lưu QR code vào thư viện ảnh"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Lỗi khi lưu vào thư viện ảnh"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Cần cấp quyền truy cập thư viện ảnh để lưu QR"),
          backgroundColor: Colors.orange,
        ),
      );
      await openAppSettings(); // Mở trang cài đặt quyền
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Lỗi khi lưu: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  // Hàm chia sẻ QR code
  Future<void> shareQRCode() async {
    try {
      final Uint8List? qrBytes = await captureQRCode();
      if (qrBytes != null) {
        // Tạo file tạm để chia sẻ
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/qr_room_${roomId}_${DateTime.now().millisecondsSinceEpoch}.png';
        final File imageFile = File(filePath);
        await imageFile.writeAsBytes(qrBytes);

        await Share.shareXFiles(
          [XFile(imageFile.path)],
          text: 'Mời bạn tham gia phòng "${home.name}"\nMã phòng: $roomId\nQR code sẽ hết hạn sau 15 phút',
          subject: 'Mời tham gia phòng ${home.name}',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi khi tạo QR code để chia sẻ"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi khi chia sẻ: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  return showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade50,
                Colors.white,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Chia sẻ phòng",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // QR Code Container với RepaintBoundary
              RepaintBoundary(
                key: qrKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.blue.shade100, width: 1),
                  ),
                  child: QrImageView(
                    data: dataJson,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.blue,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.circle,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Room Info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      home.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Mã phòng: $roomId",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 8),
                    TimerCountdown(
                      format: CountDownTimerFormat.minutesSeconds,
                      endTime: expireTime,
                      colonsTextStyle: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                      timeTextStyle: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                      onEnd: () {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Mã QR đã hết hạn"),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Action Buttons
              Row(
                children: [
                  // Download Button - Lưu vào Gallery
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.photo_library, color: Colors.blue.shade700),
                      label: Text(
                        "Lưu vào Gallery",
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                      onPressed: downloadQRCode,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.blue.shade300),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Share Button
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share, color: Colors.white),
                      label: const Text(
                        "Chia sẻ",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: shareQRCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
 Widget _buildHomeSection(HomeModel home) {
  final deviceController = Get.find<DeviceController>();
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final width = MediaQuery.of(context).size.width;
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    width: double.infinity, // Chiếm toàn bộ chiều ngang có thể
    constraints:  BoxConstraints(
      minWidth: width, // Đảm bảo có chiều rộng tối thiểu
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: Theme.of(context).colorScheme.surface,
      boxShadow: [
        BoxShadow(
          color: isDarkMode 
            ? Colors.black.withOpacity(0.4)
            : Colors.black.withOpacity(0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image section với gradient overlay
        if (home.image != null && home.image!.isNotEmpty)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImagePage(
                    imageUrl: home.image!,
                    heroTag: "home_image_${home.id}",
                  ),
                ),
              );
            },
            child: SizedBox(
              height: 160,
              width: double.infinity, // Chiếm toàn bộ chiều ngang
              child: Stack(
                children: [
                  Hero(
                    tag: "home_image_${home.id}",
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: Image.network(
                        home.image!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 160,
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          isDarkMode 
                            ? Colors.black.withOpacity(0.6)
                            : Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            height: 120,
            width: double.infinity, // Chiếm toàn bộ chiều ngang
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              color: isDarkMode 
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Colors.grey.shade100,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                  ? [
                      Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.8),
                      Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.6),
                    ]
                  : [
                      Colors.grey.shade100,
                      Colors.grey.shade200,
                    ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.home_work_outlined,
                size: 48,
                color: isDarkMode 
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Colors.grey.shade400,
              ),
            ),
          ),

        // Content section
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với icon và menu
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDarkMode
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.home_filled,
                      size: 24,
                      color: isDarkMode
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      home.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDarkMode
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : Colors.grey.shade100,
                    ),
                    child: PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == "delete") deviceController.deleteHome(home.id);
                        if (val == "update") {
                          AddHomePage(homeModel: home,isAddHome: false).show(context);
                        };
                      },
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: isDarkMode
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Colors.grey.shade600,
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: "update",
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit, 
                                color: isDarkMode
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.blue.shade600, 
                                size: 20
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Chỉnh sửa home",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: "delete",
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete, 
                                color: isDarkMode
                                  ? Theme.of(context).colorScheme.error
                                  : Colors.red.shade500, 
                                size: 20
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Xóa home",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Rooms section
              StreamBuilder<List<RoomModel>>(
              stream: deviceController.streamRooms(home.id),
              builder: (context, snapshot) {
                // // Nếu đang load dữ liệu
                // if (snapshot.connectionState == ConnectionState.waiting) {
                //   return const Center(child: CircularProgressIndicator());
                // }

                // Nếu có dữ liệu
                final rooms = snapshot.data ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nếu không có phòng nào -> hiển thị thông báo
                    if (rooms.isEmpty)
                      const Center(
                        child: Text("Không có phòng nào!"),
                      )
                    else
                      // Hiển thị danh sách phòng
                      ...rooms.map((room) => _buildRoomSection(home, room)),

                    const SizedBox(height: 16),

                    // Nút thêm phòng mới (luôn hiển thị)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => AddRoomDialog.show(context, home.id),
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        label: Text(
                          "Thêm phòng mới",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                );
              },
            )

            ],
          ),
        ),
      ],
    ),
  );
}




  Future<void> _openEnergyConsumptionPage(BuildContext context, HomeModel home, RoomModel room) async {
  try {
    // Hiển thị loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // 🆕 LẤY DEVICE STATUS MAP CHO PHÒNG NÀY
    final Map<String, DeviceStatus> deviceStatusMap = await deviceController.getDeviceStatusMapForRoom(home.id, room.id, room.devices);

    // Đóng loading
    if (context.mounted) {
      Navigator.of(context).pop(); // Đóng dialog loading
    }

    // Mở EnergyConsumptionPage
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EnergyConsumptionPage(
            room: room,
            devices: room.devices,
            deviceStatusMap: deviceStatusMap,
          ),
        ),
      );
    }
  } catch (e) {
    // Đóng loading nếu có lỗi
    if (context.mounted) {
      Navigator.of(context).pop(); // Đóng dialog loading
      
      // Hiển thị lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải dữ liệu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
  // ==================== UI ROOM ====================
  Widget _buildRoomSection(HomeModel home, RoomModel room) {
    String getRoomImage(String type) {
      switch (type) {
        case "Phòng ngủ":
          return AssetImages.bedRoom;
        case "Phòng khách":
          return AssetImages.livingRoom;
        case "Phòng ăn":
          return AssetImages.kitchenRoom;
        case "Phòng vệ sinh":
          return AssetImages.bathRoom;
        case "Sân/Vườn":
          return AssetImages.garden;
        default:
          return AssetImages.livingRoom;
      }
    }

    return Card(
  margin: const EdgeInsets.symmetric(vertical: 8),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  clipBehavior: Clip.antiAlias,
  elevation: 2,
  child: Stack(
    children: [
      // Background image (chỉ hiển thị khi có ảnh)
      if (room.image != null && room.image!.isNotEmpty) ...[
        Positioned.fill(
          child: Image.network(
            room.image!,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.35),
          ),
        ),
      ],

      // Nội dung
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header phòng
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: AssetImage(getRoomImage(room.type)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "${room.type} - ${room.name}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: (room.image != null && room.image!.isNotEmpty)
                          ? Colors.white
                          : Colors.black, // đổi màu chữ theo ảnh
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (val)  {
                    if (val == "edit") EditRoomDialog.show(context, home.id, room);
                    if (val == "analys")  {
                     _openEnergyConsumptionPage(context, home, room);
                    }
                    if (val == "delete") deviceController.deleteRoom(home.id, room.id);
                    if (val == "share") _shareRoom(context,home, room.id);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: "edit", child: Text("Sửa phòng")),
                    PopupMenuItem(value: "delete", child: Text("Xóa")),
                    PopupMenuItem(value: "analys", child: Text("Phân tích")),
                    PopupMenuItem(value: "share", child: Text("Chia sẻ")),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Devices
            StreamBuilder<List<Device>>(
              stream: deviceController.streamDevices(home.id, room.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Chưa có thiết bị",
                      style: TextStyle(
                        color: (room.image != null && room.image!.isNotEmpty)
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  );
                }

                final devices = snapshot.data!;
                
                return Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        mainAxisExtent: 200,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return StreamBuilder<DeviceStatus>(
                          stream: deviceController.getDeviceStatus(home.id, room.id, device.id),
                          builder: (context, snap) {
                            final status = snap.data ?? DeviceStatus(status: false);
                            return _buildDeviceCard(home.id, room.id, device, status);
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 8),

                  // Nút Chi tiết nằm trong StreamBuilder → có access devices
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.red),
                            elevation: 1
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RoomDetailPage(
                                  homeId: home.id,
                                  room: room,
                                  devices: devices, // ✅ có devices
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.info_outline),
                          label: const Text("Chi tiết", style: TextStyle(fontWeight: FontWeight.w600),),
                        ),
                      ),
                    ],
                  ),

                  ],
                );
              },
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: (room.image != null && room.image!.isNotEmpty)
                        ? Colors.white
                        : Colors.black,
                    side: BorderSide(
                      color: (room.image != null && room.image!.isNotEmpty)
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  onPressed: () =>DialogUtils.showAddDeviceDialog(context, home.id, room.id),
                  icon: const Icon(Icons.add),
                  label: const Text("Thêm thiết bị"),
                ),
        
              ],
            ),
          ],
        ),
      ),
    ],
  ),
);

  }

  // ==================== DIALOG ====================
  



  
 Widget _buildDeviceCard(
    String homeId, String roomId, Device device, DeviceStatus status) {
  final width = MediaQuery.of(context).size.width;
  final isTablet = width > 600;
  final isSmallDevice = width < 350;

  return LayoutBuilder(
    builder: (context, constraints) {
      final cardWidth = constraints.maxWidth;
      final isVeryNarrow = cardWidth < 140;

      return Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: status.status ? Colors.blue.shade600 : Colors.grey.shade500,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Padding(
          padding: isVeryNarrow 
              ? const EdgeInsets.symmetric(vertical: 4, horizontal: 3)
              : const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Icon + Menu ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isVeryNarrow ? 24 : (isSmallDevice ? 28 : 32),
                    height: isVeryNarrow ? 24 : (isSmallDevice ? 28 : 32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        getDeviceIcon(device.type!, status.status) ?? "assets/icons/default.png",
                        width: isVeryNarrow ? 16 : (isSmallDevice ? 20 : 24),
                        height: isVeryNarrow ? 16 : (isSmallDevice ? 20 : 24),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!isVeryNarrow) // Ẩn menu trên màn hình rất nhỏ
                    PopupMenuButton<String>(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      iconSize: isSmallDevice ? 16 : 20,
                      icon: Icon(Icons.more_vert, color: Colors.white, size: isSmallDevice ? 16 : 20),
                      onSelected: (value) async {
                        if (value == "delete") {
                          await deviceController.deleteDevice(homeId, roomId, device.id);
                        }
                        if (value == "edit") {
                          DialogUtils.showAddDeviceDialog(context, homeId, roomId,editDevice: true,device: device);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: "delete",
                          child: Text(
                            "Xóa",
                            style: TextStyle(fontSize: isSmallDevice ? 12 : 14),
                          ),
                        ),
                        PopupMenuItem(
                          value: "edit",
                          child: Text(
                            "Sửa",
                            style: TextStyle(fontSize: isSmallDevice ? 12 : 14),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              SizedBox(height: isVeryNarrow ? 2 : (isSmallDevice ? 3 : 5)),

              // --- Tên thiết bị ---
              Flexible(
                child: Text(
                  _getDeviceDisplayName(device),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getFontSizeForDevice(cardWidth, device.type!),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: _getMaxLinesForDevice(device.type!),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: isVeryNarrow ? 2 : (isSmallDevice ? 3 : 5)),
              // --- Hiển thị thông tin theo loại thiết bị ---
              _buildDeviceSpecificInfo(device, status, isVeryNarrow, isSmallDevice),
              SizedBox(height: isVeryNarrow ? 2 : (isSmallDevice ? 3 : 5)),
              // --- Control (Switch/Slider/Value) ---
              _buildDeviceControl(homeId, roomId, device, status, isVeryNarrow, isSmallDevice),
            ],
          ),
        ),
      );
    },
  );
}

// Hàm lấy tên hiển thị cho thiết bị
String _getDeviceDisplayName(Device device) {
  final typeName = DialogUtils.reverseDeviceTypeMap[device.type] ?? 'Thiết bị';
  final name = device.name ?? 'Unknown';
  
  // Rút gọn tên cho các thiết bị dài
  if (name.length > 12) {
    return "$typeName\n${name.substring(0, 10)}...";
  }
  
  return "$typeName\n$name";
}

// Hàm xác định kích thước font dựa trên kích thước card và loại thiết bị
double _getFontSizeForDevice(double cardWidth, String deviceType) {
  if (cardWidth < 120) return 10;
  if (cardWidth < 140) return 12;
  if (cardWidth < 160) return 14;
  
  // Các thiết bị có tên dài cần font nhỏ hơn
  final longNameDevices = ["Temperature Humidity Sensor", "Gas Sensor"];
  if (longNameDevices.contains(deviceType)) {
    if (cardWidth < 180) return 10;
    return 11;
  }
  
  if (cardWidth < 180) return 11;
  return 12;
}

// Hàm xác định số dòng tối đa dựa trên loại thiết bị
int _getMaxLinesForDevice(String deviceType) {
  switch (deviceType) {
    case "Temperature Humidity Sensor":
    case "Gas Sensor":
      return 3;
    default:
      return 2;
  }
}

// Widget hiển thị thông tin cụ thể theo loại thiết bị
Widget _buildDeviceSpecificInfo(Device device, DeviceStatus status, bool isVeryNarrow, bool isSmallDevice) {
  final textStyle = TextStyle(
    color: Colors.white,
    fontSize: isVeryNarrow ? 8 : (isSmallDevice ? 9 : 10),
    fontWeight: FontWeight.w400,
  );

  switch (device.type) {
    case "Temperature Humidity Sensor":
      return Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.thermostat,
                size: 12,
                color: Colors.redAccent.shade200,
              ),
              SizedBox(width: 4,),
              Text(
                " ${status.temperature?.toStringAsFixed(1) ?? '--'}°C",
                style: textStyle.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.water_drop,
                size: 12,
                color: Colors.lightBlue.shade200,
              ),
              SizedBox(width: 4,),
              Text(
                "${status.humidity?.toStringAsFixed(0) ?? '--'}%",
                style: textStyle,
              ),
            ],
          ),
        ],
      );
      
    case "Gas Sensor":
      return Text(
        "${double.tryParse(status.mode)?.toStringAsFixed(0) ?? '--'} ppm",
        style: textStyle.copyWith(fontWeight: FontWeight.w600),
      );
      
    case "Fan":
      return Text(
        "${status.speed?.toStringAsFixed(0) ?? '0'}%",
        style: textStyle.copyWith(fontWeight: FontWeight.w600),
      );
      
    case "Light":
      return Text(
        status.status ? "Đang bật" : "Đã tắt",
        style: textStyle.copyWith(
          fontWeight: FontWeight.w600,
          color: status.status ? Colors.lightGreenAccent : Colors.grey.shade300,
        ),
      );
      
    default:
      return Text(
        status.status ? "BẬT" : "TẮT",
        style: textStyle.copyWith(
          fontWeight: FontWeight.w600,
          color: status.status ? Colors.lightGreenAccent : Colors.grey.shade300,
        ),
      );
  }
}

// Widget điều khiển thiết bị theo loại
Widget _buildDeviceControl(String homeId, String roomId, Device device, DeviceStatus status, bool isVeryNarrow, bool isSmallDevice) {
  final controlSize = isVeryNarrow ? 40.0 : (isSmallDevice ? 46.0 : 50.0);

  switch (device.type) {
    case "Fan":
      return SizedBox(
        width: controlSize,
        height: controlSize,
        child: CircularProgressIndicator(
          value: (status.speed ?? 0) / 100,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(
            status.status ? Colors.lightGreenAccent : Colors.grey.shade300,
          ),
          strokeWidth: 3,
        ),
      );
      
    case "Temperature Humidity Sensor":
    case "Gas Sensor":
      // Cảm biến chỉ hiển thị trạng thái, không có điều khiển
      return Container(
        width: controlSize,
        height: controlSize * 0.3,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            "CẢM BIẾN",
            style: TextStyle(
              color: Colors.white,
              fontSize: isVeryNarrow ? 6 : (isSmallDevice ? 7 : 8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
      
    default:
      // Switch cho các thiết bị thông thường
      return SizedBox(
        width: controlSize,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Switch.adaptive(
            value: status.status,
            activeColor: const Color.fromARGB(255, 99, 207, 69),
            inactiveThumbColor: const Color.fromARGB(255, 99, 207, 69),
            onChanged: (val) async {
              final currentDeviceStatus = await deviceController.getFutureDeviceStatus(homeId, roomId, device.id);
              final updatedDeviceStatus = currentDeviceStatus.updateDeviceStatus(val);
              deviceController.updateStatus(
                homeId, 
                roomId, 
                device.id,
               updatedDeviceStatus
              );
              
            },
          ),
        ),
      );
  }
}

}

 /// UI từng card thiết bị


///
Widget _buildSharedRoomCard(RoomModel room, String homeId) {
  final deviceController = Get.put(DeviceController());
  
  String getRoomImage(String type) {
    switch (type) {
      case "Phòng ngủ":
        return AssetImages.bedRoom;
      case "Phòng khách":
        return AssetImages.livingRoom;
      case "Phòng ăn":
        return AssetImages.kitchenRoom;
      case "Phòng vệ sinh":
        return AssetImages.bathRoom;
      case "Sân/Vườn":
        return AssetImages.garden;
      default:
        return AssetImages.livingRoom;
    }
  }

  Color getRoomColor(String type) {
    switch (type) {
      case "Phòng ngủ":
        return Colors.purple.shade50;
      case "Phòng khách":
        return Colors.blue.shade50;
      case "Phòng ăn":
        return Colors.orange.shade50;
      case "Phòng vệ sinh":
        return Colors.cyan.shade50;
      case "Sân/Vườn":
        return Colors.green.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  final bool hasBackgroundImage = room.image?.isNotEmpty == true;
  final textColor = hasBackgroundImage ? Colors.white : Colors.black;
  final secondaryTextColor = hasBackgroundImage 
      ? Colors.white.withOpacity(0.8) 
      : Colors.grey.shade600;

  void navigateToRoomDetail(BuildContext context, List<Device> devices) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomDetailPage(
          homeId: room.hoomId ?? '',
          room: room,
          devices: devices,
        ),
      ),
    );
  }
Future<void> handleLeaveRoom(BuildContext context, RoomModel room, String homeId) async {
  try {
    final roomRef = FirebaseFirestore.instance
        .collection("Homes")
        .doc(homeId)
        .collection("Rooms")
        .doc(room.id);

    print('👉 Updating allowedUsers for room ${room.id} in home $homeId');

    await roomRef.update({
      "allowedUsers": FieldValue.arrayRemove([FirebaseAuth.instance.currentUser!.uid])
    });

    print('✅ Room updated successfully');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã rời khỏi phòng "${room.name}"')),
      );
    }
  } catch (e, stack) {
    print('❌ Lỗi khi rời phòng: $e');
    print(stack);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi rời phòng: $e')),
      );
    }
  }
}


  // Hiển thị dialog (trả về Future để dễ await nếu cần)
  Future<void> showLeaveRoomConfirmation(BuildContext context, RoomModel room, String homeId) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Rời khỏi phòng'),
          content: Text('Bạn có chắc chắn muốn rời khỏi phòng "${room.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await handleLeaveRoom(context,room, homeId); // ✅ gọi hàm mới, tránh trùng tên
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Rời khỏi'),
            ),
          ],
        );
      },
    );
  }



  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Stack(
      children: [
        // Background
        if (hasBackgroundImage) ...[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                room.image!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ),
        ] else ...[
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: getRoomColor(room.type),
              ),
            ),
          ),
        ],

        // Content
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        getRoomImage(room.type),
                        width: 28,
                        height: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          room.type,
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Shared badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.share, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "Được chia sẻ",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Info section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Bạn có quyền xem và điều khiển thiết bị trong phòng này",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Devices preview
              StreamBuilder<List<Device>>(
                stream: deviceController.streamDevices(homeId, room.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(6.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildNoDevicesSection();
                  }

                  final devices = snapshot.data!;
                  return _buildDevicesSection(
                    context,
                    devices,
                    room,
                    navigateToRoomDetail,
                    (context) => showLeaveRoomConfirmation(context, room, homeId)
                  );
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildNoDevicesSection() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(
          Icons.devices_other,
          size: 20,
          color: Colors.grey.shade500,
        ),
        const SizedBox(width: 8),
        Text(
          "Chưa có thiết bị",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}

Widget _buildDevicesSection(
  BuildContext context,
  List<Device> devices,
  RoomModel room,
  Function(BuildContext, List<Device>) onViewDetails,
  Function(BuildContext) onLeaveRoom,
) {
  // ✅ Tạo stream để đếm số thiết bị đang bật
  Stream<int> streamActiveDevices(String homeId, String roomId, List<Device> devices) async* {
    final realtime = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: "https://iotsmarthome-187be-default-rtdb.asia-southeast1.firebasedatabase.app/",
    );

    final statusRefs = devices.map((d) => realtime.ref("Status/$homeId/$roomId/${d.id}")).toList();

    // Cập nhật mỗi 2 giây
    await for (final _ in Stream.periodic(const Duration(seconds: 2))) {
      int count = 0;
      for (final ref in statusRefs) {
        final snapshot = await ref.get();
        if (snapshot.value != null) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          final statusDevice = DeviceStatus.fromMap(data);
          if (statusDevice.status == true) count++;
        }
      }
      yield count;
    }
  }

  final homeId = room.hoomId ?? ""; // 👈 bạn cần truyền đúng ID home
  final roomId = room.id;

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        // Devices info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Thiết bị",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  "${devices.length} thiết bị",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),

            // ✅ StreamBuilder để hiển thị số thiết bị đang hoạt động realtime
            StreamBuilder<int>(
              stream: streamActiveDevices(homeId, roomId, devices),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                final activeDevices = snapshot.data ?? 0;

                if (activeDevices > 0) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      "$activeDevices đang hoạt động",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink(); // không hiển thị gì nếu không có thiết bị bật
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => onViewDetails(context, devices),
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text(
                  "Xem chi tiết",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onLeaveRoom(context),
                icon: const Icon(Icons.exit_to_app, size: 18),
                label: const Text(
                  "Rời phòng",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


// ---------------- Các page khác (bình thường, không extends KFDrawerContent) ----------------






// ---------------- HomePageContent (KFDrawer container) ----------------
class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  final authController = Get.put(AuthController());
    final firebaseUser = FirebaseAuth.instance.currentUser;
  late KFDrawerController _drawerController;
  late FirebaseDatabase db;
  late DatabaseReference lightRef;

  @override
  void initState() {
    super.initState();

    db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          "https://iotsmarthome-187be-default-rtdb.asia-southeast1.firebasedatabase.app/",
    );

    lightRef = db.ref("Light/current");

    _drawerController = KFDrawerController(
      initialPage: HomeDashboard(),
      items: [
        KFDrawerItem.initWithPage(
          text: const Text("Home", style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.home, color: Colors.white),
          page: HomeDashboard(),
        ),
        KFDrawerItem.initWithPage(
          text: const Text("Create QR device", style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.devices_other_outlined, color: Colors.white),
          page: CreateDeviceQRPage(),
        ),
        KFDrawerItem.initWithPage(
          text: const Text("Profile", style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.person, color: Colors.white),
          page:  ProfilePage(),
        ),
        KFDrawerItem.initWithPage(
          text: const Text("Notifications", style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.notifications, color: Colors.white),
          page: const NotificationPage(),
        ),
        KFDrawerItem.initWithPage(
          text: const Text("Settings", style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.settings, color: Colors.white),
          page: const SettingPage(),
        ),
        KFDrawerItem(
          icon: const Icon(Icons.logout, color: Colors.white),
          text: const Text("Logout", style: TextStyle(color: Colors.white)),
          onPressed: () async {
            void signOut() async {
                await authController.signOut();
            }
            DialogUtils.showConfirmDialog(context, "Đăng xuất", Text("Bạn có muốn đăng xuất ?")
            ,signOut);

            
          },
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    
    // có thể null nếu chưa login
    return KFDrawer(
      controller: _drawerController,
      header: StreamBuilder<User?>(
      stream: firebaseUser != null
          ? authController.getUserByIdStream(firebaseUser!.uid) // 👈 lấy user Firestore
          : null,
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: 20,),
            CircleAvatar(
              radius: 30,
              backgroundImage: user?.profileImage != null
                  ? NetworkImage(user!.profileImage!)
                  : AssetImage(AssetImages.iconApp) as ImageProvider,
            ),
            const SizedBox(width: 10),
            Text(
              user?.name ?? firebaseUser?.displayName ?? firebaseUser?.email ?? "Guest",
              style: AppTextStyles.title,
            ),
          ],
        );
      },
    ),
      footer: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("Smart Home © 2025", style: AppTextStyles.body),
      
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}
// Full-screen image page
