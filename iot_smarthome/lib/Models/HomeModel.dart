import 'package:iot_smarthome/Models/RoomModel.dart';

class HomeModel {
  final String id;
  final String name;
  final String ownerId; // userId chủ nhà
  final String? image;
  final List<RoomModel> rooms;

  HomeModel({

    required this.id,
    required this.name,
    this.image,
    required this.ownerId,
    this.rooms = const [],
  });

  factory HomeModel.fromMap(String id, Map<String, dynamic> map) {
    return HomeModel(
      id: id,
      name: map['name'] ?? 'Unknown Home',
      ownerId: map['ownerId'] ?? '',
      image: map['image'],
      rooms: [], // load room riêng sau
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'image': image
    };
  }
}
