import 'package:check_bible/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // 날짜 포맷을 위해 사용

import 'grade_prayer_detail_screen.dart';
import 'prayer_time_controller.dart';

class PrayerTimeInputScreen extends StatefulWidget {
  @override
  _PrayerTimeInputScreenState createState() => _PrayerTimeInputScreenState();
}

class _PrayerTimeInputScreenState extends State<PrayerTimeInputScreen> {
  final PrayerTimeController prayerTimeController = Get.put(PrayerTimeController());
  final AuthController authController = Get.find(); // 사용자 정보 접근

  Duration selectedDuration = Duration(hours: 0, minutes: 0);
  DateTime selectedDate = DateTime.now(); // 선택된 날짜 추가
  double maxY = 0; // 추가된 클래스 필드

  @override
  void initState() {
    super.initState();
    // Firestore에서 누적 기도 시간을 계산하고 초기화
    prayerTimeController.calculateTotalPrayerTimes(authController.username.value);
    prayerTimeController.calculateGradeAccumulatedTimes(); // 학년별 누적시간 계산 추가
  }

  // 학년별 누적 기도시간을 계산하는 함수
  Map<String, double> calculateTotalByGrade() {
    return prayerTimeController.gradeAccumulatedMinutes;
  }

  Widget _buildGradeChart() {
    return Obx(() {
      if (prayerTimeController.gradeAccumulatedMinutes.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      Map<String, double> totals = calculateTotalByGrade();
      
      return FutureBuilder<Map<String, double>>(
        future: Future.wait([
          prayerTimeController.calculateGradeTargetMinutes('1학년'),
          prayerTimeController.calculateGradeTargetMinutes('2학년'),
          prayerTimeController.calculateGradeTargetMinutes('3학년'),
          prayerTimeController.calculateGradeTargetMinutes('새친구'),
          prayerTimeController.calculateGradeTargetMinutes('임원'),
        ]).then((values) => {
              '1학년': values[0],
              '2학년': values[1],
              '3학년': values[2],
              '새친구': values[3],
              '임원': values[4],
            }),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          Map<String, double> targets = snapshot.data!;
          maxY = [...totals.values, ...targets.values].reduce((curr, next) => curr > next ? curr : next);

          // Y축 간격 계산 (최대값을 10개의 구간으로 나눔)
          double interval = (maxY / 10).roundToDouble();
          // 간격을 60분 단위로 올림
          if (interval % 60 != 0) {
            interval = ((interval / 60).ceil() * 60).toDouble();
          }
          maxY = interval * 10; // maxY를 간격의 10배로 조정

          return Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY + interval,
                minY: 0,
                barGroups: [
                  _createBarGroupWithTarget(0, totals['1학년']!, targets['1학년']!, [Color(0xFF2196F3), Color(0xFF64B5F6)]),
                  _createBarGroupWithTarget(1, totals['2학년']!, targets['2학년']!, [Color(0xFF4CAF50), Color(0xFF81C784)]),
                  _createBarGroupWithTarget(2, totals['3학년']!, targets['3학년']!, [Color(0xFFF44336), Color(0xFFE57373)]),
                  _createBarGroupWithTarget(3, totals['새친구']!, targets['새친구']!, [Color(0xFF9C27B0), Color(0xFFBA68C8)]),
                  _createBarGroupWithTarget(4, totals['임원']!, targets['임원']!, [Color(0xFFFF9800), Color(0xFFFFB74D)]),
                ],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
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
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        String text = ['1학년', '2학년', '3학년', '새친구', '임원'][value.toInt()];
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
                      reservedSize: 50,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        return value == 0
                            ? const Text('0')
                            : Text(
                                '${(value / 60).floor()}시간',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 11,
                                ),
                              );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(12),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String grade = ['1학년', '2학년', '3학년', '새친구', '임원'][groupIndex];
                      String label = rodIndex == 0 ? '누적' : '목표';
                      int hours = (rod.toY / 60).floor();
                      int minutes = (rod.toY % 60).round();
                      return BarTooltipItem(
                        '$grade $label\n$hours시간 $minutes분',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  BarChartGroupData _createBarGroupWithTarget(int x, double value, double target, List<Color> colors) {
    return BarChartGroupData(
      x: x,
      groupVertically: false,
      barRods: [
        BarChartRodData(
          toY: value,
          width: 16,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        BarChartRodData(
          toY: target,
          width: 16,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
          gradient: LinearGradient(
            colors: [Colors.grey[400]!, Colors.grey[300]!],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
      ],
      barsSpace: 4,
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
    await prayerTimeController.calculateTotalPrayerTimes(authController.username.value);
    await prayerTimeController.calculateGradeAccumulatedTimes(); // 학년별 누적시간 다시 계산

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Obx(() => Text(
                          '${authController.username.value}님의 기도시간',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                  ],
                ),
                // IconButton(
                //   onPressed: _showTargetSettingDialog,
                //   icon: const Icon(Icons.settings),
                //   tooltip: '목표 설정',
                // ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              final targetMinutes = prayerTimeController.calculateTargetMinutes();
              final targetHours = (targetMinutes / 60).floor();
              final targetMins = (targetMinutes % 60).round();
              final progressPercentage = prayerTimeController.calculateProgressPercentage();

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeInfoBox(
                          '목표 기도시간',
                          '$targetHours시간 $targetMins분',
                          Colors.orange,
                          Icons.flag,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimeInfoBox(
                          '누적 기도시간',
                          '${prayerTimeController.totalPrayerHour.value}시간 '
                              '${prayerTimeController.totalPrayerMinute.value}분',
                          Colors.blue,
                          Icons.access_time,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeInfoBox(
                          '오늘의 기도시간',
                          '${prayerTimeController.todayPrayerHour.value}시간 '
                              '${prayerTimeController.todayPrayerMinute.value}분',
                          Colors.green,
                          Icons.today,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimeInfoBox(
                          '달성률',
                          '${progressPercentage.toStringAsFixed(1)}%',
                          progressPercentage >= 100
                              ? Colors.green
                              : progressPercentage < 30
                                  ? Colors.red
                                  : Colors.blue,
                          Icons.pie_chart,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progressPercentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressPercentage >= 100
                          ? Colors.green
                          : progressPercentage < 30
                              ? Colors.red
                              : Colors.blue,
                    ),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showTargetSettingDialog() {
    final startDate = prayerTimeController.startDate.value;
    final dailyTarget = prayerTimeController.dailyTargetMinutes.value;

    Get.dialog(
      AlertDialog(
        title: const Text('목표 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('시작 날짜'),
              subtitle: Text(DateFormat('yyyy년 MM월 dd일').format(startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: Get.context!,
                  initialDate: startDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2026),
                );
                if (picked != null) {
                  prayerTimeController.updateStartDate(picked);
                  Get.back();
                  _showTargetSettingDialog(); // 다이얼로그 새로고침
                }
              },
            ),
            ListTile(
              title: const Text('하루 목표'),
              subtitle: Text('$dailyTarget분'),
              trailing: const Icon(Icons.timer),
              onTap: () {
                Get.back();
                _showDailyTargetDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showDailyTargetDialog() {
    final controller = TextEditingController(
      text: prayerTimeController.dailyTargetMinutes.value.toString(),
    );

    Get.dialog(
      AlertDialog(
        title: const Text('하루 목표 시간 설정'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '분 단위로 입력',
            hintText: '예: 30',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text);
              if (minutes != null && minutes > 0) {
                prayerTimeController.updateDailyTarget(minutes);
                Get.back();
                _showTargetSettingDialog(); // 다이얼로그 새로고침
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfoBox(String title, String value, Color color, IconData icon) {
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
            value,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('정말 로그아웃 하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () {
                        authController.logout();
                        Get.offAllNamed('/');
                      },
                      child: const Text('로그아웃'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                '학년별 누적 기도시간',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Get.to(() => GradePrayerDetailScreen());
                            },
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('자세히 보기'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
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

    return Obx(() {
      final username = authController.username.value;
      if (username.isEmpty) {
        return const Center(
          child: Text('로그인이 필요합니다.'),
        );
      }

      return StreamBuilder<QuerySnapshot>(
        stream: prayerTimeController.getPrayerTimes(username),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('저장된 기도 시간이 없습니다.'));
          }

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
                  onPressed: () async {
                    await prayerTimeController.deletePrayerTime(username, doc.id);
                    // 삭제 후 누적 시간 다시 계산
                    await prayerTimeController.calculateTotalPrayerTimes(username);
                    await prayerTimeController.calculateGradeAccumulatedTimes();
                  },
                ),
              );
            },
          );
        },
      );
    });
  }
}

