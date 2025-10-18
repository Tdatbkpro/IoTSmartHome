import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final LocalAuthentication auth = LocalAuthentication();
  bool _obscure = true;
  RxBool verification = false.obs;
  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    emailController.text = prefs.getString('saved_email') ?? '';
    passwordController.text = prefs.getString('saved_password') ?? '';
  }

  Future<void> _saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
    await prefs.setString('saved_password', password);
  }

  Future<void> _login(AuthController authController) async {
    if (_formKey.currentState!.validate()) {
      String email = emailController.text.trim();
      String password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        Get.snackbar("Lỗi", "Vui lòng nhập đầy đủ thông tin");
        return;
      }

      await _saveCredentials(email, password);
      await authController.signIn(email, password);
    }
  }

  Future<void> _loginWithFingerprint(AuthController authController) async {
    try {
      bool canAuth = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!canAuth) {
        Get.snackbar("Không hỗ trợ", "Thiết bị không hỗ trợ xác thực vân tay");
        return;
      }

      bool authenticated = await auth.authenticate(
        localizedReason: "Xác thực vân tay để đăng nhập",
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (authenticated) {
          final prefs = await SharedPreferences.getInstance();
          final email = prefs.getString('saved_email');
          final password = prefs.getString('saved_password');

          if (email != null && password != null) {
            verification.value = true;
            //  Get.snackbar("Thành công", "Xác thực vân tay thành công, đang đăng nhập...");

            // 🕐 Hiển thị hiệu ứng trong 2 giây trước khi đăng nhập thật
            await Future.delayed(const Duration(milliseconds: 2000));

            await authController.signIn(email, password);
          } else {
            Get.snackbar("Thông báo", "Chưa có tài khoản được lưu. Vui lòng đăng nhập thủ công trước.");
          }
        }

    } catch (e) {
      debugPrint(e.toString());
      Get.snackbar("Lỗi", "Không thể xác thực vân tay: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = AuthController();

    return Form(
      key: _formKey,
      child: Column(
        children: [
          AuthUtils.buildTextField(Icons.email, "Email", emailController),
          const SizedBox(height: 16),
          AuthUtils.buildTextField(
            Icons.lock,
            "Mật khẩu",
            passwordController,
            isPassword: true,
            obscureText: _obscure,
            toggleObscure: () => setState(() => _obscure = !_obscure),
          ),
          const SizedBox(height: 20),

          // Nút đăng nhập thường
          AuthUtils.buildGradientButton("Đăng nhập", () => _login(authController)),

          const SizedBox(height: 25),

          // 🔒 Nút vân tay
          GestureDetector(
            onTap: () => _loginWithFingerprint(authController),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.greenAccent, Colors.teal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(2, 4),
                  )
                ],
              ),
              child: Obx(() => verification.value ?Lottie.asset("assets/lotties/fingerprinter.json", height: 70, width: 70, ) :  Icon(Icons.fingerprint, size: 40, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 10),
          const Text("Đăng nhập bằng vân tay", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),

          TextButton(
            onPressed: widget.onForgot,
            child: const Text("Quên mật khẩu?"),
          ),
        ],
      ),
    );
  }
}
