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
  var userType = ''.obs; // 사용자 타입 (학생/교사)

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage storage = GetStorage(); // GetStorage 인스턴스

  // 로그인 처리
  Future<bool> login(String name, String gradeClass, String userTypeValue) async {
    try {
      // 사용자 타입에 따라 다른 컬렉션에 저장
      String collection = userTypeValue == '학생' ? 'students' : 'teachers';
      
      // 사용자 정보를 Firestore에 저장
      await _firestore.collection(collection).doc(name).set({
        'name': name,
        'gradeClass': gradeClass,
        'userType': userTypeValue,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 로그인 상태 업데이트
      username.value = name;
      userGradeClass.value = gradeClass;
      userType.value = userTypeValue;
      isLoggedIn.value = true;

      // 로그인 정보를 로컬 스토리지에 저장
      await storage.write('username', name);
      await storage.write('gradeClass', gradeClass);
      await storage.write('userType', userTypeValue);
      await storage.write('isLoggedIn', true);

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
    try {
      String? storedUsername = storage.read('username');
      String? storedGradeClass = storage.read('gradeClass');
      String? storedUserType = storage.read('userType');
      bool? isStoredLoggedIn = storage.read('isLoggedIn');

      if (storedUsername != null && storedGradeClass != null && storedUserType != null && isStoredLoggedIn == true) {
        username.value = storedUsername;
        userGradeClass.value = storedGradeClass;
        userType.value = storedUserType;
        isLoggedIn.value = true;
        print('Auto login successful: ${username.value} (${userType.value})'); // 디버깅용 로그
      } else {
        print('No stored login data found'); // 디버깅용 로그
        isLoggedIn.value = false;
      }
    } catch (e) {
      print('Auto login error: $e'); // 디버깅용 로그
      isLoggedIn.value = false;
    }
  }

  // 로그아웃
  void logout() {
    // 로그아웃 시 로컬 스토리지의 데이터도 삭제
    storage.remove('username');
    storage.remove('gradeClass');
    storage.remove('userType');
    storage.remove('isLoggedIn');
    
    username.value = '';
    userGradeClass.value = '';
    userType.value = '';
    isLoggedIn.value = false;
  }

}
