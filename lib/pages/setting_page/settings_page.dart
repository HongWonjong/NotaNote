import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/pages/user_profile_page/user_profile_page.dart';
import 'package:nota_note/viewmodels/auth/auth_common.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(userIdProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.w200,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.grey[700]), // 뒤로가기 아이콘
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _SettingsTile(
                  label: '프로필',
                  iconPath: 'assets/icons/User.svg',
                  onTap: () {
                    if (userId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfilePage(userId: userId),
                        ),
                      );
                    }
                  },
                ),
                _SettingsTile(
                  label: '알림',
                  iconPath: 'assets/icons/MagnifyingGlass.svg',
                  onTap: () {
                    // 알림 설정 페이지 이동
                  },
                ),
                _SettingsTile(
                  label: '테마 설정',
                  iconPath: 'assets/icons/Monitor.svg',
                  onTap: () {
                    // 테마 설정 페이지 이동
                  },
                ),
                _SettingsTile(
                  label: '암호',
                  iconPath: 'assets/icons/LockSimple.svg',
                  onTap: () {
                    // 암호 설정 이동
                  },
                ),
                _SettingsTile(
                  label: '이용약관 및 개인정보 정책',
                  iconPath: 'assets/icons/Info.svg',
                  onTap: () {
                    // 약관 페이지 이동
                  },
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              '버전 0.0.0', //현재 버전 표시로 바꾸기
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 공통 설정 항목 위젯
class _SettingsTile extends StatelessWidget {
  final String label;
  final String iconPath;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.label,
    required this.iconPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: SvgPicture.asset(
        iconPath,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
          Colors.grey[500]!, // 아이콘 색상: gray.500
          BlendMode.srcIn,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
            color: Colors.grey[900], // 텍스트 색상: gray.900
            fontSize: 16,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w100),
      ),
      onTap: onTap,
    );
  }
}
