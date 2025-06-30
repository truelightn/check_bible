import 'package:check_bible/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends StatelessWidget {
  final AuthController authController = Get.put(AuthController());
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxString selectedGradeClass = '1학년'.obs; // 학년 + 반 선택 변수

  // 학년과 반 옵션 생성
  final List<String> gradeClassOptions = ['1학년', '2학년', '3학년', '새친구', '임원'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('25년 고등부 여름 수련회 다니엘 기도회!')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: '이름'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            Obx(() => DropdownButton<String>(
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
                )),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (await authController.login(usernameController.text, selectedGradeClass.value)) {
                  // 로그인 성공
                  Get.offNamed('/prayer_time_input');
                } else {
                  // 로그인 실패
                  Get.snackbar(
                    '오류',
                    '로그인에 실패했습니다.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              child: const Text('등록하기'),
            ),
            const SizedBox(
              height: 20,
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• 본인 이름과 비밀번호(간단한 비밀번호)를 입력해주세요'),
                Text('• 확인되지 않는 이름은 삭제 됩니다!!'),
                Text('• 비밀 번호는 암화 되지 않고 저장이 됩니다. 평소 사용하지 않는 비밀번호를 입력해주세요'),
                Text('• 카카오톡에서 바로 열지말고 다른 브라우저로 열기해서 사용해주세요'),
                Text('• 성공적인 수련회를 위해 열심히 기도합시다!'),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
