import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:get/route_manager.dart';
import 'package:iot_smarthome/Pages/Home/HomePage.dart';
import 'package:iot_smarthome/Pages/OnBoarding/Widget/OnBoardingPage.dart';
import 'package:iot_smarthome/Pages/SlacePage.dart';
import 'package:iot_smarthome/Pages/User/AuthPage.dart';
import 'package:iot_smarthome/Pages/User/Widgets/Login.dart';

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
  GetPage(name: "/homePage" 
  , page: () => HomePageContent(),)
];