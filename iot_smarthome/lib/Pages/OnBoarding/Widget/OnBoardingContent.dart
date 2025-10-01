import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Config/Texts.dart';
class OnBoardingContent extends StatelessWidget {
  final Size size;
  final String? title, image,subtitle, step;
  const OnBoardingContent({super.key, required this.size, this.title, this.image, this.subtitle, this.step});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.08, vertical: size.height * 0.015),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              step != "1" ?  InkWell(
                child: Icon(
                Icons.arrow_back,
                
                size: 30,
                color: Colors.black38,
              ),
              onTap: () {
                Get.toNamed("/slace");
              },
              ):Container(),
              Text(
                "Step $step",
                style: AppTextStyles.body.copyWith(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Image.asset(
            image!,
            //width: double.infinity,
            alignment: Alignment.center,
            fit:BoxFit.fitWidth
          ),
        ),
        SizedBox(height: size.height * 0.03),
        Text(
          title!,
          style: AppTextStyles.body,
        ),
        Divider(
          thickness: 2.0,
          color: Colors.blue,
          endIndent: size.width * 0.4,
          indent: size.width * 0.4,
        ),
        SizedBox(height: size.height * 0.03),
        Text(
          subtitle!,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(fontSize: 18),
        ),
      ],
    );
  }
}