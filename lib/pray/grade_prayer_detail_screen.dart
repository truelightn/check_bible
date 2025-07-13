import 'package:check_bible/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'prayer_time_controller.dart';

class GradePrayerDetailScreen extends StatelessWidget {
  final PrayerTimeController prayerTimeController = Get.find();
  final AuthController authController = Get.find();

  GradePrayerDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      String currentUserType = authController.userType.value;

      // 학생의 경우 1학년, 2학년, 3학년만 표시
      List<String> grades = currentUserType == '학생' ? ['1학년', '2학년', '3학년'] : ['1학년', '2학년', '3학년', '새친구', '임원'];
      
      return DefaultTabController(
        length: grades.length,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('학년별 기도시간 상세'),
            backgroundColor: const Color(0xFF8B3DFF),
            foregroundColor: Colors.white,
            bottom: TabBar(
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: grades.map((grade) => Tab(text: grade)).toList(),
            ),
          ),
          body: TabBarView(
            children: grades.map((grade) => _buildGradeTab(grade)).toList(),
          ),
        ),
      );
    });
  }

  Widget _buildGradeTab(String grade) {
    String currentUserType = authController.userType.value;

    if (currentUserType == '학생') {
      // 학생 로그인시: 학생만 표시
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildSingleUserTypeTab(grade, '학생'),
        ),
      );
    } else {
      // 교사 로그인시: 학생과 교사 분리해서 표시
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSingleUserTypeTab(grade, '학생'),
              const SizedBox(height: 16),
              _buildSingleUserTypeTab(grade, '교사'),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSingleUserTypeTab(String grade, String targetUserType) {
    return FutureBuilder<double>(
      future: prayerTimeController.calculateGradeTargetMinutesByUserType(grade, targetUserType),
      builder: (context, targetSnapshot) {
        if (!targetSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        double targetMinutes = targetSnapshot.data!;

        return FutureBuilder<Map<String, double>>(
          future: prayerTimeController.calculateGradeAccumulatedTimesByUserType(targetUserType),
          builder: (context, accumulatedSnapshot) {
            if (!accumulatedSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            Map<String, double> accumulatedData = accumulatedSnapshot.data!;
            double accumulatedMinutes = accumulatedData[grade] ?? 0;

            int targetHours = (targetMinutes / 60).floor();
            int targetMins = (targetMinutes % 60).round();
            int accumulatedHours = (accumulatedMinutes / 60).floor();
            int accumulatedMins = (accumulatedMinutes % 60).round();

            double progressPercentage = targetMinutes > 0 ? (accumulatedMinutes / targetMinutes * 100).clamp(0, 100) : 0;

            Color themeColor = targetUserType == '학생' ? const Color(0xFF8B3DFF) : const Color(0xFFFF6B35);

            return Column(
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
                            Text(
                              '$grade $targetUserType 현황',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                targetUserType,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: themeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoBox(
                                '목표',
                                '$targetHours시간 $targetMins분',
                                themeColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoBox(
                                '누적',
                                '$accumulatedHours시간 $accumulatedMins분',
                                themeColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoBox(
                                '달성률',
                                '${progressPercentage.toStringAsFixed(1)}%',
                                progressPercentage >= 100
                                    ? const Color(0xFF4CAF50)
                                    : progressPercentage < 30
                                        ? const Color(0xFFF44336)
                                        : themeColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progressPercentage / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progressPercentage >= 100
                                ? const Color(0xFF4CAF50)
                                : progressPercentage < 30
                                    ? const Color(0xFFF44336)
                                    : themeColor,
                          ),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
                            Text(
                              '개별 기도시간',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: themeColor,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                targetUserType,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: themeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 300, // 약 6명 정도가 보이도록 높이 제한
                          child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: prayerTimeController.getStudentsByGradeAndSpecificType(grade, targetUserType),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Center(
                                  child: Text(
                                    '${targetUserType} 데이터가 없습니다.',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                );
                              }

                              var students = snapshot.data!;
                              return ListView.separated(
                                itemCount: students.length,
                                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
                                itemBuilder: (context, index) {
                                  var student = students[index];
                                  
                                  return ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                                    title: Text(
                                      student['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${student['hours']}시간 ${student['minutes']}분',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    trailing: Container(
                                      width: 25,
                                      height: 25,
                                      child: CircularProgressIndicator(
                                        value: student['progressPercentage'],
                                        backgroundColor: Colors.grey[200],
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          student['progressPercentage'] >= 1.0
                                              ? const Color(0xFF4CAF50)
                                              : student['progressPercentage'] < 0.3
                                                  ? const Color(0xFFF44336)
                                                  : themeColor,
                                        ),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
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

  Widget _buildInfoBox(String title, String value, Color color) {
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
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
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
}
