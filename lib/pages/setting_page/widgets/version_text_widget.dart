import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionTextWidget extends StatelessWidget {
  const VersionTextWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.hasData
            ? snapshot.data!.version
            : '...'; // 로딩 중 or 못가져왔을 때
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            '버전 $version',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
              fontFamily: 'Pretendard',
            ),
          ),
        );
      },
    );
  }
}
