import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'prayer_time_controller.dart';

class GradePrayerDetailScreen extends StatelessWidget {
  final PrayerTimeController prayerTimeController = Get.find();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('학년별 기도시간 상세'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '1학년'),
              Tab(text: '2학년'),
              Tab(text: '3학년'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGradeTab('1학년'),
            _buildGradeTab('2학년'),
            _buildGradeTab('3학년'),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeTab(String grade) {
    double targetMinutes = prayerTimeController.calculateTargetMinutes(grade);
    double accumulatedMinutes = prayerTimeController.gradeAccumulatedMinutes[grade] ?? 0;

    int targetHours = (targetMinutes / 60).floor();
    int targetMins = (targetMinutes % 60).round();
    int accumulatedHours = (accumulatedMinutes / 60).floor();
    int accumulatedMins = (accumulatedMinutes % 60).round();

    double progressPercentage = (accumulatedMinutes / targetMinutes * 100).clamp(0, 100);

    return Padding(
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
                  Text(
                    '$grade 현황',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoBox(
                          '목표 시간',
                          '$targetHours시간 $targetMins분',
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoBox(
                          '누적 시간',
                          '$accumulatedHours시간 $accumulatedMins분',
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '달성률: ${progressPercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progressPercentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressPercentage >= 100 ? Colors.green : Colors.blue,
                    ),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
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
                      '학생별 기도시간',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: prayerTimeController.getStudentsByGrade(grade),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('데이터가 없습니다.'));
                          }

                          var students = snapshot.data!;
                          return ListView.separated(
                            itemCount: students.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              var student = students[index];
                              return ListTile(
                                title: Text(
                                  student['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${student['hours']}시간 ${student['minutes']}분',
                                ),
                                trailing: CircularProgressIndicator(
                                  value: student['progressPercentage'],
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    student['progressPercentage'] >= 1.0 ? Colors.green : Colors.blue,
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
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String title, String value, Color color) {
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
