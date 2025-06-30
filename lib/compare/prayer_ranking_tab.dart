import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'compare_controller.dart';

class PrayerRankingTab extends StatefulWidget {
  @override
  _PrayerRankingTabState createState() => _PrayerRankingTabState();
}

class _PrayerRankingTabState extends State<PrayerRankingTab> {
  final CompareController compareController = Get.put(CompareController());
  String selectedGrade = '전체'; // 학년 선택을 위한 필드

  @override
  void initState() {
    super.initState();
    compareController.fetchPrayerTimes(); // 처음에 모든 기도 랭킹 데이터를 불러옴
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    '학년별 보기: ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: selectedGrade,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedGrade = newValue!;
                      });
                      compareController.fetchPrayerTimes(); // 데이터를 다시 가져옴
                    },
                    items: <String>['전체', '1학년', '2학년', '3학년'].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (compareController.prayerRankingList.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // 'gradeClass'가 '교사'인 경우를 제외하고, 학년 필터링을 적용
            List<Map<String, dynamic>> filteredList = selectedGrade == '전체'
                ? compareController.prayerRankingList.where((user) => user['gradeClass'] != '교사').toList()
                : compareController.prayerRankingList.where((user) {
                    return user['gradeClass'] != '교사' && user['gradeClass']!.toString().startsWith(selectedGrade);
                  }).toList();

            return ListView(
              children: [
                _buildTop3(filteredList), // 상위 3명 표시
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '기도 시간 랭킹',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                ...filteredList.map((user) {
                  return ListTile(
                    title: Text(
                      '${user['username']} (${user['gradeClass']})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '기도 시간: ${user['totalPrayerHours']}시간 ${user['totalPrayerMinutes']}분',
                      style: const TextStyle(fontSize: 16),
                    ),
                    leading: CircleAvatar(
                      child: Text('#${filteredList.indexOf(user) + 1}'),
                    ),
                  );
                }).toList(),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTop3(List<Map<String, dynamic>> prayerRankingList) {
    List<Map<String, dynamic>> top3 = prayerRankingList.take(3).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '상위 3인',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: top3.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> user = entry.value;
              String medalType = _getMedalType(index);
              Color medalColor = _getMedalColor(index);
              double avatarSize = _getAvatarSize(index);

              return Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: avatarSize,
                        backgroundColor: medalColor,
                      ),
                      Text(
                        '${user['totalPrayerHours']}시간 ${user['totalPrayerMinutes']}분',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    user['username'],
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    medalType,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: medalColor,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getMedalType(int index) {
    switch (index) {
      case 0:
        return '1등';
      case 1:
        return '2등';
      case 2:
        return '3등';
      default:
        return '';
    }
  }

  Color _getMedalColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber; // 1등 금색
      case 1:
        return Colors.grey; // 2등 은색
      case 2:
        return Colors.brown; // 3등 동색
      default:
        return Colors.grey;
    }
  }

  double _getAvatarSize(int index) {
    switch (index) {
      case 0:
        return 50.0; // 1등 더 큰 아이콘
      case 1:
        return 45.0; // 2등
      case 2:
        return 40.0; // 3등
      default:
        return 40.0;
    }
  }
}
