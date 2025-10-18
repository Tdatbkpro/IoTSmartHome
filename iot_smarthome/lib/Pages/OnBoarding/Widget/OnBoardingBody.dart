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
  final auth = FirebaseAuth.instance;
  int currentPage = 0;

  final List<Map<String, String>> onBoardingDatas = [
    {
      "step": "1",
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
    
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header với step indicator
            _buildHeader(size),
            
            // PageView content
            Expanded(
              flex: 4,
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
                },
              ),
            ),
            
            // Bottom section với indicator và button
            _buildBottomSection(size, auth),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.08,
        vertical: size.height * 0.02,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button (chỉ hiện khi không phải page đầu)
          if (currentPage > 0)
            GestureDetector(
              onTap: () {
                _pageController.previousPage(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.ease,
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 20,
                  color: Colors.grey[600],
                ),
              ),
            )
          else
            SizedBox(width: 40),
          
          // Step indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Step ${currentPage + 1}/3",
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          
          // Skip button (chỉ hiện khi không phải page cuối)
          if (currentPage < onBoardingDatas.length - 1)
            TextButton(
              onPressed: () {
                if (auth.currentUser != null) {
                  Get.toNamed("/homePage");
                } else {
                  Get.toNamed("/authPath");
                }
              },
              child: Text(
                "Skip",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildBottomSection(Size size, FirebaseAuth auth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.08,
        vertical: size.height * 0.04,
      ),
      child: Column(
        children: [
          // Smooth Page Indicator
          SmoothPageIndicator(
            controller: _pageController,
            count: onBoardingDatas.length,
            effect: ExpandingDotsEffect(
              activeDotColor: Colors.blue,
              dotColor: Colors.grey[300]!,
              dotHeight: 8,
              dotWidth: 8,
              spacing: 12,
              expansionFactor: 3,
            ),
          ),
          
          SizedBox(height: size.height * 0.04),
          
          // Next/Enter Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                currentPage < onBoardingDatas.length - 1 ? "Continue" : "Get Started",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}