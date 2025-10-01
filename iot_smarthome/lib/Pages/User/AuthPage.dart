import 'package:flutter/material.dart';
import 'package:iot_smarthome/Config/Images.dart';
import 'package:iot_smarthome/Config/Theme.dart';
import './Widgets/Login.dart';
import './Widgets/Register.dart';
import './Widgets/ForgotPassword.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  String currentView = "login"; // login, register, forgot

  void switchView(String view) {
    setState(() {
      currentView = view;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkTheme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(AssetImages.logoApp,),
              SizedBox(height: 16),
              Text(
                "SmartHome",
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 40),
              // Toggle login/register
              if (currentView != "forgot")
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildToggleButton("Đăng nhập", "login"),
                    _buildToggleButton("Đăng ký", "register"),
                  ],
                ),
              SizedBox(height: 30),
              // Main content
              if (currentView == "login")
                LoginWidget(onForgot: () => switchView("forgot")),
              if (currentView == "register")
                RegisterWidget(),
              if (currentView == "forgot")
                ForgotPasswordWidget(onBack: () => switchView("login")),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text, String view) {
    bool isSelected = currentView == view;
    return GestureDetector(
      onTap: () => setState(() => currentView = view),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        margin: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.greenAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.greenAccent),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
