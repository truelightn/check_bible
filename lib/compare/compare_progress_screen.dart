import 'package:flutter/material.dart';
import 'bible_progress_tab.dart';
import 'prayer_ranking_tab.dart';

class CompareProgressScreen extends StatefulWidget {
  @override
  _CompareProgressScreenState createState() => _CompareProgressScreenState();
}

class _CompareProgressScreenState extends State<CompareProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 탭은 성경 읽기와 기도 두 개
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로젝트 현황'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '성경 읽기'),
            Tab(text: '기도 랭킹'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 성경 읽기 탭 화면
          BibleProgressTab(),

          // 기도 랭킹 탭 화면
          PrayerRankingTab(),
        ],
      ),
    );
  }
}
