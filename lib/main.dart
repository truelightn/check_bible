import 'package:check_bible/auth_controller.dart';
import 'package:check_bible/bible_reading_screen.dart';
import 'package:check_bible/firebase_options.dart';
import 'package:check_bible/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); 
  await GetStorage.init(); // GetStorage 초기화
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthController authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    // 앱 시작 시 자동 로그인 시도
    authController.autoLogin();

    return GetMaterialApp(
      title: 'Bible Reading Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Obx(() {
        // 로그인 상태에 따라 다른 화면을 보여줌
        return authController.isLoggedIn.value ? BibleReadingScreen() : LoginScreen();
      }),
    );
  }
}
