import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:check_bible/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'prayer_time_controller.dart';
import 'package:intl/intl.dart'; // 날짜 포맷을 위해 사용
import 'package:check_bible/compare/compare_progress_screen.dart'; // 새로운 import 추가
import 'package:fl_chart/fl_chart.dart';
import 'package:check_bible/compare/compare_controller.dart';

class PrayerTimeInputScreen extends StatefulWidget {
  @override
  _PrayerTimeInputScreenState createState() => _PrayerTimeInputScreenState();
}

class _PrayerTimeInputScreenState extends State<PrayerTimeInputScreen> {
  final PrayerTimeController prayerTimeController = Get.put(PrayerTimeController());
  final AuthController authController = Get.find(); // 사용자 정보 접근
  final CompareController compareController = Get.put(CompareController());

  Duration selectedDuration = Duration(hours: 0, minutes: 0);
  DateTime selectedDate = DateTime.now(); // 선택된 날짜 추가
  double maxY = 0; // 추가된 클래스 필드

  @override
  void initState() {
    super.initState();
    // Firestore에서 누적 기도 시간을 계산하고 초기화
    prayerTimeController.calculateTotalPrayerTimes(authController.username.value);
    compareController.fetchPrayerTimes(); // 학년별 기도시간 데이터 가져오기
  }

  // 학년별 평균 기도시간을 계산하는 함수
  Map<String, double> calculateAverageByGrade() {
    Map<String, List<double>> gradeMinutes = {
      '1학년': [],
      '2학년': [],
      '3학년': [],
    };

    for (var user in compareController.prayerRankingList) {
      if (user['gradeClass'].toString().startsWith('1')) {
        gradeMinutes['1학년']!.add(user['totalPrayerHours'] * 60 + user['totalPrayerMinutes']);
      } else if (user['gradeClass'].toString().startsWith('2')) {
        gradeMinutes['2학년']!.add(user['totalPrayerHours'] * 60 + user['totalPrayerMinutes']);
      } else if (user['gradeClass'].toString().startsWith('3')) {
        gradeMinutes['3학년']!.add(user['totalPrayerHours'] * 60 + user['totalPrayerMinutes']);
      }
    }

    Map<String, double> averages = {};
    gradeMinutes.forEach((grade, minutes) {
      if (minutes.isNotEmpty) {
        averages[grade] = minutes.reduce((a, b) => a + b) / minutes.length;
      } else {
        averages[grade] = 0;
      }
    });

    return averages;
  }

  Widget _buildGradeChart() {
    return Obx(() {
      if (compareController.prayerRankingList.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      Map<String, double> averages = calculateAverageByGrade();
      maxY = averages.values.reduce((curr, next) => curr > next ? curr : next);

      return Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY + 30,
            minY: 0,
            barGroups: [
              _createBarGroup(0, averages['1학년']!, [Color(0xFF2196F3), Color(0xFF64B5F6)]),
              _createBarGroup(1, averages['2학년']!, [Color(0xFF4CAF50), Color(0xFF81C784)]),
              _createBarGroup(2, averages['3학년']!, [Color(0xFFF44336), Color(0xFFE57373)]),
            ],
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 60,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[300],
                  strokeWidth: 1,
                  dashArray: [5, 5],
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32, // 하단 여백 증가
                  getTitlesWidget: (value, meta) {
                    String text = ['1학년', '2학년', '3학년'][value.toInt()];
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 60,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${(value / 60).floor()}시간',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                left: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
                tooltipRoundedRadius: 8,
                tooltipPadding: const EdgeInsets.all(12),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  String grade = ['1학년', '2학년', '3학년'][groupIndex];
                  int hours = (rod.toY / 60).floor();
                  int minutes = (rod.toY % 60).round();
                  return BarTooltipItem(
                    '$grade\n$hours시간 $minutes분',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  );
                },
              ),
            ),
            groupsSpace: 32, // 막대 사이 간격 조정
            baselineY: 0,
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: 0,
                  color: Colors.grey[300],
                  strokeWidth: 1,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  BarChartGroupData _createBarGroup(int x, double value, List<Color> colors) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          width: 20, // 막대 너비 약간 감소
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY + 30,
            color: Colors.grey[200],
          ),
        ),
      ],
    );
  }

  // 날짜 선택 다이얼로그를 보여주는 함수
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _savePrayerTime() async {
    int hour = selectedDuration.inHours;
    int minute = selectedDuration.inMinutes % 60;

    // 입력된 시간을 PrayerTimeController에 업데이트 (선택된 날짜 포함)
    prayerTimeController.updatePrayerTime(hour, minute, selectedDate);

    // Firestore에 저장 후 누적 시간 다시 계산
    await prayerTimeController.savePrayerTime(authController.username.value);

    // Firestore에서 누적 시간을 다시 계산하여 업데이트
    prayerTimeController.calculateTotalPrayerTimes(authController.username.value);

    Get.back();
  }

  Widget _buildTimeSelectButton(Duration duration) {
    bool isSelected = selectedDuration == duration;
    return InkWell(
      onTap: () {
        setState(() {
          selectedDuration = duration;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          duration.inMinutes == 0
              ? '0분'
              : '${duration.inHours > 0 ? '${duration.inHours}시간 ' : ''}'
                  '${duration.inMinutes % 60 > 0 ? '${duration.inMinutes % 60}분' : ''}',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMyPrayerTimeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '나의 기도시간',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() => Row(
                  children: [
                    Expanded(
                      child: _buildTimeInfoBox(
                        '누적 기도시간',
                        '${prayerTimeController.totalPrayerHour.value}시간 '
                            '${prayerTimeController.totalPrayerMinute.value}분',
                        Colors.blue,
                        Icons.access_time,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimeInfoBox(
                        '오늘의 기도시간',
                        '${prayerTimeController.todayPrayerHour.value}시간 '
                            '${prayerTimeController.todayPrayerMinute.value}분',
                        Colors.green,
                        Icons.today,
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfoBox(String title, String time, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기도시간 입력'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '학년별 평균 기도시간',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildGradeChart(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildMyPrayerTimeCard(),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '기도 날짜 및 시간 입력',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: Colors.blue),
                                    const SizedBox(width: 12),
                                    Text(
                                      DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(selectedDate),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _savePrayerTime,
                            icon: const Icon(Icons.save),
                            label: const Text('저장'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 30분 단위 시간 선택 버튼들
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (int i = 0; i <= 8; i++) _buildTimeSelectButton(Duration(minutes: i * 30)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const PrayerTimeListWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 기도 시간을 Firestore에서 불러와 표시하는 리스트 위젯
class PrayerTimeListWidget extends StatelessWidget {
  const PrayerTimeListWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find();
    final PrayerTimeController prayerTimeController = Get.find();

    return StreamBuilder<QuerySnapshot>(
      stream: prayerTimeController.getPrayerTimes(authController.username.value), // 기도 시간 데이터를 가져오는 스트림
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // 로딩 중 표시
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('저장된 기도 시간이 없습니다.'); // 데이터가 없을 때
        }

        // Firestore에서 가져온 기도 시간 데이터를 리스트로 표시
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            var date = (data['date'] as Timestamp).toDate();
            var hour = data['hour'];
            var minute = data['minute'];

            return ListTile(
              title: Text(
                '${DateFormat('yyyy-MM-dd').format(date)}: $hour시간 $minute분',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  // 기도 시간 삭제
                  prayerTimeController.deletePrayerTime(authController.username.value, doc.id);
                },
              ),
            );
          },
        );
      },
    );
  }
}
