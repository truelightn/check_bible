import 'package:check_bible/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends StatelessWidget {
  final AuthController authController = Get.put(AuthController());
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxString selectedGradeClass = '1학년'.obs; // 학년 + 반 선택 변수
  final RxString selectedUserType = '학생'.obs; // 사용자 타입 선택 변수

  // 학년과 반 옵션 생성
  final List<String> gradeClassOptions = ['1학년', '2학년', '3학년', '새친구', '임원'];

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('25년 고등부 여름 수련회[우리가 FM] 다니엘 기도회!'),
        backgroundColor: const Color(0xFF8B3DFF), // 보라색
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // 기본 정보 입력 카드
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person, color: Color(0xFF8B3DFF), size: 24), // 보라색
                        SizedBox(width: 8),
                        Text(
                          '기본 정보',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: '이름',
                        prefixIcon: const Icon(Icons.account_circle, color: Color(0xFF8B3DFF)), // 보라색
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF8B3DFF), width: 2), // 보라색
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFF8B3DFF)), // 보라색
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF8B3DFF), width: 2), // 보라색
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      obscureText: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 추가 정보 선택 카드
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B3DFF).withValues(alpha: 0.1), // 보라색 배경
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF8B3DFF).withValues(alpha: 0.3)), // 보라색 테두리
                      ),
                      child: Obx(() => Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selectedUserType.value == '학생'
                                        ? const Color(0xFF8B3DFF).withValues(alpha: 0.2) // 보라색
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: selectedUserType.value == '학생'
                                          ? const Color(0xFF8B3DFF) // 보라색
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: RadioListTile<String>(
                                    value: '학생',
                                    groupValue: selectedUserType.value,
                                    onChanged: (String? value) {
                                      selectedUserType.value = value!;
                                    },
                                    title: const Text('학생'),
                                    dense: true,
                                    activeColor: const Color(0xFF8B3DFF), // 보라색
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selectedUserType.value == '교사'
                                        ? const Color(0xFF8B3DFF).withValues(alpha: 0.2) // 보라색
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: selectedUserType.value == '교사'
                                          ? const Color(0xFF8B3DFF) // 보라색
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: RadioListTile<String>(
                                    value: '교사',
                                    groupValue: selectedUserType.value,
                                    onChanged: (String? value) {
                                      selectedUserType.value = value!;
                                    },
                                    title: const Text('교사'),
                                    dense: true,
                                    activeColor: const Color(0xFF8B3DFF), // 보라색
                                  ),
                                ),
                              ),
                            ],
                          )),
                    ),

                    const SizedBox(height: 20),

                    // 학년/반 선택
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withValues(alpha: 0.1), // 주황색 배경
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.3)), // 주황색 테두리
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.school, color: Color(0xFFFF6B35), size: 20), // 주황색 아이콘
                              SizedBox(width: 8),
                              Text(
                                '학년/반',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.5)), // 주황색 테두리
                            ),
                            child: Obx(() => DropdownButton<String>(
                                  value: selectedGradeClass.value,
                                  onChanged: (newValue) {
                                    selectedGradeClass.value = newValue!;
                                  },
                                  items: gradeClassOptions.map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  dropdownColor: Colors.white,
                                )),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 등록 버튼
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B3DFF), Color(0xFFFF6B35)], // 보라색에서 주황색으로 그라데이션
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B3DFF).withValues(alpha: 0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () async {
                  if (await authController.login(usernameController.text, selectedGradeClass.value, selectedUserType.value)) {
                    // 로그인 성공
                    Get.offNamed('/prayer_time_input');
                  } else {
                    // 로그인 실패
                    Get.snackbar(
                      '오류',
                      '로그인에 실패했습니다.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red[400],
                      colorText: Colors.white,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '등록하기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 안내 사항 카드
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFFFF6B35), size: 24), // 주황색
                        SizedBox(width: 8),
                        Text(
                          '안내 사항',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoText(text: '본인 이름과 비밀번호(간단한 비밀번호)를 입력해주세요'),
                        _InfoText(text: '확인되지 않는 이름은 삭제 됩니다!!'),
                        _InfoText(text: '비밀 번호는 암화 되지 않고 저장이 됩니다. 평소 사용하지 않는 비밀번호를 입력해주세요'),
                        _InfoText(text: '카카오톡에서 바로 열지말고 다른 브라우저로 열기해서 사용해주세요'),
                        _InfoText(text: '성공적인 수련회를 위해 열심히 기도합시다!'),
                        _InfoText(text: '오류/문의 사항은 나진환T에게 연락하세요'),
                      ],
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
}

class _InfoText extends StatelessWidget {
  final String text;

  const _InfoText({required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 8),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFFFF6B35), // 주황색
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
