import 'package:check_bible/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends StatelessWidget {
  final AuthController authController = Get.put(AuthController());
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('성락교회 고등부 찬양팀')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
            ElevatedButton(
              onPressed: () {
                authController.login(
                  usernameController.text,
                  passwordController.text,
                );
              },
              child: const Text('들어가기'),
            ),
            const Text('본인 이름과 비밀번호(간단한 비밀번호)를 입력해주세요'),
            const Text('비밀 번호는 암화 되지 않고 저장이 됩니다. 평소 사용하지 않는 비밀번호를 입력해주세요'),
            const Text('카카오톡에서 바로 열지말고 다른 브라우저로 열기해서 사용해주세요')
          ],
        ),
      ),
    );
  }
}
