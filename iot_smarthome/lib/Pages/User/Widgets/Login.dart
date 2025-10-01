import 'package:flutter/material.dart';
import '../Utils/AuthUtil.dart';
import '../../../Controllers/Auth.dart';

class LoginWidget extends StatefulWidget {
  final VoidCallback onForgot;
  const LoginWidget({super.key, required this.onForgot});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final authController = AuthController();
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AuthUtils.buildTextField(Icons.email, "Email", emailController),
          SizedBox(height: 16),
          AuthUtils.buildTextField(Icons.lock, "Mật khẩu", passwordController, isPassword: true, obscureText: _obscure, toggleObscure: () {
            setState(() { _obscure = !_obscure; });
          }),
          SizedBox(height: 20),
          AuthUtils.buildGradientButton("Đăng nhập", () {
            authController.signIn(emailController.text, passwordController.text);
            if (_formKey.currentState!.validate()) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đang đăng nhập...")));
            }
          }),
          SizedBox(height: 10),
          TextButton(
            onPressed: widget.onForgot,
            child: Text("Quên mật khẩu?", style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
