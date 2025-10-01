import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Config/PagePath.dart';
import 'package:iot_smarthome/Pages/SlacePage.dart';
import 'package:iot_smarthome/Config/Theme.dart'; // nơi chứa lightTheme, darkTheme
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Nếu bạn có ClassBuilder
  // ClassBuilder.registerClasses();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "SmartHome",
      getPages: pagePath,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // mặc định chạy darkTheme
      debugShowCheckedModeBanner: false,
      home: const SlacePage(), // màn hình khởi chạy
      
    );
  }
}
