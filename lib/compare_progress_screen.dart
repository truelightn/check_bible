import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompareProgressScreen extends StatefulWidget {
  @override
  _CompareProgressScreenState createState() => _CompareProgressScreenState();
}

class _CompareProgressScreenState extends State<CompareProgressScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 모든 성경의 총 장 수
  final int totalBibleChapters = 1189;
  final int newTestamentChapters = 260; // 신약의 총 장 수

  bool showNewTestamentOnly = true; // 신약만 보기 토글 상태

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('읽기 현황'),
      ),
      body: Column(
        children: [
          // 신약만 보기 토글 버튼
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
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
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder(
              stream: _firestore.collection('users').snapshots(), // Firestore에서 'users' 컬렉션의 실시간 스냅샷 가져옴
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator()); // 데이터가 로드되지 않았을 때 로딩 인디케이터
                }

                // 총 장 수를 기준으로 설정
                int totalChapters = showNewTestamentOnly ? newTestamentChapters : totalBibleChapters;

                // 사용자 진행 데이터를 처리하고 정렬
                List<Map<String, dynamic>> userProgressList = snapshot.data!.docs.map((doc) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                  // 사용자 정보 추출
                  String username = data['username'] ?? 'Unknown'; // username 필드
                  Map<String, dynamic> bibleProgress = data['bibleProgress'] ?? {}; // bibleProgress 필드

                  // 완료된 장수 계산
                  int completedChapters = 0;
                  int completedOldTestamentChapters = 0;
                  int completedNewTestamentChapters = 0;

                  bibleProgress.forEach((book, chapters) {
                    Map chaptersMap = chapters as Map;
                    int bookChaptersCompleted = chaptersMap.values.where((isRead) => isRead == true).length;
                    completedChapters += bookChaptersCompleted;

                    // 구약과 신약을 구분하여 완료된 장수 계산
                    if (_isOldTestament(book)) {
                      completedOldTestamentChapters += bookChaptersCompleted;
                    } else {
                      completedNewTestamentChapters += bookChaptersCompleted;
                    }
                  });

                  // 진행도를 신약만 볼 경우에는 신약 장수만으로, 그렇지 않으면 전체로 계산
                  double progress = (showNewTestamentOnly
                      ? (completedNewTestamentChapters / newTestamentChapters)
                      : (completedChapters / totalChapters));

                  return {
                    'username': username,
                    'progress': progress,
                    'completedChapters': completedChapters,
                    'completedOldTestamentChapters': completedOldTestamentChapters,
                    'completedNewTestamentChapters': completedNewTestamentChapters
                  };
                }).toList();

                // 진행 퍼센트로 내림차순 정렬
                userProgressList.sort((a, b) => b['progress'].compareTo(a['progress']));

                return ListView(
                  children: [
                    // 상위 1, 2, 3등 사용자 표시
                    _buildTop3(userProgressList),

                    // 사용자별 진행 상황 표시
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        '전체 사용자 진행 상황',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...userProgressList.map((user) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Card(
                          elevation: 3,
                          child: ListTile(
                            title: Text(user['username'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8.0),
                                LinearProgressIndicator(
                                  value: user['progress'], // 퍼센트 값에 따라 진행바 업데이트
                                  backgroundColor: Colors.grey[300],
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  '구약: ${user['completedOldTestamentChapters']}장 / 신약: ${user['completedNewTestamentChapters']}장',
                                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                                ),
                                Text(
                                  '전체 진행도: ${user['completedChapters']}/${totalChapters}장 (${(user['progress'] * 100).toStringAsFixed(1)}%)',
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
              },
            ),
          ),
        ],
      ),
    );
  }

  // 구약 신약 구분 함수 (간단히 구약 책들로 구분)
  bool _isOldTestament(String book) {
    const oldTestamentBooks = {
      '창세기', '출애굽기', '레위기', '민수기', '신명기',
      '여호수아', '사사기', '룻기', '사무엘상', '사무엘하',
      '열왕기상', '열왕기하', '역대상', '역대하', '에스라',
      '느헤미야', '에스더', '욥기', '시편', '잠언', '전도서', '아가',
      '이사야', '예레미야', '예레미야애가', '에스겔', '다니엘', '호세아',
      '요엘', '아모스', '오바댜', '요나', '미가', '나훔', '하박국', '스바냐',
      '학개', '스가랴', '말라기'
    };
    return oldTestamentBooks.contains(book);
  }

  // 상위 1, 2, 3등 표시 위젯
  Widget _buildTop3(List<Map<String, dynamic>> userProgressList) {
    List<Map<String, dynamic>> top3 = userProgressList.take(3).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '상위 3명의 사용자',
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

  // 상위 순위에 따른 메달 타입 결정
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

  // 상위 순위에 따른 메달 색상 결정
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

  // 상위 순위에 따른 아이콘 크기 결정
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
