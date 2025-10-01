import 'package:flutter/material.dart';

/// RoomModel (Firestore)
class RoomModel {
  final String id;
  final String name;
  final String type;
  final String? image;
  final String? description;

  RoomModel({
    required this.id,
    this.image,
    required this.type,
    required this.name,
    this.description,
  });

  factory RoomModel.fromMap(String id, Map<String, dynamic> map) {
    return RoomModel(
      id: id,
      image: map['image'],
      name: map['name'] ?? 'Unknown Room',
      description: map['description'] ?? '', 
      type: map['type'] ?? 'Unknown Room',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'name': name,
      'description': description,
      'image': image
    };
  }
}


class Device {
  final String id;
  final String? name;
  final String? type;
  final String? roomId;

  Device({
    required this.id,
    this.name,
    this.type,
    this.roomId,
  });

  factory Device.fromMap(String id, Map<String, dynamic> map, String roomId) {
    return Device(
      id: id,
      name: map["name"] ?? "Unknown",
      type: map["type"],
      roomId: roomId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "type": type,
      "roomId": roomId,
    };
  }
}

