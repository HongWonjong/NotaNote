import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/models/user_model.dart';
import 'package:nota_note/pages/user_profile_page/widgets/profile_image_widget.dart';
import 'package:nota_note/theme/pretendard_text_styles.dart';
import 'package:nota_note/theme/colors.dart';

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

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();

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
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(color: Colors.grey),
          title: Text(
            '프로필',
            style:
                PretendardTextStyles.titleS.copyWith(color: Colors.grey[900]),
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
                  Navigator.pop(context, true);
                }
              },
              child: Text(
                '완료',
                style: PretendardTextStyles.bodyM
                    .copyWith(color: AppColors.primary300Main),
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

                // 프로필 이미지
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
                                'assets/icons/ProfileCamera.svg'),
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
                      Text('닉네임',
                          style: PretendardTextStyles.bodyMEmphasis
                              .copyWith(color: Colors.grey[800])),
                      const SizedBox(height: 12),
                      Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          TextFormField(
                            focusNode: _nameFocusNode,
                            controller: _nameController,
                            maxLength: 10,
                            style: PretendardTextStyles.bodyM
                                .copyWith(color: Colors.grey[900]),
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
                              style: PretendardTextStyles.labelS
                                  .copyWith(color: Colors.grey[400]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('이메일',
                          style: PretendardTextStyles.bodyMEmphasis
                              .copyWith(color: Colors.grey[800])),
                      const SizedBox(height: 12),
                      TextFormField(
                        focusNode: _emailFocusNode,
                        controller: _emailController,
                        style: PretendardTextStyles.bodyM
                            .copyWith(color: Colors.grey[900]),
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
                //수정페이지에선 로그아웃, 탈퇴 없앰.

                // const SizedBox(height: 30),
                // Divider(color: Colors.grey[200], thickness: 6),
                // const SizedBox(height: 10),

                // Padding(
                //   padding:
                //       const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       TextButton(
                //         onPressed: () async {
                //           await signOut();
                //           if (context.mounted) {
                //             Navigator.pushAndRemoveUntil(
                //               context,
                //               MaterialPageRoute(
                //                   builder: (_) => const LoginPage()),
                //               (route) => false,
                //             );
                //           }
                //         },
                //         child: Text(
                //           '로그아웃',
                //           style: PretendardTextStyles.bodyM.copyWith(
                //             color: Colors.grey[900],
                //           ),
                //         ),
                //       ),
                //       TextButton(
                //         onPressed: () {},
                //         child: Text(
                //           '계정 탈퇴하기',
                //           style: PretendardTextStyles.bodyM.copyWith(
                //             color: Colors.red,
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
