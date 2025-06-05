import 'package:flutter/material.dart';
import 'package:nota_note/models/user_model.dart';
import 'package:nota_note/viewmodels/user_profile_viewmodel.dart';

/// 사용자 프로필 수정 페이지
class UserProfileEditPage extends StatefulWidget {
  final UserModel user;

  const UserProfileEditPage({super.key, required this.user});

  @override
  State<UserProfileEditPage> createState() => _UserProfileEditPageState();
}

class _UserProfileEditPageState extends State<UserProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    // 기존 유저 정보를 입력폼에 채워줌
    _emailController = TextEditingController(text: widget.user.email);
    _nameController = TextEditingController(text: widget.user.displayName);
  }

  @override
  void dispose() {
    // 컨트롤러 해제
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 상단 AppBar
      appBar: AppBar(
        leading: const BackButton(color: Colors.grey), // 회색 뒤로가기 버튼
        title: const Text(
          '프로필 수정',
          style: TextStyle(fontWeight: FontWeight.bold), // 볼드체
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () async {
              // 유효성 검사 통과 시 업데이트 수행
              if (!_formKey.currentState!.validate()) return;

              await updateUserProfile(
                userId: widget.user.userId,
                email: _emailController.text,
                displayName: _nameController.text,
              );

              if (mounted) Navigator.pop(context);
            },
            child: const Text(
              '완료',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F2F2F),
              ),
            ),
          )
        ],
      ),

      // 본문
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이메일
              SizedBox(
                height: 28,
              ),
              const Text(
                '이메일',
                style: TextStyle(
                  color: Color(0xFF545454),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white, // 텍스트 박스 안 흰 배경
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE9E9E9), // 테두리 색
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.black,
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (val) => (val ?? '').isEmpty ? '이메일을 입력하세요' : null,
              ),

              const SizedBox(height: 32),

              // 닉네임
              const Text(
                '닉네임',
                style: TextStyle(
                  color: Color(0xFF545454),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white, // 흰 배경
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE9E9E9), //테두라 색
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Colors.black, width: 1.5),
                  ),
                ),
                validator: (val) => (val ?? '').isEmpty ? '닉네임을 입력하세요' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
