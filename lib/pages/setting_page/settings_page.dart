import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/pages/setting_page/widgets/version_text_widget.dart';
import 'package:nota_note/pages/terms_page/terms_page.dart';
import 'package:nota_note/pages/user_profile_page/user_profile_page.dart';
import 'package:nota_note/theme/colors.dart';
import 'package:nota_note/theme/pretendard_text_styles.dart';
import 'package:nota_note/viewmodels/auth/auth_common.dart';
import 'package:nota_note/viewmodels/auth/user_id_provider.dart';

/// 설정 페이지
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 현재 로그인된 사용자 ID 읽기 (초기값은 userIdProvider에서 가져오지만, 아래서 실시간 갱신함)
    final userId = ref.watch(userIdProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '설정',
          style: PretendardTextStyles.titleS.copyWith(
            color: AppColors.gray900,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppColors.gray700,
        ),
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
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // 프로필 설정
                _SettingsTile(
                  label: '프로필',
                  iconPath: 'assets/icons/User.svg',
                  onTap: () async {
                    // userIdProvider 상태를 강제로 최신화 (시뮬레이터 재시작 시에도 대응)
                    final latestUserId = await getCurrentUserId();
                    ref.read(userIdProvider.notifier).state = latestUserId;

                    //최신 userId 기준으로 프로필 페이지 이동 << 현재 버그있음.
                    if (latestUserId != null && latestUserId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfilePage(userId: latestUserId),
                        ),
                      );
                    } else {
                      // 로딩 중 또는 null일 경우 스낵바 표시
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('사용자 정보를 불러오는 중입니다.')),
                      );
                    }
                  },
                ),
                // 알림 설정
                _SettingsTile(
                  label: '알림(추후 추가 예정)',
                  iconPath: 'assets/icons/MagnifyingGlass.svg',
                  onTap: () {
                    // 알림 설정 페이지 이동 예정
                  },
                ),
                // 테마 설정
                _SettingsTile(
                  label: '테마 설정(추후 추가 예정)',
                  iconPath: 'assets/icons/Monitor.svg',
                  onTap: () {
                    // 테마 설정 페이지 이동 예정
                  },
                ),
                // 암호 설정
                _SettingsTile(
                  label: '암호(추후 추가 예정)',
                  iconPath: 'assets/icons/LockSimple.svg',
                  onTap: () {
                    // 암호 설정 페이지 이동 예정
                  },
                ),
                // 이용약관
                _SettingsTile(
                  label: '이용약관 및 개인정보 정책',
                  iconPath: 'assets/icons/Info.svg',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TermsPage()),
                    );
                  },
                ),
              ],
            ),
          ),
          // 하단 앱 버전 표시
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: VersionTextWidget()),
        ],
      ),
    );
  }
}

/// 공통 설정 항목 위젯
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
          AppColors.gray500,
          BlendMode.srcIn,
        ),
      ),
      title: Text(
        label,
        style: PretendardTextStyles.bodyM.copyWith(
          color: AppColors.gray900,
        ),
      ),
      onTap: onTap,
    );
  }
}
