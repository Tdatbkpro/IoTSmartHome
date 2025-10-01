// ignore: file_names
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class User {
  String? id;
  String? name;
  String? email;
  String? profileImage;
  String? phoneNumber;
  DateTime? createdAt;
  String? bio;
  String? status;
  DateTime? lastOnlineStatus;

  User({
    this.id,
    this.name,
    this.email,
    this.profileImage,
    this.phoneNumber,
    this.createdAt,
    this.bio,
    this.status,
    this.lastOnlineStatus,
  });

  // ✅ Hàm copyWith
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImage,
    String? phoneNumber,
    DateTime? createdAt,
    String? bio,
    String? status,
    DateTime? lastOnlineStatus,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      bio: bio ?? this.bio,
      status: status ?? this.status,
      lastOnlineStatus: lastOnlineStatus ?? this.lastOnlineStatus,
    );
  }

  // Convert JSON to Dart object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      profileImage: json['profileImage'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      bio: json['bio'] as String?,
      status: json['status'] as String?,
      lastOnlineStatus: json['lastOnlineStatus'] != null
          ? DateTime.tryParse(json['lastOnlineStatus'].toString())
          : null,
    );
  }

  // Convert Dart object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt?.toIso8601String(),
      'bio': bio,
      'status': status,
      'lastOnlineStatus': lastOnlineStatus?.toIso8601String(),
    };
  }
  // ✅ Tạo User từ FirebaseAuth
factory User.fromFirebase(firebase_auth.User firebaseUser) {
  return User(
    id: firebaseUser.uid,
    name: firebaseUser.displayName,
    email: firebaseUser.email,
    profileImage: firebaseUser.photoURL,
    phoneNumber: firebaseUser.phoneNumber,
    createdAt: DateTime.now(), // hoặc firebaseUser.metadata.creationTime nếu cần
  );
}

}