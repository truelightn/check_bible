import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompareController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var userProgressList = <Map<String, dynamic>>[].obs;
  var prayerRankingList = <Map<String, dynamic>>[].obs;

  final int totalBibleChapters = 1189;
  final int newTestamentChapters = 260;

  // 성경 읽기 진행 데이터를 불러오는 함수
  Future<void> fetchBibleProgress({required bool showNewTestamentOnly, required String selectedGrade}) async {
    try {
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      List<Map<String, dynamic>> tempUserProgressList = [];

      for (var userDoc in usersSnapshot.docs) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;

        if (data != null) {
          String username = data['username']?.toString() ?? 'Unknown';
          String gradeClass = data['gradeClass']?.toString() ?? '학년/반 미정';
          Map<String, dynamic> bibleProgress = data['bibleProgress'] ?? {};

          int completedChapters = 0;
          int completedOldTestamentChapters = 0;
          int completedNewTestamentChapters = 0;

          bibleProgress.forEach((book, chapters) {
            Map chaptersMap = chapters as Map;
            int bookChaptersCompleted = chaptersMap.values.where((isRead) => isRead == true).length;
            completedChapters += bookChaptersCompleted;

            if (_isOldTestament(book)) {
              completedOldTestamentChapters += bookChaptersCompleted;
            } else {
              completedNewTestamentChapters += bookChaptersCompleted;
            }
          });

          double progress = showNewTestamentOnly ? (completedNewTestamentChapters / newTestamentChapters) : (completedChapters / totalBibleChapters);

          // 학년 필터링 조건에 맞는 사용자만 추가
          if (selectedGrade == '전체' || gradeClass.startsWith(selectedGrade)) {
            tempUserProgressList.add({
              'username': username,
              'gradeClass': gradeClass,
              'progress': progress,
              'completedChapters': completedChapters,
              'completedOldTestamentChapters': completedOldTestamentChapters,
              'completedNewTestamentChapters': completedNewTestamentChapters,
            });
          }
        }
      }

      // 진행 퍼센트로 내림차순 정렬
      tempUserProgressList.sort((a, b) => b['progress'].compareTo(a['progress']));
      userProgressList.value = tempUserProgressList;
    } catch (e) {
      print('Error fetching Bible progress: $e');
    }
  }

  // 구약과 신약을 구분하는 함수
  bool _isOldTestament(String book) {
    const oldTestamentBooks = {
      '창세기',
      '출애굽기',
      '레위기',
      '민수기',
      '신명기',
      '여호수아',
      '사사기',
      '룻기',
      '사무엘상',
      '사무엘하',
      '열왕기상',
      '열왕기하',
      '역대상',
      '역대하',
      '에스라',
      '느헤미야',
      '에스더',
      '욥기',
      '시편',
      '잠언',
      '전도서',
      '아가',
      '이사야',
      '예레미야',
      '예레미야애가',
      '에스겔',
      '다니엘',
      '호세아',
      '요엘',
      '아모스',
      '오바댜',
      '요나',
      '미가',
      '나훔',
      '하박국',
      '스바냐',
      '학개',
      '스가랴',
      '말라기'
    };
    return oldTestamentBooks.contains(book);
  }

  Future<void> fetchPrayerTimes() async {
    try {
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      List<Future<Map<String, dynamic>>> rankingFutures = [];

      for (var userDoc in usersSnapshot.docs) {
        rankingFutures.add(_fetchPrayerTimesForUser(userDoc));
      }

      // 모든 사용자에 대해 병렬로 기도 시간을 불러옴
      List<Map<String, dynamic>> tempRankingList = await Future.wait(rankingFutures);

      // 기도 시간을 기준으로 내림차순 정렬
      tempRankingList.sort((a, b) {
        int aTotalMinutes = a['totalPrayerHours'] * 60 + a['totalPrayerMinutes'];
        int bTotalMinutes = b['totalPrayerHours'] * 60 + b['totalPrayerMinutes'];
        return bTotalMinutes.compareTo(aTotalMinutes);
      });

      prayerRankingList.value = tempRankingList;
    } catch (e) {
      print('Error fetching prayer times: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchPrayerTimesForUser(DocumentSnapshot userDoc) async {
    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

    if (userData != null) {
      String username = userData['username']?.toString() ?? 'Unknown';
      String gradeClass = userData['gradeClass']?.toString() ?? '학년/반 미정';

      // 사용자별 prayer_times 서브컬렉션의 각 날짜별 문서를 가져오기
      QuerySnapshot prayerTimesSnapshot = await _firestore.collection('users').doc(userDoc.id).collection('prayer_times').get();

      int totalPrayerHours = 0;
      int totalPrayerMinutes = 0;

      // 날짜별 기도 시간을 불러오고 합산
      for (var prayerDoc in prayerTimesSnapshot.docs) {
        Map<String, dynamic>? prayerData = prayerDoc.data() as Map<String, dynamic>?;

        if (prayerData != null) {
          int hour = (prayerData['hour'] ?? 0).toInt();
          int minute = (prayerData['minute'] ?? 0).toInt();

          totalPrayerHours += hour;
          totalPrayerMinutes += minute;
        }
      }

      // 분을 시간으로 변환
      totalPrayerHours += totalPrayerMinutes ~/ 60;
      totalPrayerMinutes = totalPrayerMinutes % 60;

      return {
        'username': username,
        'gradeClass': gradeClass,
        'totalPrayerHours': totalPrayerHours,
        'totalPrayerMinutes': totalPrayerMinutes,
      };
    } else {
      return {};
    }
  }
}
