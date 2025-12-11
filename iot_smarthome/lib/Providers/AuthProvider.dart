// Auth Controller Provider
import 'package:firebase_auth/firebase_auth.dart' ;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_smarthome/Controllers/Auth.dart';
import 'package:iot_smarthome/Models/UserModel.dart' as UserModel;

// Provider cho current user (Firebase Auth)
final currentUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user.asData?.value?.uid;
});
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController();
});

// Stream provider cho current user data từ Firestore
final currentUserDataProvider = StreamProvider<UserModel.User?>((ref) {
  final authController = ref.watch(authControllerProvider);
  final userId = ref.watch(currentUserIdProvider);
  
  if (userId == null) return const Stream.empty();
  
  return authController.getUserByIdStream(userId);
});