import 'package:iot_smarthome/Models/RoomModel.dart';

class HomeModel {
  final String id;
  final String name;
  final String ownerId; // userId chủ nhà
  final String? image;
  final String? location; // địa chỉ cụ thể (ví dụ: "123 Nguyễn Huệ, Quận 1, TP.HCM")
  final double? latitude;  // vĩ độ
  final double? longitude; // kinh độ
  final List<RoomModel> rooms;
  final List<HomeMember> members; // Danh sách thành viên trong nhà
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HomeModel({
    required this.id,
    required this.name,
    required this.ownerId,
    this.image,
    this.location,
    this.latitude,
    this.longitude,
    this.rooms = const [],
    this.members = const [],
    this.createdAt,
    this.updatedAt,
  });

  // Trong HomeModel.fromMap, cập nhật phần members:
factory HomeModel.fromMap(String id, Map<String, dynamic> map) {
  return HomeModel(
    id: id,
    name: map['name'] ?? 'Unknown Home',
    ownerId: map['ownerId'] ?? '',
    image: map['image'],
    location: map['location'],
    latitude: map['latitude']?.toDouble(),
    longitude: map['longitude']?.toDouble(),
    rooms: [], // load room riêng sau
    members: _parseMembers(map['members']), // Parse members từ Firestore
    createdAt: map['createdAt'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
        : null,
    updatedAt: map['updatedAt'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
        : null,
  );
}

// Helper method để parse members
static List<HomeMember> _parseMembers(dynamic membersData) {
  if (membersData is List) {
    return membersData.map((memberMap) {
      if (memberMap is Map<String, dynamic>) {
        return HomeMember.fromMap(memberMap);
      } else if (memberMap is String) {
        // Nếu members chỉ là array of user IDs
        return HomeMember(
          userId: memberMap,
          role: HomeRole.member,
          joinedAt: DateTime.now(),
        );
      }
      return HomeMember(
        userId: '',
        role: HomeRole.member,
        joinedAt: DateTime.now(),
      );
    }).toList();
  }
  return [];
}

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'image': image,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'members': members.map((member) => member.toMap()).toList(),
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  // Helper methods
  bool isOwner(String userId) {
    return ownerId == userId;
  }

  bool isMember(String userId) {
    return members.any((member) => member.userId == userId) || isOwner(userId);
  }

  HomeMember? getMember(String userId) {
    return members.firstWhere((member) => member.userId == userId);
  }

  List<HomeMember> get allMembersWithOwner {
    // Trả về tất cả thành viên bao gồm cả chủ nhà
    final ownerMember = HomeMember(
      userId: ownerId,
      role: HomeRole.owner,
      joinedAt: createdAt ?? DateTime.now(),
    );
    return [ownerMember, ...members];
  }

  // Copy with method để dễ dàng cập nhật
  HomeModel copyWith({
    String? id,
    String? name,
    String? ownerId,
    String? image,
    String? location,
    double? latitude,
    double? longitude,
    List<RoomModel>? rooms,
    List<HomeMember>? members,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HomeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      image: image ?? this.image,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rooms: rooms ?? this.rooms,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class HomeMember {
  final String userId;
   HomeRole role;
  final DateTime joinedAt;
  final DateTime? invitedAt;
  final String? invitedBy; // userId người mời
  final bool isActive;

  HomeMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.invitedAt,
    this.invitedBy,
    this.isActive = true,
  });

  factory HomeMember.fromMap(Map<String, dynamic> map) {
    return HomeMember(
      userId: map['userId'] ?? '',
      role: HomeRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => HomeRole.member,
      ),
      joinedAt: map['joinedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['joinedAt'])
          : DateTime.now(),
      invitedAt: map['invitedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['invitedAt'])
          : null,
      invitedBy: map['invitedBy'],
      isActive: map['isActive'] ?? true,
    );
  }
  factory HomeMember.empty() {
    return HomeMember.empty();
  }
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role.name,
      'joinedAt': joinedAt.millisecondsSinceEpoch,
      'invitedAt': invitedAt?.millisecondsSinceEpoch,
      'invitedBy': invitedBy,
      'isActive': isActive,
    };
  }

  // Copy with method
  HomeMember copyWith({
    String? userId,
    HomeRole? role,
    DateTime? joinedAt,
    DateTime? invitedAt,
    String? invitedBy,
    bool? isActive,
  }) {
    return HomeMember(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      invitedAt: invitedAt ?? this.invitedAt,
      invitedBy: invitedBy ?? this.invitedBy,
      isActive: isActive ?? this.isActive,
    );
  }

  // Helper methods
  bool get isOwner => role == HomeRole.owner;
  bool get isAdmin => role == HomeRole.admin;
  bool get isMember => role == HomeRole.member;
}

enum HomeRole {
  owner,   // Chủ nhà - toàn quyền
  admin,   // Quản trị - có thể thêm/xóa thành viên, quản lý thiết bị
  member,  // Thành viên - chỉ có thể điều khiển thiết bị
  guess,
}

// Extension để hiển thị tên role tiếng Việt
extension HomeRoleExtension on HomeRole {
  String get displayName {
    switch (this) {
      case HomeRole.owner:
        return 'Chủ nhà';
      case HomeRole.admin:
        return 'Quản trị';
      case HomeRole.member:
        return 'Thành viên';
      case HomeRole.guess:
        return "Khách";
    }
  }

  String get description {
    switch (this) {
      case HomeRole.owner:
        return 'Toàn quyền quản lý nhà';
      case HomeRole.admin:
        return 'Có thể quản lý thành viên và thiết bị';
      case HomeRole.member:
        return 'Chỉ có thể điều khiển thiết bị';
        case HomeRole.guess:
        return 'Chỉ có xem thông tin nhà';
    }
  }
}