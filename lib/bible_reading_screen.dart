import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // GetStorage 가져오기
import 'bible_controller.dart';
import 'login_screen.dart'; // 로그아웃 후 로그인 화면으로 이동하기 위한 스크린
import 'compare_progress_screen.dart'; // CompareProgressScreen import

class BibleReadingScreen extends StatefulWidget {
  @override
  _BibleReadingScreenState createState() => _BibleReadingScreenState();
}

class _BibleReadingScreenState extends State<BibleReadingScreen> {
  late BibleController bibleController;
  final GetStorage storage = GetStorage(); // GetStorage 인스턴스 생성

  // 구약 성경 책 목록과 각 책의 장 수
  final Map<String, int> oldTestamentChapters = {
    '창세기': 50, '출애굽기': 40, '레위기': 27, '민수기': 36, '신명기': 34,
    '여호수아': 24, '사사기': 21, '룻기': 4, '사무엘상': 31, '사무엘하': 24,
    '열왕기상': 22, '열왕기하': 25, '역대상': 29, '역대하': 36, '에스라': 10,
    '느헤미야': 13, '에스더': 10, '욥기': 42, '시편': 150, '잠언': 31,
    '전도서': 12, '아가': 8, '이사야': 66, '예레미야': 52, '예레미야애가': 5,
    '에스겔': 48, '다니엘': 12, '호세아': 14, '요엘': 3, '아모스': 9,
    '오바댜': 1, '요나': 4, '미가': 7, '나훔': 3, '하박국': 3,
    '스바냐': 3, '학개': 2, '스가랴': 14, '말라기': 4,
  };

  // 신약 성경 책 목록과 각 책의 장 수
  final Map<String, int> newTestamentChapters = {
    '마태복음': 28, '마가복음': 16, '누가복음': 24, '요한복음': 21,
    '사도행전': 28, '로마서': 16, '고린도전서': 16, '고린도후서': 13,
    '갈라디아서': 6, '에베소서': 6, '빌립보서': 4, '골로새서': 4,
    '데살로니가전서': 5, '데살로니가후서': 3, '디모데전서': 6, '디모데후서': 4,
    '디도서': 3, '빌레몬서': 1, '히브리서': 13, '야고보서': 5,
    '베드로전서': 5, '베드로후서': 3, '요한1서': 5, '요한2서': 1,
    '요한3서': 1, '유다서': 1, '요한계시록': 22
  };

  // 신약만 보기 토글 상태를 관리하는 변수 (기본값: true)
  bool showNewTestamentOnly = true;

  @override
  void initState() {
    super.initState();
    bibleController = Get.put(BibleController()); // initState에서 컨트롤러 설정
  }

  // 로그아웃 함수
  void logout() {
    storage.erase(); // GetStorage에 저장된 모든 값 삭제
    Get.offAll(() => LoginScreen()); // 로그아웃 후 로그인 화면으로 이동
  }

  // 구약 또는 신약 성경 리스트 빌더
  Widget buildBibleSection(String sectionTitle, Map<String, int> bibleChapters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          child: Text(
            sectionTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // ListView가 ListView 안에서 스크롤되지 않도록 설정
          itemCount: bibleChapters.length,
          itemBuilder: (context, index) {
            String bookName = bibleChapters.keys.elementAt(index);
            int chapters = bibleChapters[bookName]!;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 성경 책 이름 텍스트를 글자 크기에 맞게 조정
                      SizedBox(
                        width: 120,
                        child: Text(
                          bookName,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      // 오른쪽에 해당 성경의 장 수만큼의 동그라미와 숫자를 표시
                      Expanded(
                        child: Wrap(
                          spacing: 10.0, // 동그라미 사이 간격
                          runSpacing: 10.0, // 동그라미 위아래 간격
                          children: List.generate(chapters, (chapterIndex) {
                            return Obx(() {
                              // 읽음 여부에 따라 색상 변경
                              bool isRead = bibleController.isChapterRead(bookName, chapterIndex + 1);
                              return GestureDetector(
                                onTap: () {
                                  bibleController.updateChapterProgress(bookName, chapterIndex + 1, !isRead);
                                },
                                child: Container(
                                  width: 30,  // 동그라미 크기
                                  height: 30, // 동그라미 크기
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isRead ? Colors.green : Colors.transparent, // 체크된 상태는 초록색, 체크 안된 상태는 투명
                                    border: Border.all( // 체크 안된 상태에서 회색 테두리
                                      color: isRead ? Colors.green : Colors.grey, // 체크 안된 상태는 회색 테두리
                                      width: 1.0,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${chapterIndex + 1}', // 숫자 표시
                                    style: TextStyle(
                                      color: isRead ? Colors.white : Colors.grey, // 체크된 상태는 흰색, 체크 안된 상태는 회색
                                    ),
                                  ),
                                ),
                              );
                            });
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider( // 성경마다 구분선 추가
                  thickness: 1.0, // 선 두께
                  color: Colors.black12, // 선 색상
                  height: 20.0, // 선과의 간격
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('성락교회 고등부'),
            IconButton(
            icon: const Icon(Icons.bookmark_border_rounded), // 비교 아이콘 (아이콘은 원하는대로 변경 가능)
            onPressed: () {
              Get.to(() => CompareProgressScreen()); // CompareProgressScreen으로 이동
            },
          ),
          ]
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), // 로그아웃 아이콘
            onPressed: logout, // 로그아웃 함수 호출
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
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
                        showNewTestamentOnly = value; // 토글 상태 업데이트
                      });
                    },
                  ),
                ],
              ),
            ),

            // 구약 섹션 (신약만 보기 상태일 때는 표시되지 않음)
            if (!showNewTestamentOnly) buildBibleSection("구약 성경", oldTestamentChapters),

            // 신약 섹션
            buildBibleSection("신약 성경", newTestamentChapters),
          ],
        ),
      ),
    );
  }
}
