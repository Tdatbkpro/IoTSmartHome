import 'package:flutter/material.dart';
import 'package:iot_smarthome/Pages/OnBoarding/Widget/OnBoardingBody.dart';
import 'package:iot_smarthome/Config/Theme.dart';
class OnBoardingPage extends StatelessWidget {
  const OnBoardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: OnBoardingBody(),
    );
  }
}