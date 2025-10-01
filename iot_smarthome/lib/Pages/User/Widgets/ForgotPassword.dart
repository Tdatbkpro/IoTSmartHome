import 'package:flutter/material.dart';
import '../Utils/AuthUtil.dart';
import '../../../Controllers/Auth.dart';
class ForgotPasswordWidget extends StatefulWidget {
  final VoidCallback onBack;
  const ForgotPasswordWidget({super.key, required this.onBack});

  @override
  State<ForgotPasswordWidget> createState() => _ForgotPasswordWidgetState();
}

class _ForgotPasswordWidgetState extends State<ForgotPasswordWidget> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authController = AuthController();
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Text(
            "Nhập email để lấy lại mật khẩu",
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 16),
          AuthUtils.buildTextField(Icons.email, "Email", emailController),
          SizedBox(height: 20),
          AuthUtils.buildGradientButton("Gửi yêu cầu", () {
            authController.sendPasswordResetEmail(emailController.text);
            if (_formKey.currentState!.validate()) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã gửi email lấy lại mật khẩu")));
            }
          }),
          SizedBox(height: 10),
          TextButton(
            onPressed: widget.onBack,
            child: Text("Quay lại đăng nhập", style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
