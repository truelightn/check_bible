import 'package:check_bible/bible/bible_reading_screen.dart';
import 'package:check_bible/pray/prayer_time_input_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'login_screen.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();
  var isLoggedIn = false.obs;
  var username = ''.obs;
  var password = ''.obs;
  var userGradeClass = ''.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage storage = GetStorage(); // GetStorage 인스턴스

  // 로그인 처리
  Future<bool> login(String name, String gradeClass) async {
    try {
      // 사용자 정보를 Firestore에 저장
      await _firestore.collection('teachers').doc(name).set({
        'name': name,
        'gradeClass': gradeClass,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 로그인 상태 업데이트
      username.value = name;
      userGradeClass.value = gradeClass;
      isLoggedIn.value = true;

      return true;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  void _handleLoginSuccess(String inputUsername, String inputPassword, String gradeClass) {
    // 로그인 성공 처리
    username.value = inputUsername;
    password.value = inputPassword;
    isLoggedIn.value = true;

    // 로그인 상태를 로컬 스토리지에 저장
    storage.write('username', inputUsername);
    storage.write('password', inputPassword);
    storage.write('gradeClass', gradeClass);

    // 로그인 후 성경 읽기 화면으로 이동
    Get.to(() => PrayerTimeInputScreen());
  }

Future<void> _createNewAccount(String inputUsername, String inputPassword, String gradeClass) async {
    // 새 계정 생성
    await _firestore.collection('teachers').doc(inputUsername).set({
      'username': inputUsername,
      'password': inputPassword,
      'gradeClass': gradeClass, // 학년+반 정보 저장
      'bibleProgress': {}
    });
}



void autoLogin() {
    String? storedUsername = storage.read('username');
    String? storedPassword = storage.read('password');
    String? storedGradeClass = storage.read('gradeClass'); // 저장된 학년+반 정보 불러오기

    if (storedUsername != null && storedPassword != null && storedGradeClass != null) {
      login(storedUsername, storedGradeClass);
    }
  }

  // 로그아웃
  void logout() {
    username.value = '';
    userGradeClass.value = '';
    isLoggedIn.value = false;
  }

}
