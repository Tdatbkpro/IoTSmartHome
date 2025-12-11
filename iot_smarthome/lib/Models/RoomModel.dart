
import 'dart:ffi';

/// RoomModel (Firestore)
class RoomModel {
  final String id;
  final String name;
  final String type;
  final String? image;
  final String? description;
  final String? hoomId; // 🆕 thêm trường ownerId
  final List<String> allowedUsers;
  final List<Device> devices; // giữ nguyên

  RoomModel({
    required this.id,
    required this.name,
    required this.type,
    this.image,
    this.description,
    this.hoomId, // 🆕 thêm vào constructor
    this.allowedUsers = const [],
    this.devices = const [],
  });

  RoomModel copyWithDevices(List<Device> newDevices) {
    return RoomModel(
      id: id,
      name: name,
      type: type,
      image: image,
      description: description,
      hoomId: hoomId, // 🆕 thêm
      allowedUsers: allowedUsers,
      devices: newDevices,
    );
  }

  factory RoomModel.fromMap(String id, Map<String, dynamic> map) {
  return RoomModel(
    id: id,
    image: map['image'],
    name: map['name'] ?? 'Unknown Room',
    description: map['description'] ?? '',
    type: map['type'] ?? 'Unknown Room',
    hoomId: map['hoomId'],
    allowedUsers: List<String>.from(map['allowedUsers'] ?? []),
    devices:  [], // sẽ load sau
  );
}

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'name': name,
      'description': description,
      'image': image,
      'hoomId': hoomId, // 🆕 thêm vào khi lưu
      'allowedUsers': allowedUsers,
    };
  }
}



class Device {
  final String id;
  final String? name;
  final double? power;
  final String? type;
  final String? roomId;

  Device( {
    required this.id,
    this.name,
    this.power,
    this.type,
    this.roomId,
  });

  factory Device.fromMap(String id, Map<String, dynamic> map, String roomId) {
    return Device(
      id: id,
      name: map["name"] ?? "Unknown",
      type: map["type"],
      roomId: roomId,
      power: map["power"] ?? 0.0
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "type": type,
      "roomId": roomId,
      "power" : power
    };
  }

  Device copyWith({
  String? id,
  String? name,
  double? power,
  String? type,
  String? roomId,
}) {
  return Device(
    id: id ?? this.id,
    name: name ?? this.name,
    power: power ?? this.power,
    type: type ?? this.type,
    roomId: roomId ?? this.roomId,
  );
}

}

