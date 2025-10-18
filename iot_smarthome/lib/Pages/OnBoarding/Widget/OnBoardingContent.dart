import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Config/Texts.dart';

class OnBoardingContent extends StatelessWidget {
  final Size size;
  final String? title, image, subtitle, step;
  const OnBoardingContent({
    super.key,
    required this.size,
    this.title,
    this.image,
    this.subtitle,
    this.step,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
      child: Column(
        children: [
          // Image Section
          Expanded(
            flex: 3,
            child: Container(
              margin: EdgeInsets.only(bottom: size.height * 0.04),
              child: Stack(
                children: [
                  // Background decoration
                  Positioned(
                    bottom: 0,
                    left: size.width * 0.1,
                    right: size.width * 0.1,
                    child: Container(
                      height: size.height * 0.25,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.blue.withOpacity(0.1),
                            Colors.blue.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),
                  
                  // Image
                  Center(
                    child: Image.asset(
                      image!,
                      height: size.height * 0.35,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Text Content Section
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Title
                Text(
                  title!,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 16),
                
                // Divider
                Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Subtitle
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}