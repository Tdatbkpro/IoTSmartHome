import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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
      //backgroundColor: AppTheme.darkTheme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                      'assets/lotties/smarthome.json',
                      width: 200,
                      height: 200,
                      repeat: true,
                      onLoaded: (composition) {
                        Future.delayed(const Duration(seconds: 3), () {
                          // Navigator.pushReplacementNamed(context, '/home');
                        });
                      },
                    ),
              SizedBox(height: 16),
              Text(
                "Smart Home",
               style: Theme.of(context).textTheme.displayMedium),
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
            color: isSelected ? Colors.black : const Color.fromARGB(255, 106, 54, 54),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
