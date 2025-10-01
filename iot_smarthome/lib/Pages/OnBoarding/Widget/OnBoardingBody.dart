import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Pages/OnBoarding/Widget/OnBoardingContent.dart';
import 'package:iot_smarthome/Config/Images.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
class OnBoardingBody extends StatefulWidget {
  const OnBoardingBody({super.key});

  @override
  State<OnBoardingBody> createState() => _OnBoardingBodyState();
}

class _OnBoardingBodyState extends State<OnBoardingBody> {
  final PageController _pageController = PageController();
  int currentPage = 0;

  final List<Map<String, String>> onBoardingDatas = [
    {
      "step" : "1",
      "image": AssetImages.feature1,
      "title": "IoT Coursework",
      "subtitle": "You are few click away to enter, The world of Smart Home."
    },
    {
      "step": "2",
      "image": AssetImages.feature2,
      "title": "Smart Devices",
      "subtitle": "Control lights, ACs, and appliances easily from your app."
    },
    {
      "step": "3",
      "image": AssetImages.feature3,
      "title": "Automation",
      "subtitle": "Schedule tasks automatically and save energy efficiently."
    },

  ];  
  
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final auth = FirebaseAuth.instance;
    return SafeArea(child: Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: onBoardingDatas.length,
            onPageChanged: (index) {
              setState(() {
                currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final onBoardingData = onBoardingDatas[index];
              return OnBoardingContent(
                size: size,
                image: onBoardingData["image"],
                step: onBoardingData["step"],
                title: onBoardingData["title"],
                subtitle: onBoardingData["subtitle"],
                );
            }) 
        ),
        SmoothPageIndicator(
          controller: _pageController, 
          count: onBoardingDatas.length,
          axisDirection: Axis.horizontal,    
          effect:  SlideEffect(    
              spacing:  8.0,    
              radius:  4.0,    
              dotWidth:  12.0,    
              dotHeight:  12.0,    
              paintStyle:  PaintingStyle.stroke,    
              strokeWidth:  1.5,    
              dotColor:  Colors.grey,    
              activeDotColor:  Colors.indigo    
          ),
          ),
          SizedBox(height: size.height * 0.03),
          // Skip / Next button
            TextButton(
              onPressed: () {
                // Nếu chưa tới page cuối → next, nếu cuối → có thể đi vào app
                if (currentPage < onBoardingDatas.length - 1) {
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.ease,
                  );
                } else {
                  debugPrint(auth.currentUser.toString());
                  if (auth.currentUser != null) {
                    Get.toNamed("/homePage");
                  } else {
                    Get.toNamed("/authPath");
                  }

                }
              },
              child: Text(
                currentPage < onBoardingDatas.length - 1 ? "Next" : "Enter",
                style: TextStyle(fontSize: 16),
              ),
            ),
      ],
    ));
  }
}