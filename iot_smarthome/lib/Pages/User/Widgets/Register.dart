import 'package:flutter/material.dart';
import '../Utils/AuthUtil.dart';
import '../../../Controllers/Auth.dart';

class RegisterWidget extends StatefulWidget {
  const RegisterWidget({super.key});

  @override
  State<RegisterWidget> createState() => _RegisterWidgetState();
}

class _RegisterWidgetState extends State<RegisterWidget> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
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
          AuthUtils.buildTextField(Icons.person, "Họ và tên", nameController),
          SizedBox(height: 16),
          AuthUtils.buildTextField(Icons.email, "Email", emailController),
          SizedBox(height: 16),
          AuthUtils.buildTextField(Icons.lock, "Mật khẩu", passwordController, isPassword: true, obscureText: _obscure, toggleObscure: () {
            setState(() { _obscure = !_obscure; });
          }),
          SizedBox(height: 20),
          AuthUtils.buildGradientButton("Đăng ký", () {
            authController.signUp(emailController.text, passwordController.text, nameController.text);
            if (_formKey.currentState!.validate()) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đang đăng ký...")));
            }
          }),
        ],
      ),
    );
  }
}
