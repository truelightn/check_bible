import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_controller.dart'; // AuthController를 불러옵니다.

class BibleController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController authController = Get.find<AuthController>(); // AuthController 사용

  // 각 책과 장별로 읽기 상태를 저장하는 맵 (책 이름 -> (장 번호 -> 읽음 여부))
  var bibleProgress = <String, Map<int, bool>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Firestore에서 초기 데이터를 불러오는 함수
    loadUserProgress();
  }

  // Firestore에서 사용자 성경 읽기 진행 정보를 불러오는 함수
  void loadUserProgress() async {
    // 로그인한 사용자의 username 값을 가져옵니다.
    String username = authController.username.value;

    try {
      // Firestore에서 해당 사용자의 데이터를 불러옵니다.
      var userDoc = await _firestore.collection('users').doc(username).get();
      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data()!;

        // Firestore에서 읽어온 데이터를 int로 변환
        if (data.containsKey('bibleProgress')) {
          var progressData = Map<String, dynamic>.from(data['bibleProgress']);
          progressData.forEach((book, chapters) {
            bibleProgress[book] = Map<int, bool>.from(
              (chapters as Map).map((key, value) => MapEntry(int.parse(key), value))
            );
          });

          // 상태를 강제 리프레시하여 UI에 반영
          bibleProgress.refresh();
        }
      }
    } catch (error) {
      Get.snackbar('Error', 'Failed to load progress');
    }
  }

  // 특정 책과 장의 읽기 상태를 업데이트하고 Firestore에 저장하는 함수
  void updateChapterProgress(String book, int chapter, bool isChecked) {
    // 상태를 즉시 업데이트
    if (!bibleProgress.containsKey(book)) {
      bibleProgress[book] = {};
    }
    bibleProgress[book]![chapter] = isChecked;

    // 상태 강제 리프레시하여 즉시 UI에 반영
    bibleProgress.refresh();

    // Firestore에 데이터를 비동기적으로 저장
    _firestore.collection('users').doc(authController.username.value).update({
      'bibleProgress': bibleProgress.map((book, chapters) => MapEntry(
            book,
            chapters.map((chapter, isRead) => MapEntry(chapter.toString(), isRead)),
          ))
    }).catchError((error) {
      // Firestore 업데이트 중 에러가 발생하면, 상태를 원래대로 되돌림
      bibleProgress[book]![chapter] = !isChecked;
      bibleProgress.refresh();
      Get.snackbar('Error', 'Failed to update progress');
    });
  }

  // 특정 책과 장이 읽혔는지 여부를 반환하는 함수
  bool isChapterRead(String book, int chapter) {
    return bibleProgress[book]?[chapter] ?? false;
  }
}
