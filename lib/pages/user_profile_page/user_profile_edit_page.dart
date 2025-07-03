import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/models/user_model.dart';
import 'package:nota_note/pages/user_profile_page/widgets/profile_image_widget.dart';
import 'package:nota_note/theme/pretendard_text_styles.dart';
import 'package:nota_note/theme/colors.dart';
import 'package:nota_note/viewmodels/user_profile_viewmodel.dart';

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
          leading: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: SvgPicture.asset(
                'assets/icons/CaretLeft.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
          title: Text(
            '프로필',
            style: PretendardTextStyles.titleS.copyWith(
              color: AppColors.gray900,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(
            color: AppColors.gray700,
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 20),
              child: TextButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  // 프로필 업데이트 함수 호출
                  await updateUserProfile(
                    userId: widget.user.userId,
                    displayName: _nameController.text.trim(),
                    email: _emailController.text.trim(),
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
                const SizedBox(height: 30),
                // 프로필 이미지+카메라 아이콘 (가로 무제한, 세로91)
                SizedBox(
                  width: double.infinity,
                  height: 91,
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        ProfileImageWidget(
                          userId: widget.user.userId,
                          currentPhotoUrl: widget.user.photoUrl,
                          displayName: widget.user.displayName,
                          isEditable: true,
                        ),
                        // 카메라 아이콘 (86x86 프로필 기준 오른쪽 하단)
                        Positioned(
                          bottom: 0,
                          right: -6,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: AppColors.gray200,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/icons/ProfileCamera.svg',
                                width: 20,
                                height: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('닉네임',
                          style: PretendardTextStyles.bodyMEmphasis.copyWith(
                            color: AppColors.gray800,
                          )),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 52,
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            TextFormField(
                              focusNode: _nameFocusNode,
                              controller: _nameController,
                              maxLength: 10,
                              style: PretendardTextStyles.bodyM.copyWith(
                                color: _nameFocusNode.hasFocus
                                    ? AppColors.gray400
                                    : AppColors.gray900,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.gray300,
                                  ),
                                ),
                                //포커스 시 테두리
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.primary200, width: 1.5),
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
                                style: PretendardTextStyles.labelS.copyWith(
                                  color: AppColors.gray400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('이메일',
                          style: PretendardTextStyles.bodyMEmphasis.copyWith(
                            color: AppColors.gray800,
                          )),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 52,
                        child: TextFormField(
                          focusNode: _emailFocusNode,
                          controller: _emailController,
                          style: PretendardTextStyles.bodyM.copyWith(
                            color: _emailFocusNode.hasFocus
                                ? AppColors.gray400
                                : AppColors.gray900,
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.gray300,
                              ),
                            ),
                            //포커스 시 테두리
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.primary200, width: 1.5),
                            ),
                          ),
                          validator: (val) =>
                              (val ?? '').isEmpty ? '이메일을 입력하세요' : null,
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
