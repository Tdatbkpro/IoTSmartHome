import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:iot_smarthome/Controllers/Auth.dart';
import 'package:iot_smarthome/Controllers/DeviceController.dart';
import 'package:iot_smarthome/Models/HomeModel.dart';
import 'package:iot_smarthome/Models/RoomModel.dart';
import 'package:iot_smarthome/Models/UserModel.dart';
import 'package:iot_smarthome/Pages/Home/Dialog.dart';
import 'package:iot_smarthome/Pages/Home/Widget/ConfigHome.dart';
import 'package:iot_smarthome/Pages/Home/Widget/RoomDetailPage.dart';
import 'package:iot_smarthome/Services/InvitationService.dart';

class HomeDetailPage extends StatefulWidget {
  final HomeModel home;

  const HomeDetailPage({super.key, required this.home});

  @override
  State<HomeDetailPage> createState() => _HomeDetailPageState();
}

class _HomeDetailPageState extends State<HomeDetailPage> {
   late HomeModel _currentHome;
  final DeviceController deviceController = Get.find<DeviceController>();

  @override
  void initState() {
    super.initState();
    _currentHome = widget.home;
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
   
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          // 🌀 Tải lại danh sách homes
          final userId = _currentHome.ownerId;
          deviceController.streamHomes(userId);

          // Chờ homes cập nhật xong (GetX là reactive)
          await Future.delayed(const Duration(seconds: 1));

          // 🔁 Cập nhật lại home hiện tại
          final updatedHome = deviceController.homes.firstWhereOrNull(
            (h) => h.id == _currentHome.id,
          );

          if (updatedHome != null) {
            setState(() {
              _currentHome = updatedHome;
            });
          }
        },
        child: CustomScrollView(
          physics:  AlwaysScrollableScrollPhysics(),
          slivers: [
            // SliverAppBar với hiệu ứng giống RoomDetailPage
            SliverAppBar(
              pinned: true,
              expandedHeight: 220,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _currentHome.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                centerTitle: true,
                collapseMode: CollapseMode.parallax,
                background: _currentHome.image?.isNotEmpty == true
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            _currentHome.image!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / 
                                          loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              );
                            },
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
                    : Container(
                        color: isDarkMode ? Colors.grey[900] : Colors.grey[800],
                        child: Icon(
                          Icons.home_work_outlined,
                          color: Colors.white,
                          size: 80,
                        ),
                      ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: () {
                    AddHomePage(isAddHome: false, homeModel: _currentHome).show(context);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {
                    _showHomeOptions(context);
                  },
                ),
              ],
              backgroundColor: theme.appBarTheme.backgroundColor ?? theme.primaryColor,
            ),
        
            // Thông tin thống kê home
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thông tin địa chỉ
                    if (_currentHome.location != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: theme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentHome.location!,
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
        
                    // Thống kê nhanh
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            Icons.room_outlined,
                            "${_currentHome.rooms.length}",
                            "Phòng",
                            Colors.blue,
                            theme,
                          ),
                          _buildStatItem(
                            Icons.devices_outlined,
                            _calculateTotalDevices(_currentHome.rooms).toString(),
                            "Thiết bị",
                            Colors.green,
                            theme,
                          ),
                          _buildStatItem(
                            Icons.people_outline,
                            _currentHome.members?.length.toString() ?? "1",
                            "Thành viên",
                            Colors.orange,
                            theme,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
        
            // Section: Thành viên trong nhà
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.people_outlined,
                          color: theme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "THÀNH VIÊN TRONG NHÀ",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                           _showAddMemberDialog(context, _currentHome.id, _currentHome.id);
                          },
                          icon: Icon(Icons.person_add, size: 16, color: theme.primaryColor),
                          label: Text(
                            "Thêm thành viên",
                            style: TextStyle(color: theme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMembersSection(context,_currentHome),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
        
            // Header danh sách phòng
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.room_outlined,
                          color: theme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "DANH SÁCH PHÒNG (${_currentHome.rooms.length})",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            AddRoomDialog.show(context, _currentHome.id);
                          },
                          icon: Icon(Icons.add, size: 16, color: theme.primaryColor),
                          label: Text(
                            "Thêm phòng",
                            style: TextStyle(color: theme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
        
            // Danh sách phòng
            _currentHome.rooms.isEmpty
                ? SliverToBoxAdapter(
                    child: _buildEmptyRoomsState(context),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final room = _currentHome.rooms[index];
                        return _buildRoomItem(context, room, index);
                      },
                      childCount: _currentHome.rooms.length,
                    ),
                  ),
        
            // Khoảng cách cuối cùng
            const SliverToBoxAdapter(
              child: SizedBox(height: 40),
            ),
          ],
        ),
      ),

      // Floating Action Button để thêm phòng
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AddRoomDialog.show(context, _currentHome.id);
        },
        backgroundColor: theme.primaryColor,
        child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMembersSection(BuildContext context, HomeModel home) {
  final theme = Theme.of(context);
  final isDarkMode = theme.brightness == Brightness.dark;
  
  // Sử dụng dữ liệu thực từ home.members thay vì giả lập
  final members = home.members;

  return Container(
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        // Hiển thị chủ nhà đầu tiên
        _buildMemberTile(
          context, 
          _MemberInfo(
            userId: home.ownerId,
            name: "Chủ nhà", // Cần fetch tên từ user service
            email: "", // Cần fetch email từ user service
            role: "Chủ sở hữu",
            isOwner: true,
            avatar: null,
          ),
        ),
        
        // Hiển thị các thành viên khác
        ...members.map((member)  {
          final authController = Get.find<AuthController>();
          return  FutureBuilder(future: authController.getUserById(member.userId), 
          builder: (context, snapshot) {
           if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
           }
           if (!snapshot.hasData) {
            return Center(
              child: Text("Không có thông tin"),
            );
           }
           final userInfo = snapshot.data;

            return _buildMemberTile(
          context, 
          _MemberInfo.fromHomeMember(member,userInfo!)
        );
          },);
        }),
        
        // Nút thêm thành viên
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_add_outlined,
              color: theme.primaryColor,
              size: 20,
            ),
          ),
          title: Text(
            "Thêm thành viên",
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () {
            _showAddMemberDialog(context, _currentHome.id, _currentHome.name);
          },
        ),
      ],
    ),
  );
}

Widget _buildMemberTile(BuildContext context, _MemberInfo member) {
  final theme = Theme.of(context);
  
  return FutureBuilder<Map<String, dynamic>?>(
    future: _fetchUserInfo(member.userId), // Hàm fetch thông tin user
    builder: (context, snapshot) {
      final userData = snapshot.data;
      final displayName = userData?['name'] ?? member.name;
      final email = userData?['email'] ?? member.email;
      final avatar = userData?['profileImage'] ?? member.avatar;
      
      return ListTile(
        leading: Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: avatar != null && avatar.isNotEmpty
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(avatar),
                    )
                  : Icon(
                      Icons.person_outlined,
                      color: theme.primaryColor,
                    ),
            ),
            if (member.isOwner)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.cardColor, width: 2),
                  ),
                  child: Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Text(
              displayName,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (member.isOwner) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Chủ nhà",
                  style: TextStyle(
                    color: Colors.amber[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else if (member.role.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  member.role,
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: email.isNotEmpty ? Text(
          email,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12,
          ),
        ) : null,
        trailing: !member.isOwner
            ? IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  size: 20,
                ),
                onPressed: () {
                  _showMemberOptions(context, member);
                },
              )
            : null,
      );
    },
  );
}

// Hàm fetch thông tin user từ Firestore
Future<Map<String, dynamic>?> _fetchUserInfo(String userId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    
    if (doc.exists) {
      return doc.data();
    }
    return null;
  } catch (e) {
    print('Error fetching user info: $e');
    return null;
  }
}
  Widget _buildRoomItem(BuildContext context, RoomModel room, int index) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final deviceController = Get.put(DeviceController());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getRoomColor(index).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: room.image?.isNotEmpty == true
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    room.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        _getRoomIcon(room.type),
                        color: _getRoomColor(index),
                        size: 24,
                      );
                    },
                  ),
                )
              : Icon(
                  _getRoomIcon(room.type),
                  color: _getRoomColor(index),
                  size: 24,
                ),
        ),
        title: Text(
          room.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "${room.devices.length} thiết bị",
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
            if (room.type != null) ...[
              const SizedBox(height: 2),
              Text(
                room.type!,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getRoomColor(index).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            room.devices.isNotEmpty ? "Đang bật" : "Tắt",
            style: TextStyle(
              color: _getRoomColor(index),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomDetailPage(
                homeId: _currentHome.id,
                room: room,
                devices: room.devices,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyRoomsState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.room_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            "Chưa có phòng nào",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Thêm phòng đầu tiên để quản lý thiết bị dễ dàng hơn",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              AddRoomDialog.show(context, _currentHome.id);
            },
            icon: Icon(Icons.add, size: 18, color: theme.colorScheme.onPrimary),
            label: Text("Thêm phòng mới", style: TextStyle(color: theme.colorScheme.onPrimary)),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoomColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }

  IconData _getRoomIcon(String? roomType) {
    switch (roomType?.toLowerCase()) {
      case 'living room':
      case 'phòng khách':
        return Icons.living_outlined;
      case 'bedroom':
      case 'phòng ngủ':
        return Icons.bed_outlined;
      case 'kitchen':
      case 'nhà bếp':
        return Icons.kitchen_outlined;
      case 'bathroom':
      case 'phòng tắm':
        return Icons.bathtub_outlined;
      case 'office':
      case 'phòng làm việc':
        return Icons.work_outline;
      default:
        return Icons.room_outlined;
    }
  }

  int _calculateTotalDevices(List<RoomModel> rooms) {
    return rooms.fold(0, (sum, room) => sum + room.devices.length);
  }

  void _showHomeOptions(BuildContext context) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.dialogBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit_outlined, color: theme.colorScheme.onSurface),
                title: Text('Chỉnh sửa thông tin nhà', style: TextStyle(color: theme.colorScheme.onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  AddHomePage(isAddHome:false, homeModel: _currentHome).show(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.people_outlined, color: theme.colorScheme.onSurface),
                title: Text('Quản lý thành viên', style: TextStyle(color: theme.colorScheme.onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  _showMembersManagement(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.share_outlined, color: theme.colorScheme.onSurface),
                title: Text('Chia sẻ quyền truy cập', style: TextStyle(color: theme.colorScheme.onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  // Share home access
                },
              ),
              ListTile(
                leading: Icon(Icons.qr_code_2_outlined, color: theme.colorScheme.onSurface),
                title: Text('Mã QR nhà', style: TextStyle(color: theme.colorScheme.onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  // Show QR code
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Xóa nhà', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteHomeDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMembersManagement(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Text(
          "Quản lý thành viên",
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Text(
          "Tính năng quản lý thành viên đang được phát triển",
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Đóng", style: TextStyle(color: theme.primaryColor)),
          ),
        ],
      ),
    );
  }

  // Cập nhật _showAddMemberDialog
void _showAddMemberDialog(BuildContext context, String homeId, String homeName) {
  final theme = Theme.of(context);
  final invitationService = Get.put(InvitationService());
  final TextEditingController emailController = TextEditingController();
  final isLoading = false.obs;

  showDialog(
    context: context,
    builder: (context) => Obx(() => AlertDialog(
      backgroundColor: theme.dialogBackgroundColor,
      title: Text(
        "Thêm thành viên",
        style: TextStyle(color: theme.colorScheme.onSurface),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: "Email thành viên",
              labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hintText: "nhập email người dùng",
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          Text(
            "Thành viên sẽ nhận được lời mời tham gia ngôi nhà này",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          if (isLoading.value) ...[
            const SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: isLoading.value ? null : () => Navigator.pop(context),
          child: Text("Hủy", 
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
        ),
        ElevatedButton(
          onPressed: isLoading.value ? null : () async {
            final email = emailController.text.trim();
            if (email.isEmpty) {
              Get.snackbar('Lỗi', 'Vui lòng nhập email',
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
              return;
            }

            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
              Get.snackbar('Lỗi', 'Email không hợp lệ',
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
              return;
            }

            isLoading.value = true;
            try {
              await invitationService.sendInvitation(
                toUserEmail: email,
                homeId: homeId,
                homeName: homeName,
              );
              
              Navigator.pop(context);
              Get.snackbar('Thành công', 'Đã gửi lời mời đến $email',
                backgroundColor: Colors.green,
                colorText: Colors.white,
                duration: Duration(seconds: 3),
              );
            } catch (e) {
              Get.snackbar('Lỗi', e.toString(),
                backgroundColor: Colors.red,
                colorText: Colors.white,
                duration: Duration(seconds: 5),
              );
            } finally {
              isLoading.value = false;
            }
          },
          child: Text("Gửi lời mời"),
        ),
      ],
    )),
  );
}

  void _showMemberOptions(BuildContext context, _MemberInfo member) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.dialogBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.remove_red_eye_outlined, color: theme.colorScheme.onSurface),
                title: Text('Xem thông tin', style: TextStyle(color: theme.colorScheme.onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  _showMemberInfo(context, member);
                },
              ),
              ListTile(
                leading: Icon(Icons.admin_panel_settings_outlined, color: theme.colorScheme.onSurface),
                title: Text('Phân quyền', style: TextStyle(color: theme.colorScheme.onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  _showRoleManagementDialog(context, member);
                  // Phân quyền thành viên
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.person_remove_outlined, color: Colors.red),
                title: Text('Xóa thành viên', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showRemoveMemberDialog(context, member);
                },
              ),
            ],
          ),
        );
      },
    );
  }
Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
  final theme = Theme.of(context);
  
  return Row(
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: theme.primaryColor,
          size: 16,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 2,
        child: Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ),
      Expanded(
        flex: 3,
        child: Text(
          value,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.right,
        ),
      ),
    ],
  );
}
  void _showMemberInfo(BuildContext context, _MemberInfo member) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: theme.dialogBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header với avatar lớn
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.3),
                  width: 3,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.primaryColor.withOpacity(0.1),
                    theme.primaryColor.withOpacity(0.05),
                  ],
                ),
              ),
              child: member.avatar != null
                  ? ClipOval(
                      child: Image.network(
                        member.avatar!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.person_outlined,
                      color: theme.primaryColor,
                      size: 40,
                    ),
            ),
            
            const SizedBox(height: 20),
            
            // Tên thành viên
            Text(
              member.name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Email
            Text(
              member.email,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Badge role với màu sắc đẹp
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: member.isOwner 
                  ? LinearGradient(
                      colors: [Colors.amber.shade400, Colors.orange.shade600],
                    )
                  : LinearGradient(
                      colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                    ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (member.isOwner ? Colors.amber : theme.primaryColor).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    member.isOwner ? Icons.star_rounded : Icons.person_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    member.role,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Thông tin chi tiết
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông tin chi tiết',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildInfoRow(
                    context,
                    Icons.calendar_today_rounded,
                    'Tham gia từ',
                    member.joinedAt ?? "Không rõ", // Cần thay bằng joinDate thực tế
                  ),
                
                  
                  const SizedBox(height: 8),
                  
                  _buildInfoRow(
                    context,
                    Icons.security_rounded,
                    'Quyền hạn',

                    member.isOwner ? HomeRole.admin.description : HomeRole.member.description,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Nút đóng
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showRoleManagementDialog(BuildContext context, _MemberInfo member) {
  final theme = Theme.of(context);
  String selectedRole = member.role;
  
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          backgroundColor: theme.dialogBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.purple,
                    size: 30,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Phân Quyền Thành Viên',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Chọn quyền cho ${member.name}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Danh sách quyền
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Quyền Admin
                      _buildRoleOption(
                        context,
                        value: 'Admin',
                        title: 'Quản trị viên',
                        description: 'Toàn quyền quản lý ngôi nhà',
                        icon: Icons.admin_panel_settings_rounded,
                        iconColor: Colors.purple,
                        isSelected: selectedRole == 'Admin',
                        onTap: () => setState(() => selectedRole = 'Admin'),
                      ),
                      
                      const Divider(height: 1),
                      
                      // Quyền Member
                      _buildRoleOption(
                        context,
                        value: 'Member',
                        title: 'Thành viên',
                        description: 'Quyền cơ bản, xem và điều khiển thiết bị',
                        icon: Icons.person_rounded,
                        iconColor: Colors.blue,
                        isSelected: selectedRole == 'Member',
                        onTap: () => setState(() => selectedRole = 'Member'),
                      ),
                      
                      const Divider(height: 1),
                      
                      // Quyền Guest
                      _buildRoleOption(
                        context,
                        value: 'Guest',
                        title: 'Khách',
                        description: 'Chỉ xem, không thể điều khiển thiết bị',
                        icon: Icons.visibility_rounded,
                        iconColor: Colors.green,
                        isSelected: selectedRole == 'Guest',
                        onTap: () => setState(() => selectedRole = 'Guest'),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Nút hành động
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: theme.dividerColor,
                          ),
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _updateMemberRole(member, selectedRole);
                          Navigator.pop(context);
                          
                          // Hiển thị snackbar thông báo
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã cập nhật quyền cho ${member.name}'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Xác nhận'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
Widget _buildRoleOption(
  BuildContext context, {
  required String value,
  required String title,
  required String description,
  required IconData icon,
  required Color iconColor,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  final theme = Theme.of(context);
  
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? theme.primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Radio button
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? theme.primaryColor : theme.dividerColor,
                width: 2,
              ),
            ),
            child: isSelected
                ? Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.primaryColor,
                    ),
                  )
                : null,
          ),
          
          const SizedBox(width: 16),
          
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          
          const SizedBox(width: 12),
          
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void _updateMemberRole(_MemberInfo member, String newRole) {
  // TODO: Implement update member role logic
  print('Updating ${member.name} role to $newRole');
  // Gọi API hoặc update Firestore ở đây
}
  void _showRemoveMemberDialog(BuildContext context, _MemberInfo member) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Row(
          children: [
            Icon(Icons.person_remove_outlined, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              "Xóa thành viên",
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ],
        ),
        content: Text(
          "Bạn có chắc chắn muốn xóa ${member.name} khỏi ngôi nhà này?",
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Xóa thành viên
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text("Xóa thành viên"),
          ),
        ],
      ),
    );
  }

  void _showDeleteHomeDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              "Xác nhận xóa nhà",
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ],
        ),
        content: Text(
          "Bạn có chắc chắn muốn xóa ngôi nhà này? "
          "Tất cả các phòng và thiết bị trong nhà sẽ bị xóa vĩnh viễn.",
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Hủy",
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final deviceController = Get.put(DeviceController());
              await deviceController.deleteHome(_currentHome.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text("Xóa nhà"),
          ),
        ],
      ),
    );
  }
}

// Cập nhật class _MemberInfo để hỗ trợ từ HomeMember
class _MemberInfo {
  final String userId;
  final String name;
  final String email;
  final String role;
  final String? joinedAt;
  final bool isOwner;
  final String? avatar;

  _MemberInfo({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.isOwner,
    this.joinedAt,
    this.avatar,
  });

  // Factory method để chuyển từ HomeMember sang _MemberInfo
  factory _MemberInfo.fromHomeMember(HomeMember member, User userInfo)   {

    return _MemberInfo(
      joinedAt: DateFormat('HH:mm - dd/MM/yyyy').format(member.joinedAt ?? DateTime.now()),
      userId: member.userId,
      name: userInfo.name ?? "Unknow", // Sẽ được fill từ FutureBuilder
      email: userInfo.email!, // Sẽ được fill từ FutureBuilder
      role: member.role.displayName,
      isOwner: member.isOwner,
      avatar: userInfo.profileImage,
    );
  }
}