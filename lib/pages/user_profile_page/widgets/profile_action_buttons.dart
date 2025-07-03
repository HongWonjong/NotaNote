import 'package:flutter/material.dart';
import 'package:nota_note/theme/colors.dart';
import 'package:nota_note/theme/pretendard_text_styles.dart';

/// 프로필 하단 액션(로그아웃, 탈퇴) 버튼 묶음 위젯
class ProfileActionButtons extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  const ProfileActionButtons({
    super.key,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            onPressed: onLogout,
            child: Text('로그아웃',
                style: PretendardTextStyles.bodyM.copyWith(
                  color: AppColors.gray900,
                )),
          ),
          TextButton(
            onPressed: onDeleteAccount,
            child: Text('계정 탈퇴하기',
                style: PretendardTextStyles.bodyM.copyWith(
                  color: Colors.red,
                )),
          ),
        ],
      ),
    );
  }
}
