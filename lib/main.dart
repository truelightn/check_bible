import 'package:check_bible/auth_controller.dart';
import 'package:check_bible/bible/bible_reading_screen.dart';
import 'package:check_bible/firebase_options.dart';
import 'package:check_bible/login_screen.dart';
import 'package:check_bible/pray/prayer_time_input_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GetStorage.init(); // GetStorage 초기화
  await initializeDateFormatting('ko_KR', null); // 한국어 로케일 초기화
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthController authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    // 앱 시작 시 자동 로그인 시도
    authController.autoLogin();

    return GetMaterialApp(
      title: '25년 고등부 여름 수련회 다니엘 기도회!',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Obx(() {
        // 로그인 상태에 따라 다른 화면을 보여줌
        return authController.isLoggedIn.value ? PrayerTimeInputScreen() : LoginScreen();
      }),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ko', 'KR'),
    );
  }
}
