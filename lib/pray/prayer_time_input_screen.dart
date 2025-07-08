import 'package:check_bible/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // 날짜 포맷을 위해 사용

import 'grade_prayer_detail_screen.dart';
import 'prayer_time_controller.dart';

class PrayerTimeInputScreen extends StatefulWidget {
  const PrayerTimeInputScreen({super.key});

  @override
  _PrayerTimeInputScreenState createState() => _PrayerTimeInputScreenState();
}

class _PrayerTimeInputScreenState extends State<PrayerTimeInputScreen> {
  final PrayerTimeController prayerTimeController = Get.put(PrayerTimeController());
  final AuthController authController = Get.find(); // 사용자 정보 접근

  Duration selectedDuration = const Duration(hours: 0, minutes: 0);
  DateTime selectedDate = DateTime.now(); // 선택된 날짜 추가
  double maxY = 0; // 추가된 클래스 필드

  @override
  void initState() {
    super.initState();
    
    // 로그인 상태 확인 및 데이터 초기화
    if (authController.isLoggedIn.value) {
      _initializeData();
    } else {
      // 자동 로그인 시도
      authController.autoLogin();

      // 자동 로그인 결과 확인
      Future.delayed(const Duration(milliseconds: 500), () {
        if (authController.isLoggedIn.value) {
          _initializeData();
        } else {
          Get.offAllNamed('/');
        }
      });
    }
  }

  void _initializeData() {
    if (authController.username.value.isNotEmpty) {
      prayerTimeController.calculateTotalPrayerTimes(authController.username.value, authController.userType.value);
      // 기존 calculateGradeAccumulatedTimes 호출 제거 - 차트에서 동적으로 계산
    }
  }

  Widget _buildGradeChart() {
    return Obx(() {
      String currentUserType = authController.userType.value;

      if (currentUserType == '학생') {
        // 학생 로그인시: 학생 차트만 표시
        return _buildSingleUserTypeChart('학생');
      } else {
        // 교사 로그인시: 학생과 교사 차트를 분리해서 표시
        return Column(
          children: [
            _buildSingleUserTypeChart('학생'),
            const SizedBox(height: 16),
            _buildSingleUserTypeChart('교사'),
          ],
        );
      }
    });
  }

  Widget _buildSingleUserTypeChart(String targetUserType) {
    Color themeColor = targetUserType == '학생' ? const Color(0xFF8B3DFF) : const Color(0xFFFF6B35);

    // 학생의 경우 1학년, 2학년, 3학년만 표시
    List<String> grades = targetUserType == '학생' ? ['1학년', '2학년', '3학년'] : ['1학년', '2학년', '3학년', '새친구', '임원'];

    return FutureBuilder<Map<String, double>>(
      future: prayerTimeController.calculateGradeAccumulatedTimesByUserType(targetUserType),
      builder: (context, accumulatedSnapshot) {
        if (!accumulatedSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        Map<String, double> totals = accumulatedSnapshot.data!;

        return FutureBuilder<Map<String, double>>(
          future: Future.wait(grades.map((grade) => prayerTimeController.calculateGradeTargetMinutesByUserType(grade, targetUserType))).then((values) => Map.fromIterables(grades, values)),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            Map<String, double> targets = snapshot.data!;
            
            // 표시할 학년의 데이터만 필터링
            List<double> displayTotals = grades.map((grade) => totals[grade] ?? 0).toList();
            List<double> displayTargets = grades.map((grade) => targets[grade] ?? 0).toList();

            double chartMaxY = [...displayTotals, ...displayTargets].reduce((curr, next) => curr > next ? curr : next);

            // Y축 간격 계산 (최대값을 10개의 구간으로 나눔)
            double interval = (chartMaxY / 10).roundToDouble();
            // 간격을 60분 단위로 올림
            if (interval % 60 != 0) {
              interval = ((interval / 60).ceil() * 60).toDouble();
            }
            chartMaxY = interval * 10; // maxY를 간격의 10배로 조정

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '학년별 누적 기도시간 ($targetUserType)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 250,
                  padding: const EdgeInsets.all(16),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: chartMaxY + interval,
                      minY: 0,
                      barGroups: List.generate(grades.length, (index) {
                        return _createBarGroupWithTarget(index, displayTotals[index], displayTargets[index], [themeColor, themeColor.withValues(alpha: 0.7)]);
                      }),
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
                              int index = value.toInt();
                              if (index >= 0 && index < grades.length) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    grades[index],
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
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
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: themeColor.withValues(alpha: 0.9),
                          tooltipRoundedRadius: 8,
                          tooltipPadding: const EdgeInsets.all(12),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            if (groupIndex >= 0 && groupIndex < grades.length) {
                              String grade = grades[groupIndex];
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
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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
    await prayerTimeController.savePrayerTime(authController.username.value, authController.userType.value);

    // Firestore에서 누적 시간을 다시 계산하여 업데이트
    await prayerTimeController.calculateTotalPrayerTimes(authController.username.value, authController.userType.value);
    // 학년별 누적시간은 차트에서 동적으로 계산되므로 제거

    Get.back();
  }

  Widget _buildTimeSelectButton(Duration duration) {
    bool isSelected = selectedDuration == duration;
    
    // 시간 형식 변환 (예: 1:30, 2:00)
    String timeText = '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedDuration = duration;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF8B3DFF) : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          elevation: isSelected ? 4 : 1,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          timeText,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerTimeInputCard() {
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
                    color: const Color(0xFF8B3DFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '기도시간 입력',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () => _selectDate(context),
              child: Row(
                children: [
                  Text(
                    DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(selectedDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '기도시간 선택',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // 30분 단위 (30분 ~ 4시간)
                for (int i = 1; i <= 8; i++) _buildTimeSelectButton(Duration(minutes: i * 30)),
                // 4시간 30분 ~ 6시간
                for (int i = 9; i <= 12; i++) _buildTimeSelectButton(Duration(minutes: i * 30)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedDuration.inMinutes > 0 ? _savePrayerTime : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B3DFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save),
                    const SizedBox(width: 8),
                    Text(
                      selectedDuration.inMinutes > 0
                          ? '기도시간 ${selectedDuration.inHours > 0 ? '${selectedDuration.inHours}시간 ' : ''}'
                              '${selectedDuration.inMinutes % 60}분 저장'
                          : '기도시간을 선택해주세요',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
                        color: const Color(0xFF8B3DFF),
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
                          const Color(0xFFFF6B35),
                          Icons.flag,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimeInfoBox(
                          '누적 기도시간',
                          '${prayerTimeController.totalPrayerHour.value}시간 '
                              '${prayerTimeController.totalPrayerMinute.value}분',
                          const Color(0xFF8B3DFF),
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
                          const Color(0xFF4CAF50),
                          Icons.today,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimeInfoBox(
                          '달성률',
                          '${progressPercentage.toStringAsFixed(1)}%',
                          progressPercentage >= 100
                              ? const Color(0xFF4CAF50)
                              : progressPercentage < 30
                                  ? const Color(0xFFF44336)
                                  : const Color(0xFF8B3DFF),
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
                          ? const Color(0xFF4CAF50)
                          : progressPercentage < 30
                              ? const Color(0xFFF44336)
                              : const Color(0xFF8B3DFF),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
        title: Obx(() {
          final daysPassed = DateTime.now().difference(prayerTimeController.startDate.value).inDays + 1;
          return Text('[우리가 FM] 다니엘기도회 D+$daysPassed일차');
        }),
        backgroundColor: const Color(0xFF8B3DFF),
        foregroundColor: Colors.white,
        actions: [
          Obx(() => authController.username.value.isNotEmpty
              ? IconButton(
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
                )
              : const SizedBox.shrink()
          ),
        ],
      ),
      body: Obx(() {
        if (authController.username.value.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  '기도시간을 기록하려면\n로그인이 필요합니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Get.offAllNamed('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B3DFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    '로그인 하러가기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
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
                        const SizedBox(height: 16),
                        _buildGradeChart(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Get.to(() => GradePrayerDetailScreen());
                              },
                              icon: const Icon(Icons.arrow_forward, color: Color(0xFF8B3DFF)),
                              label: const Text('자세히 보기', style: TextStyle(color: Color(0xFF8B3DFF))),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF8B3DFF),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildMyPrayerTimeCard(),
                const SizedBox(height: 20),
                _buildPrayerTimeInputCard(),
                const SizedBox(height: 20),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: PrayerTimeListWidget(),
                ),
              ],
            ),
          ),
        );
      }),
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
        stream: prayerTimeController.getPrayerTimes(username, authController.userType.value),
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
                    await prayerTimeController.deletePrayerTime(username, authController.userType.value, doc.id);
                    // 삭제 후 누적 시간 다시 계산
                    await prayerTimeController.calculateTotalPrayerTimes(username, authController.userType.value);
                    // 학년별 누적시간은 차트에서 동적으로 계산되므로 제거
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

