import 'package:flutter/material.dart';
import 'package:nota_note/models/user_model.dart';
import 'package:nota_note/pages/login_page/login_page.dart';
import 'package:nota_note/pages/user_profile_page/user_profile_edit_page.dart';
import 'package:nota_note/viewmodels/auth/auth_common.dart';

class UserProfilePage extends StatelessWidget {
  final UserModel user;

  const UserProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 프로필')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey,
                      backgroundImage: user.photoUrl.isNotEmpty
                          ? NetworkImage(user.photoUrl)
                          : null,
                      child: user.photoUrl.isEmpty
                          ? Text(
                              user.displayName.characters.first,
                              style: const TextStyle(
                                  fontSize: 24, color: Colors.white),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(user.displayName,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(user.email,
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text('로그인 방식: ${user.loginProviders}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Positioned(
                  top: 8,
                  right: 16,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileEditPage(user: user),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child:
                        const Text('수정', style: TextStyle(color: Colors.black)),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.email),
            title: Text(user.email),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () async {
              await signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
