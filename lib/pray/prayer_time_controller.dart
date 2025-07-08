// Controller class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PrayerTimeController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxInt prayerHour = 0.obs; // 기도 시간 (시)
  final RxInt prayerMinute = 0.obs; // 기도 시간 (분)
  final RxInt totalPrayerHour = 0.obs; // 누적 기도 시간 (시)
  final RxInt totalPrayerMinute = 0.obs; // 누적 기도 시간 (분)
  final RxInt todayPrayerHour = 0.obs; // 오늘 기도 시간 (시)
  final RxInt todayPrayerMinute = 0.obs; // 오늘 기도 시간 (분)
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  // 학년별 누적 시간
  final RxMap<String, double> gradeAccumulatedMinutes = <String, double>{
    '1학년': 0.0,
    '2학년': 0.0,
    '3학년': 0.0,
    '새친구': 0.0,
    '임원': 0.0,
  }.obs;

  // 학년별 학생 수 (임시 데이터)
  final Map<String, int> gradeStudentCount = {
    '1학년': 10,
    '2학년': 10,
    '3학년': 10,
    '새친구': 5,
    '임원': 5,
  };

  // 목표 기도시간 설정
  final Rx<DateTime> startDate = DateTime(2025, 6, 28).obs;
  final RxInt dailyTargetMinutes = 30.obs; // 하루 목표 기도시간 (분)

  // 목표 기도시간 계산
  double calculateTargetMinutes() {
    final now = DateTime.now();
    final difference = now.difference(startDate.value).inDays;
    return difference * dailyTargetMinutes.value.toDouble();
  }

  // 목표 달성률 계산
  double calculateProgressPercentage() {
    final targetMinutes = calculateTargetMinutes();
    if (targetMinutes <= 0) return 0;
    return ((totalPrayerHour.value * 60 + totalPrayerMinute.value) / targetMinutes * 100).clamp(0, 100);
  }

  // 시작 날짜 변경
  void updateStartDate(DateTime newDate) {
    startDate.value = newDate;
  }

  // 하루 목표 시간 변경
  void updateDailyTarget(int minutes) {
    dailyTargetMinutes.value = minutes;
  }

  // 학년별 목표시간 계산 (분 단위) - 사용자 타입 필터링
  Future<double> calculateGradeTargetMinutesByUserType(String grade, String currentUserType) async {
    final int daysPassed = DateTime.now().difference(startDate.value).inDays;

    // 해당 학년의 학생 수 계산 (사용자 타입에 따라 필터링)
    int studentCount = 0;

    List<String> collectionsToCheck = currentUserType == '학생' ? ['students'] : ['students', 'teachers'];

    for (String collection in collectionsToCheck) {
      QuerySnapshot usersSnapshot = await _firestore.collection(collection).get();

      for (var userDoc in usersSnapshot.docs) {
        String gradeClass = (userDoc.data() as Map<String, dynamic>)['gradeClass'] ?? '';

        if (grade == '1학년' && gradeClass.startsWith('1')) {
          studentCount++;
        } else if (grade == '2학년' && gradeClass.startsWith('2')) {
          studentCount++;
        } else if (grade == '3학년' && gradeClass.startsWith('3')) {
          studentCount++;
        } else if (grade == '새친구' && gradeClass == '새친구') {
          studentCount++;
        } else if (grade == '임원' && gradeClass == '임원') {
          studentCount++;
        }
      }
    }

    return studentCount * 30.0 * (daysPassed + 1); // 하루 30분 * 실제 인원수 * 경과일수
  }

  // 학년별 누적 시간 계산 - 사용자 타입 필터링
  Future<Map<String, double>> calculateGradeAccumulatedTimesByUserType(String currentUserType) async {
    Map<String, double> accumulatedMinutes = {
      '1학년': 0.0,
      '2학년': 0.0,
      '3학년': 0.0,
      '새친구': 0.0,
      '임원': 0.0,
    };

    // 사용자 타입에 따라 확인할 컬렉션 결정
    List<String> collectionsToCheck = currentUserType == '학생' ? ['students'] : ['students', 'teachers'];

    for (String collection in collectionsToCheck) {
      QuerySnapshot usersSnapshot = await _firestore.collection(collection).get();

      for (var userDoc in usersSnapshot.docs) {
        String gradeClass = (userDoc.data() as Map<String, dynamic>)['gradeClass'] ?? '';
        String grade = '';

        if (gradeClass.startsWith('1')) {
          grade = '1학년';
        } else if (gradeClass.startsWith('2')) {
          grade = '2학년';
        } else if (gradeClass.startsWith('3')) {
          grade = '3학년';
        } else if (gradeClass == '새친구') {
          grade = '새친구';
        } else if (gradeClass == '임원') {
          grade = '임원';
        } else {
          continue;
        }

        // 각 사용자의 기도 시간을 가져옴
        QuerySnapshot prayerTimesSnapshot = await _firestore.collection(collection).doc(userDoc.id).collection('prayer_times').where('date', isGreaterThanOrEqualTo: startDate.value).get();

        for (var prayerDoc in prayerTimesSnapshot.docs) {
          Map<String, dynamic> data = prayerDoc.data() as Map<String, dynamic>;
          double minutes = (data['hour'] ?? 0) * 60 + (data['minute'] ?? 0);
          accumulatedMinutes[grade] = (accumulatedMinutes[grade] ?? 0) + minutes;
        }
      }
    }

    return accumulatedMinutes;
  }

  // 학년별 목표시간 계산 (분 단위)
  Future<double> calculateGradeTargetMinutes(String grade) async {
    final int daysPassed = DateTime.now().difference(startDate.value).inDays;

    // 해당 학년의 학생 수 계산 (학생과 교사 컬렉션 모두 확인)
    int studentCount = 0;
    
    for (String collection in ['students', 'teachers']) {
      QuerySnapshot usersSnapshot = await _firestore.collection(collection).get();

      for (var userDoc in usersSnapshot.docs) {
        String gradeClass = (userDoc.data() as Map<String, dynamic>)['gradeClass'] ?? '';

        if (grade == '1학년' && gradeClass.startsWith('1')) {
          studentCount++;
        } else if (grade == '2학년' && gradeClass.startsWith('2')) {
          studentCount++;
        } else if (grade == '3학년' && gradeClass.startsWith('3')) {
          studentCount++;
        } else if (grade == '새친구' && gradeClass == '새친구') {
          studentCount++;
        } else if (grade == '임원' && gradeClass == '임원') {
          studentCount++;
        }
      }
    }

    return studentCount * 30.0 * (daysPassed + 1); // 하루 30분 * 실제 인원수 * 경과일수
  }

  // 학년별 누적 시간 계산
  Future<void> calculateGradeAccumulatedTimes() async {
    Map<String, double> accumulatedMinutes = {
      '1학년': 0.0,
      '2학년': 0.0,
      '3학년': 0.0,
      '새친구': 0.0,
      '임원': 0.0,
    };

    // 모든 사용자의 기도 시간을 가져옴 (학생과 교사 컬렉션 모두 확인)
    for (String collection in ['students', 'teachers']) {
      QuerySnapshot usersSnapshot = await _firestore.collection(collection).get();

      for (var userDoc in usersSnapshot.docs) {
        String gradeClass = (userDoc.data() as Map<String, dynamic>)['gradeClass'] ?? '';
        String grade = '';

        if (gradeClass.startsWith('1')) {
          grade = '1학년';
        } else if (gradeClass.startsWith('2')) {
          grade = '2학년';
        } else if (gradeClass.startsWith('3')) {
          grade = '3학년';
        } else if (gradeClass == '새친구') {
          grade = '새친구';
        } else if (gradeClass == '임원') {
          grade = '임원';
        } else {
          continue;
        }

        // 각 사용자의 기도 시간을 가져옴
        QuerySnapshot prayerTimesSnapshot = await _firestore.collection(collection).doc(userDoc.id).collection('prayer_times').where('date', isGreaterThanOrEqualTo: startDate.value).get();

        for (var prayerDoc in prayerTimesSnapshot.docs) {
          Map<String, dynamic> data = prayerDoc.data() as Map<String, dynamic>;
          double minutes = (data['hour'] ?? 0) * 60 + (data['minute'] ?? 0);
          accumulatedMinutes[grade] = (accumulatedMinutes[grade] ?? 0) + minutes;
        }
      }
    }

    gradeAccumulatedMinutes.value = accumulatedMinutes;
  }

  // 시, 분을 업데이트하는 함수
  void updatePrayerTime(int hour, int minute, DateTime date) {
    prayerHour.value = hour;
    prayerMinute.value = minute;
    selectedDate.value = date;
  }

  // 기도 시간을 Firestore에 저장하는 함수 (기존 기도 시간에 추가)
  Future<void> savePrayerTime(String username, String userType) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    String collection = userType == '학생' ? 'students' : 'teachers';

    // 기존의 기도 시간을 불러와서 더하기
    DocumentSnapshot doc = await _firestore.collection(collection).doc(username).collection('prayer_times').doc(formattedDate).get();

    int existingHour = 0;
    int existingMinute = 0;

    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      existingHour = data['hour'] ?? 0;
      existingMinute = data['minute'] ?? 0;
    }

    // 새로운 기도 시간을 기존 기도 시간에 더함
    int totalHour = existingHour + prayerHour.value;
    int totalMinute = existingMinute + prayerMinute.value;

    if (totalMinute >= 60) {
      totalHour += totalMinute ~/ 60;
      totalMinute = totalMinute % 60;
    }

    // Firestore에 새로운 합산된 시간 저장
    await _firestore.collection(collection).doc(username).collection('prayer_times').doc(formattedDate).set({
      'date': selectedDate.value,
      'hour': totalHour,
      'minute': totalMinute,
    }, SetOptions(merge: true));

    Get.snackbar('Success', "기도시간 저장 완료!");
  }

  // 누적 기도 시간과 오늘의 기도 시간을 계산하는 함수
  Future<void> calculateTotalPrayerTimes(String username, String userType) async {
    String collection = userType == '학생' ? 'students' : 'teachers';
    QuerySnapshot querySnapshot = await _firestore.collection(collection).doc(username).collection('prayer_times').get();

    int totalHour = 0;
    int totalMinute = 0;
    int todayHour = 0;
    int todayMinute = 0;

    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      int hour = data['hour'] ?? 0;
      int minute = data['minute'] ?? 0;

      // 전체 누적 기도 시간 계산
      totalHour += hour;
      totalMinute += minute;

      // 오늘의 기도 시간 계산
      String docDate = DateFormat('yyyy-MM-dd').format((data['date'] as Timestamp).toDate());
      if (docDate == todayDate) {
        todayHour = hour;
        todayMinute = minute;
      }
    }

    // 분이 60을 넘으면 시간으로 전환
    totalHour += totalMinute ~/ 60;
    totalMinute = totalMinute % 60;

    todayHour += todayMinute ~/ 60;
    todayMinute = todayMinute % 60;

    // 상태 업데이트
    totalPrayerHour.value = totalHour;
    totalPrayerMinute.value = totalMinute;

    todayPrayerHour.value = todayHour;
    todayPrayerMinute.value = todayMinute;
  }

  // 기도 시간을 가져오는 함수
  Stream<QuerySnapshot> getPrayerTimes(String username, String userType) {
    String collection = userType == '학생' ? 'students' : 'teachers';
    return _firestore
        .collection(collection)
        .doc(username)
        .collection('prayer_times')
        .orderBy('date', descending: true) // 날짜별로 정렬
        .snapshots();
  }

  // Firestore에서 기도 시간 데이터를 삭제하는 함수 (선택한 날짜)
  Future<void> deletePrayerTime(String username, String userType, String docId) async {
    String collection = userType == '학생' ? 'students' : 'teachers';
    await _firestore.collection(collection).doc(username).collection('prayer_times').doc(docId).delete();

    Get.snackbar('Success', "기도시간 삭제 완료!");
  }

  // 학년별 학생 기도시간 조회 (학생과 교사 구분)
  Future<List<Map<String, dynamic>>> getStudentsByGradeAndType(String grade, String currentUserType) async {
    List<Map<String, dynamic>> students = [];

    // 현재 로그인한 사용자 타입이 학생이면 학생만, 교사면 모두 보여줌
    List<String> collectionsToCheck = currentUserType == '학생' ? ['students'] : ['students', 'teachers'];

    for (String collection in collectionsToCheck) {
      QuerySnapshot usersSnapshot = await _firestore.collection(collection).get();

      for (var userDoc in usersSnapshot.docs) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String gradeClass = userData['gradeClass'] ?? '';
        String userType = userData['userType'] ?? '';

        // 학년 필터링
        bool isMatchingGrade = false;
        if (grade == '1학년' && gradeClass.startsWith('1')) {
          isMatchingGrade = true;
        } else if (grade == '2학년' && gradeClass.startsWith('2')) {
          isMatchingGrade = true;
        } else if (grade == '3학년' && gradeClass.startsWith('3')) {
          isMatchingGrade = true;
        } else if (grade == '새친구' && gradeClass == '새친구') {
          isMatchingGrade = true;
        } else if (grade == '임원' && gradeClass == '임원') {
          isMatchingGrade = true;
        }

        if (!isMatchingGrade) continue;

        // 학생의 기도 시간 합계 계산
        QuerySnapshot prayerTimesSnapshot = await _firestore.collection(collection).doc(userDoc.id).collection('prayer_times').get();

        int totalMinutes = 0;
        for (var prayerDoc in prayerTimesSnapshot.docs) {
          Map<String, dynamic> data = prayerDoc.data() as Map<String, dynamic>;
          totalMinutes += ((data['hour'] ?? 0) as num).toInt() * 60 + ((data['minute'] ?? 0) as num).toInt();
        }

        // 목표 시간 대비 진행률 계산
        double targetMinutes = await calculateGradeTargetMinutes(grade);
        double progressPercentage = (totalMinutes / targetMinutes).clamp(0.0, 1.0);

        students.add({
          'name': userData['name'] ?? '이름 없음',
          'hours': totalMinutes ~/ 60,
          'minutes': totalMinutes % 60,
          'progressPercentage': progressPercentage,
          'userType': userType,
        });
      }
    }

    // 기도시간 내림차순 정렬
    students.sort((a, b) => (b['hours'] * 60 + b['minutes']).compareTo(a['hours'] * 60 + a['minutes']));

    return students;
  }

  // 학년별 학생 기도시간 조회 (기존 메서드)
  Future<List<Map<String, dynamic>>> getStudentsByGrade(String grade) async {
    List<Map<String, dynamic>> students = [];

    // 학생과 교사 컬렉션 모두 확인
    for (String collection in ['students', 'teachers']) {
      QuerySnapshot usersSnapshot = await _firestore.collection(collection).get();

      for (var userDoc in usersSnapshot.docs) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String gradeClass = userData['gradeClass'] ?? '';

        if (!gradeClass.startsWith(grade[0])) continue; // 해당 학년이 아니면 스킵

        // 학생의 기도 시간 합계 계산
        QuerySnapshot prayerTimesSnapshot = await _firestore.collection(collection).doc(userDoc.id).collection('prayer_times').get();

        int totalMinutes = 0;
        for (var prayerDoc in prayerTimesSnapshot.docs) {
          Map<String, dynamic> data = prayerDoc.data() as Map<String, dynamic>;
          totalMinutes += ((data['hour'] ?? 0) as num).toInt() * 60 + ((data['minute'] ?? 0) as num).toInt();
        }

        // 목표 시간 대비 진행률 계산
        double targetMinutes = await calculateGradeTargetMinutes(grade);
        double progressPercentage = (totalMinutes / targetMinutes).clamp(0.0, 1.0);

        students.add({
          'name': userData['name'] ?? '이름 없음',
          'hours': totalMinutes ~/ 60,
          'minutes': totalMinutes % 60,
          'progressPercentage': progressPercentage,
        });
      }
    }

    // 기도시간 내림차순 정렬
    students.sort((a, b) => (b['hours'] * 60 + b['minutes']).compareTo(a['hours'] * 60 + a['minutes']));

    return students;
  }

  // 특정 사용자 타입만 필터링하여 학년별 기도시간 조회
  Future<List<Map<String, dynamic>>> getStudentsByGradeAndSpecificType(String grade, String specificUserType) async {
    List<Map<String, dynamic>> students = [];

    // 특정 사용자 타입의 컬렉션만 확인
    String collection = specificUserType == '학생' ? 'students' : 'teachers';

    QuerySnapshot usersSnapshot = await _firestore.collection(collection).get();

    for (var userDoc in usersSnapshot.docs) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String gradeClass = userData['gradeClass'] ?? '';
      String userType = userData['userType'] ?? '';

      // 학년 필터링
      bool isMatchingGrade = false;
      if (grade == '1학년' && gradeClass.startsWith('1')) {
        isMatchingGrade = true;
      } else if (grade == '2학년' && gradeClass.startsWith('2')) {
        isMatchingGrade = true;
      } else if (grade == '3학년' && gradeClass.startsWith('3')) {
        isMatchingGrade = true;
      } else if (grade == '새친구' && gradeClass == '새친구') {
        isMatchingGrade = true;
      } else if (grade == '임원' && gradeClass == '임원') {
        isMatchingGrade = true;
      }

      if (!isMatchingGrade) continue;

      // 학생의 기도 시간 합계 계산
      QuerySnapshot prayerTimesSnapshot = await _firestore.collection(collection).doc(userDoc.id).collection('prayer_times').get();

      int totalMinutes = 0;
      for (var prayerDoc in prayerTimesSnapshot.docs) {
        Map<String, dynamic> data = prayerDoc.data() as Map<String, dynamic>;
        totalMinutes += ((data['hour'] ?? 0) as num).toInt() * 60 + ((data['minute'] ?? 0) as num).toInt();
      }

      // 목표 시간 대비 진행률 계산
      double targetMinutes = await calculateGradeTargetMinutesByUserType(grade, specificUserType);
      double progressPercentage = (totalMinutes / targetMinutes).clamp(0.0, 1.0);

      students.add({
        'name': userData['name'] ?? '이름 없음',
        'hours': totalMinutes ~/ 60,
        'minutes': totalMinutes % 60,
        'progressPercentage': progressPercentage,
        'userType': userType,
      });
    }

    // 기도시간 내림차순 정렬
    students.sort((a, b) => (b['hours'] * 60 + b['minutes']).compareTo(a['hours'] * 60 + a['minutes']));

    return students;
  }
}
