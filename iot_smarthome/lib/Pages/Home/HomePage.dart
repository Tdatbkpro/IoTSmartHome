
import 'dart:math';
import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:iot_smarthome/Config/Icons.dart';
import 'package:iot_smarthome/Controllers/DeviceController.dart';
import 'package:iot_smarthome/Controllers/PickImageController.dart';
import 'package:iot_smarthome/Models/DeviceStatusModel.dart';
import 'package:iot_smarthome/Models/HomeModel.dart';
import 'package:iot_smarthome/Models/RoomModel.dart';
import 'package:iot_smarthome/Pages/Home/Dialog.dart';
import 'package:iot_smarthome/Pages/Home/Widget/ProfilePage.dart';
import 'package:iot_smarthome/Pages/Home/Widget/RoomDetailPage.dart';
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
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({Key? key}) : super(key: key);

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final authController = Get.put(AuthController());
  final deviceController = Get.put(DeviceController());
  final firebaseUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (firebaseUser != null) {
      deviceController.streamHomes(firebaseUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    body: Obx(() {
      final homes = deviceController.homes;

      return CustomScrollView(
        slivers: [
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

              final avatarSize = 56 * percent.clamp(0.5, 1.0);
              final topPadding = 60 * percent.clamp(0.0, 1.0);

              // Giá trị dịch sang phải khi cuộn (max 40px chẳng hạn)
              final offsetX = (1 - percent) * 40;
                return Stack(
              fit: StackFit.expand,
              children: [
                // Ảnh nền + blur cục bộ
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Image.asset(
                    "assets/images/banner_homepage.png",
                    fit: BoxFit.cover,
                  ),
                ),

                Container(color: Colors.black.withOpacity(0.3)),
                // Nội dung avatar + tên
                Padding(
                  padding: EdgeInsets.fromLTRB(10, topPadding, 10, 10),
                  child: FutureBuilder<User?>(
                    future: firebaseUser != null
                        ? authController.getUserById(firebaseUser!.uid)
                        : null,
                    builder: (context, snapshot) {
                      final user = snapshot.data;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // dịch avatar + name sang phải khi cuộn
                          Transform.translate(
                            offset: Offset(offsetX, 0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: avatarSize / 2,
                                  backgroundImage: user?.profileImage != null
                                      ? NetworkImage(user!.profileImage!)
                                      : AssetImage(AssetImages.iconApp) as ImageProvider,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Opacity(
                                      opacity: 1,
                                      child: Text(
                                        "Welcome 👋",
                                        style: TextStyle(
                                          fontSize: 16 * percent.clamp(0.8, 1.0),
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      user?.name ??
                                          firebaseUser?.displayName ??
                                          firebaseUser?.email ??
                                          "Guest",
                                      style: TextStyle(
                                        fontSize: 20 * percent.clamp(0.8, 1.0),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.notifications_none, color: Colors.white),
                            onPressed: () {},
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );


            },
          ),
        ),


          // Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: homes.isEmpty
                  ? const Center(child: Text("No homes found"))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          homes.map((home) => _buildHomeSection(home)).toList(),
                    ),
            ),
          ),
        ],
      );
    }),




      floatingActionButton: FloatingActionButton(
      onPressed: () {
        final pickImageController = Get.put(PickImageController());
        final nameCtrl = TextEditingController();
        String? imageHome;

        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: "Add Home",
          barrierColor: Colors.black.withOpacity(0.5),
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.85,
                ),
                child: Material(
                  color: Theme.of(context).dialogBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              "Thêm Home",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(
                                labelText: "Tên Home",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (imageHome != null)
                              Image.network(
                                imageHome!,
                                height: 200,
                                width: 200,
                                fit: BoxFit.fill,
                              ),
                            TextButton.icon(
                              onPressed: () async {
                                final url = await pickImageController.pickImageFileAndUpload();
                                if (!mounted) return; // kiểm tra trước khi setState
                                if (url != null && url.isNotEmpty) {
                                  setState(() {
                                    imageHome = url;
                                  });
                                }
                              },
                              icon: const Icon(Icons.image),
                              label: const Text("Chọn ảnh"),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Hủy"),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    if (nameCtrl.text.trim().isEmpty) return; // validate
                                    final home = HomeModel(
                                      id: const Uuid().v4(),
                                      name: nameCtrl.text.trim(),
                                      ownerId: firebaseUser!.uid,
                                      image: imageHome,
                                    );
                                    deviceController.addHome(home);
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Thêm"),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: curved, child: child),
            );
          },
        );
      },
      child: const Icon(Icons.add),
    ),




    );
  }

  // ==================== UI HOME ====================
 Widget _buildHomeSection(HomeModel home) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
    clipBehavior: Clip.antiAlias,
    elevation: 3,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image section
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
            child: Hero(
              tag: "home_image_${home.id}",
              child: Image.network(
                home.image!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          )
        else
          Container(
            height: 200,
            color: Colors.grey.shade300,
            width: double.infinity,
          ),

        // Overlay content
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.home, size: 28, color: Colors.black87),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      home.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == "delete") deviceController.deleteHome(home.id);
                      if (val == "update") DialogUtils.showEditHomeDialog(context, home);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: "delete", child: Text("Xóa home")),
                      PopupMenuItem(value: "update", child: Text("Sửa home")),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<RoomModel>>(
                stream: deviceController.streamRooms(home.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  final rooms = snapshot.data!;
                  return Column(
                    children: [
                      ...rooms.map((room) => _buildRoomSection(home.id, room)).toList(),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => DialogUtils.showAddRoomDialog(context, home.id),
                        icon: const Icon(Icons.add),
                        label: const Text("Thêm phòng"),
                      ),
                    ],
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





  // ==================== UI ROOM ====================
  Widget _buildRoomSection(String homeId, RoomModel room) {
    final  Devices;
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
                  onSelected: (val) {
                    if (val == "edit") DialogUtils.showEditRoomDialog(context, homeId, room);
                    if (val == "delete") deviceController.deleteRoom(homeId, room.id);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: "edit", child: Text("Sửa")),
                    PopupMenuItem(value: "delete", child: Text("Xóa")),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Devices
            StreamBuilder<List<Device>>(
              stream: deviceController.streamDevices(homeId, room.id),
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
                          stream: deviceController.getDeviceStatus(homeId, room.id, device.id),
                          builder: (context, snap) {
                            final status = snap.data ?? DeviceStatus(status: false);
                            return _buildDeviceCard(homeId, room.id, device, status);
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
                                  homeId: homeId,
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
                  onPressed: () =>DialogUtils.showAddDeviceDialog(context, homeId, room.id),
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
  return ConstrainedBox(
    constraints: const BoxConstraints(
      minWidth: 120,
      minHeight: 160,
      maxWidth: 180,
    ),
    child: Container(
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
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Icon + Menu ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white,
                child: Image.asset(
                  getDeviceIcon(device.type!, status.status) ?? "assets/icons/default.png",
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                ),
              ),

                const Spacer(),
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                  onSelected: (value) async {
                    if (value == "delete") {
                      await deviceController.deleteDevice(
                          homeId, roomId, device.id);
                    }
                    // TODO: edit device
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: "delete", child: Text("Xóa")),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // --- Tên thiết bị ---
            Flexible(
              child: Text(
                "${device.type ?? 'Thiết bị'} - ${device.name ?? 'Unknown'}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const Spacer(),

            // --- Switch ---
            Align(
              alignment: Alignment.center,
              child: Switch.adaptive(
                value: status.status,
                activeColor: Colors.white,
                inactiveThumbColor: Colors.grey.shade300,
                onChanged: (val) {
                  if (device.type == "Quạt") {
                    deviceController.updateStatus(homeId, roomId, device.id, {
                    "status": val ? 1 : 0,
                    "speed" : Random().nextInt(100),
                    
                  });
                  } else if  (device.type == "Cảm biến khí gas"){
                     deviceController.updateStatus(homeId, roomId, device.id, {
                    "status": val ? 1 : 0,
                    "CO2" : Random().nextInt(1000),
                  });
                  } else if (device.type == "Cảm biến nhiệt độ & độ ẩm") {
                    deviceController.updateStatus(homeId, roomId, device.id, {
                    "status": val ? 1 : 0,
                    "temperature" : Random().nextInt(100),
                    "humidity": Random().nextInt(100)
                  });} else {
                     deviceController.updateStatus(homeId, roomId, device.id, {
                    "status": val ? 1 : 0,
                  });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

}

 /// UI từng card thiết bị


// ---------------- Các page khác (bình thường, không extends KFDrawerContent) ----------------


class NotificationsContent extends StatelessWidget {
  const NotificationsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => KFDrawer.of(context)?.toggle(),
        ),
      ),
      body: const Center(child: Text("Notifications Page")),
    );
  }
}

class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => KFDrawer.of(context)?.toggle(),
        ),
      ),
      body: const Center(child: Text("Settings Page")),
    );
  }
}

// ---------------- HomePageContent (KFDrawer container) ----------------
class HomePageContent extends StatefulWidget {
  const HomePageContent({Key? key}) : super(key: key);

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
          text: const Text("Profile", style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.person, color: Colors.white),
          page:  ProfilePage(),
        ),
        KFDrawerItem.initWithPage(
          text: const Text("Notifications", style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.notifications, color: Colors.white),
          page: const NotificationsContent(),
        ),
        KFDrawerItem.initWithPage(
          text: const Text("Settings", style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.settings, color: Colors.white),
          page: const SettingsContent(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    
    // có thể null nếu chưa login
    return KFDrawer(
      controller: _drawerController,
      header: FutureBuilder<User?>(
      future: firebaseUser != null
          ? authController.getUserById(firebaseUser!.uid) // 👈 lấy user Firestore
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
