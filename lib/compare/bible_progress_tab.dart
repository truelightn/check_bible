import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'compare_controller.dart';

class BibleProgressTab extends StatefulWidget {
  @override
  _BibleProgressTabState createState() => _BibleProgressTabState();
}

class _BibleProgressTabState extends State<BibleProgressTab> {
  final CompareController compareController = Get.put(CompareController());
  bool showNewTestamentOnly = true;
  String selectedGrade = '전체';

  @override
  void initState() {
    super.initState();
    compareController.fetchBibleProgress(
      showNewTestamentOnly: showNewTestamentOnly,
      selectedGrade: selectedGrade,
    );
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
                      compareController.fetchBibleProgress(
                        showNewTestamentOnly: showNewTestamentOnly,
                        selectedGrade: selectedGrade,
                      );
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
              Row(
                children: [
                  const Text(
                    '신약만 보기',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: showNewTestamentOnly,
                    onChanged: (value) {
                      setState(() {
                        showNewTestamentOnly = value;
                      });
                      compareController.fetchBibleProgress(
                        showNewTestamentOnly: showNewTestamentOnly,
                        selectedGrade: selectedGrade,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (compareController.userProgressList.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // 교사 제외한 사용자 목록 필터링
            final filteredUserProgressList = compareController.userProgressList
                .where((user) => user['gradeClass'] != '교사') // '교사'를 제외하는 조건
                .toList();

            return ListView(
              children: [
                _buildTop3(filteredUserProgressList),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '전체 사용자 읽기 현황',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                ...filteredUserProgressList.map((user) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Card(
                      elevation: 3,
                      child: ListTile(
                        title: Text(
                          '${user['username']} (${user['gradeClass']})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8.0),
                            LinearProgressIndicator(
                              value: user['progress'],
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                            ),
                            const SizedBox(height: 4.0),
                            if (!showNewTestamentOnly)
                              Text(
                                '구약: ${user['completedOldTestamentChapters']}장 / 신약: ${user['completedNewTestamentChapters']}장',
                                style: const TextStyle(fontSize: 14, color: Colors.black54),
                              )
                            else
                              Text(
                                '신약: ${user['completedNewTestamentChapters']}장',
                                style: const TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                            Text(
                              '전체 진행도: ${user['completedChapters']}/${compareController.totalBibleChapters}장 (${(user['progress'] * 100).toStringAsFixed(1)}%)',
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildTop3(List<Map<String, dynamic>> userProgressList) {
    List<Map<String, dynamic>> top3 = userProgressList.take(3).toList();

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
                        '${(user['progress'] * 100).toStringAsFixed(1)}%',
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
        return Colors.amber;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  double _getAvatarSize(int index) {
    switch (index) {
      case 0:
        return 50.0;
      case 1:
        return 45.0;
      case 2:
        return 40.0;
      default:
        return 40.0;
    }
  }
}
