import 'package:check_bible/bible_reading_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'login_screen.dart';

class AuthController extends GetxController {
  var isLoggedIn = false.obs;
  var username = ''.obs;
  var password = ''.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage storage = GetStorage(); // GetStorage 인스턴스

  // 로그인 기능
  void login(String inputUsername, String inputPassword) async {
    var result = await _firestore.collection('users')
        .doc(inputUsername)
        .get();

    if (result.exists) {
      var data = result.data()!;
      if (data['password'] == inputPassword) {
        // 로그인 성공
        username.value = inputUsername;
        password.value = inputPassword;
        isLoggedIn.value = true;

        // 로그인 상태를 로컬 스토리지에 저장
        storage.write('username', inputUsername);
        storage.write('password', inputPassword);

        // 로그인 후 성경 읽기 화면으로 이동
        Get.to(() => BibleReadingScreen());
      } else {
        Get.snackbar('Error', 'Invalid password');
      }
    } else {
      // 계정 생성 및 로그인
      await _firestore.collection('users').doc(inputUsername).set({
        'username': inputUsername,
        'password': inputPassword,
        'bibleProgress': {}
      });

      // 계정 생성 후 로그인 처리
      username.value = inputUsername;
      password.value = inputPassword;
      isLoggedIn.value = true;

      // 로그인 상태를 로컬 스토리지에 저장
      storage.write('username', inputUsername);
      storage.write('password', inputPassword);

      Get.snackbar('Success', 'Account created and logged in');
      Get.to(() => BibleReadingScreen());
    }
  }

  // 자동 로그인 기능
  void autoLogin() {
    String? storedUsername = storage.read('username');
    String? storedPassword = storage.read('password');

    if (storedUsername != null && storedPassword != null) {
      login(storedUsername, storedPassword);
    }
  }

  // 로그아웃
  void logout() {
    username.value = '';
    password.value = '';
    isLoggedIn.value = false;
    storage.remove('username');
    storage.remove('password');
    Get.offAll(() => LoginScreen()); // 로그아웃 후 로그인 화면으로 이동
  }
}
