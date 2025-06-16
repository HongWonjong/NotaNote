// lib/pages/user_profile_page/user_profile_edit_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/models/user_model.dart';
import 'package:nota_note/pages/login_page/login_page.dart';
import 'package:nota_note/pages/user_profile_page/widgets/profile_image_widget.dart';
import 'package:nota_note/viewmodels/auth/auth_common.dart';
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

  final FocusNode _nameFocusNode = FocusNode(); // 추가
  final FocusNode _emailFocusNode = FocusNode(); // 추가

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user.email);
    _nameController = TextEditingController(text: widget.user.displayName);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose(); // 해제
    _emailFocusNode.dispose(); // 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // 키보드 문제 방지
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(color: Colors.grey),
          title: Text(
            '프로필',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
              color: Colors.grey[900],
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.grey[700]),
          actions: [
            TextButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;

                await updateUserProfile(
                  userId: widget.user.userId,
                  email: _emailController.text,
                  displayName: _nameController.text,
                );

                if (mounted) {
                  Navigator.pop(context, true); // true 전달
                }
              },
              child: Text(
                '완료',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // 프로필 이미지 수정 가능
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ProfileImageWidget(
                        userId: widget.user.userId,
                        currentPhotoUrl: widget.user.photoUrl,
                        displayName: widget.user.displayName,
                        isEditable: true,
                      ),
                      Positioned(
                        bottom: 0,
                        right: -4,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border.all(color: Colors.grey[200]!),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/ProfileCamera.svg',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 닉네임
                      Text(
                        '닉네임',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          TextFormField(
                            focusNode: _nameFocusNode,
                            controller: _nameController,
                            maxLength: 10,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[900],
                              fontFamily: 'Pretendard',
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.black, width: 1.5),
                              ),
                            ),
                            validator: (val) =>
                                (val ?? '').isEmpty ? '닉네임을 입력하세요' : null,
                            onChanged: (_) => setState(() {}),
                          ),
                          Positioned(
                            right: 16,
                            child: Text(
                              '${_nameController.text.length}/10',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 이메일
                      Text(
                        '이메일',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        focusNode: _emailFocusNode,
                        controller: _emailController,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[900],
                          fontFamily: 'Pretendard',
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Colors.black, width: 1.5),
                          ),
                        ),
                        validator: (val) =>
                            (val ?? '').isEmpty ? '이메일을 입력하세요' : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Divider(color: Colors.grey[200], thickness: 6),

                // 계정 전환
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),
                      Text(
                        '계정 전환',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Pretendard',
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),

                ListTile(
                  leading: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFB0E7D8),
                    child: Icon(Icons.person, color: Colors.white, size: 16),
                  ),
                  title: Text(
                    widget.user.email,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[900],
                    ),
                  ),
                  onTap: () {},
                ),

                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/Plus.svg',
                      width: 20,
                      height: 20,
                    ),
                  ),
                  title: Text(
                    '계정 추가하기',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[900],
                    ),
                  ),
                  onTap: () {},
                ),

                Divider(color: Colors.grey[200], thickness: 6),

                // 로그아웃/탈퇴
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton(
                        onPressed: () async {
                          await signOut();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginPage()),
                              (route) => false,
                            );
                          }
                        },
                        child: Text(
                          '로그아웃',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[900],
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                      const Center(
                        child: Text(
                          '계정 탈퇴하기',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFFF2F2F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
