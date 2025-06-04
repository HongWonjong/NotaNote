import 'package:flutter/material.dart';
import 'package:nota_note/models/user_model.dart';
import 'package:nota_note/pages/user_profile_page/user_profile_page.dart';

class SettingsPage extends StatelessWidget {
  final UserModel user;

  const SettingsPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('프로필 수정'),
            leading: const Icon(Icons.person),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfilePage(user: user),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('기타 설정'),
            leading: const Icon(Icons.settings),
            onTap: () {
              // 향후 기능
            },
          ),
        ],
      ),
    );
  }
}
