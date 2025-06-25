import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/pages/login_page/login_page.dart';
import 'package:nota_note/theme/colors.dart';
import 'package:nota_note/theme/pretendard_text_styles.dart';

class AccountDeletedPage extends StatelessWidget {
  const AccountDeletedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // SafeArea로 상단, 하단 여백을 자동 보장
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const SizedBox(height: 80), // 최상단과 아이콘 사이 여백
              // 1. 아이콘
              const Spacer(),

              Center(
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: SvgPicture.asset(
                    'assets/icons/Circle.svg',
                    width: 76,
                    height: 76,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              // 2. 텍스트 영역
              SizedBox(
                width: 303,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      '계정 탈퇴가 완료되었습니다.',
                      textAlign: TextAlign.center,
                      style: PretendardTextStyles.headS.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '지금까지 노타노트를 이용해주셔서 감사합니다.\n앞으로 더 나은 서비스를 제공하기 위해 노력하겠습니다.',
                      textAlign: TextAlign.center,
                      style: PretendardTextStyles.labelM.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // 3. 중간 공간을 최대한 확보
              const Spacer(),
              SizedBox(
                height: 100,
              ),
              // 4. 확인 버튼 (가운데, width 114, height 50, 하단에 고정)
              Center(
                child: SizedBox(
                  width: 114,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary300Main,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(114, 50),
                      maximumSize: const Size(114, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      '확인',
                      style: PretendardTextStyles.bodyM.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36), // 하단과 버튼 사이 간격
            ],
          ),
        ),
      ),
    );
  }
}
