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

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthController authController = Get.put(AuthController());
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 자동 로그인 시도
    await Future.delayed(const Duration(milliseconds: 100)); // 약간의 딜레이
    authController.autoLogin();
    
    // 초기화 완료
    setState(() {
      isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '성락교회 고등부',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'NotoSansKR',
      ),
      home: !isInitialized
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B3DFF)),
                ),
              ),
            )
          : Obx(() {
              // 자동 로그인 상태에 따라 다른 화면으로 이동
              if (authController.isLoggedIn.value && authController.username.value.isNotEmpty) {
                return const PrayerTimeInputScreen();
              } else {
                return LoginScreen();
              }
            }),
      getPages: [
        GetPage(name: '/', page: () => LoginScreen()),
        GetPage(name: '/prayer_time_input', page: () => const PrayerTimeInputScreen()),
      ],
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
