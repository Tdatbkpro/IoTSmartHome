import 'package:get/route_manager.dart';
import 'package:iot_smarthome/Pages/Home/HomePage.dart';
import 'package:iot_smarthome/Pages/Notification/NotificationsPage.dart';
import 'package:iot_smarthome/Services/VoiceAssistantTTS.dart';
import 'package:iot_smarthome/Pages/Settings/Widget/FeedBack.dart';
import 'package:iot_smarthome/Pages/Home/Widget/ScanQRCodePage.dart';
import 'package:iot_smarthome/Pages/OnBoarding/Widget/OnBoardingPage.dart';
import 'package:iot_smarthome/Pages/SlacePage.dart';
import 'package:iot_smarthome/Pages/User/AuthPage.dart';

var pagePath = [
  GetPage(name: "/onBoarding", 
  page: () =>  OnBoardingPage(),
  transition: Transition.leftToRight,
  transitionDuration: Duration(microseconds: 500)
  
  ),
  GetPage(name: "/slace", 
  page: () =>  SlacePage(),
  transition: Transition.rightToLeft,
  transitionDuration: Duration(microseconds: 400)
  
  ),
  GetPage(name: "/authPath", 
  page: () =>  AuthPage(),
  transition: Transition.fadeIn,
  transitionDuration: Duration(microseconds: 400)
  
  ),
  GetPage(name: "/notifications", 
  page: () =>  NotificationPage(),
  transition: Transition.leftToRightWithFade,
  transitionDuration: Duration(microseconds: 400)
  
  ),
  GetPage(name: "/feedBack", 
  page: () =>  FeedbackPage(),
  transition: Transition.fadeIn,
  transitionDuration: Duration(microseconds: 300)
  
  ),
  GetPage(name: "/voiceAssistant", 
  page: () =>  VoiceAssistantTTS(),
  transition: Transition.fadeIn,
  transitionDuration: Duration(microseconds: 400)
  
  ),
    GetPage(name: "/scan", 
  page: () =>  ScanQRCodePage(),
  transition: Transition.fadeIn,
  transitionDuration: Duration(microseconds: 200)
  
  ),
  GetPage(name: "/homePage" 
  , page: () => HomePageContent(),)
];