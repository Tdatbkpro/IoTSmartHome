import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Config/Theme.dart';
import 'package:iot_smarthome/Pages/OnBoarding/Widget/OnBoardingPage.dart';
import 'package:lottie/lottie.dart';
import 'package:iot_smarthome/Config/Colors.dart';
import 'package:iot_smarthome/Config/Texts.dart';
import 'package:iot_smarthome/Config/Images.dart';
import 'package:iot_smarthome/Config/Texts.dart';
class SlacePage extends StatefulWidget {
  const SlacePage({super.key});

  @override
  State<SlacePage> createState() => _SlacePageState();
}

class _SlacePageState extends State<SlacePage> {
  final onBoardingPage = Get.put(OnBoardingPage());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.surface,
      body: Column(
      
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ClipOval(
              child: Image.asset(
                AssetImages.logoApp, // ảnh avatar
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            
                    ),
            // ClipRRect(
            // borderRadius: BorderRadius.circular(16), // bo 16px
            // child: Image.asset(
            //   AssetImages.bannerApp, // ảnh banner
            //   fit: BoxFit.cover,
            // ),
            //         )
              ],
            ),
          ),
          Expanded(
            child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animation IoT
                    Lottie.asset(
                      'lotties/Home.json',
                      width: 300,
                      height: 300,
                      repeat: true,
                      onLoaded: (composition) {
                        Future.delayed(const Duration(seconds: 3), () {
                          // Navigator.pushReplacementNamed(context, '/home');
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    // Title
                    const Text(
                      "IoT Smart Home",
                      style: AppTextStyles.headline,
                    ),
                    const SizedBox(height: 12),
                    // Subtitle
                    const Text(
                      "Kết nối - Điều khiển - Trải nghiệm\nngôi nhà thông minh",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 40),
                    // Button thử nghiệm
                    ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(AppColors.primary),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    onPressed: () {
                      Get.toNamed("/onBoarding");
                    },
                    child: const Text("Khám phá ngay", style: AppTextStyles.button),
                  )


                  ],
                ),
              ),
          ),
        ],
      ),
    );
  }
}
