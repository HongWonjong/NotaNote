// login_page
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/main.dart';
import 'package:nota_note/viewmodels/auth_viewmodel.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final viewModel = ref.read(authViewModelProvider);

    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              await viewModel.signInWithGoogle();

              if (!mounted) return;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MyHomePage()),
                );
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('로그인 성공')));
              });
            } catch (e) {
              if (!mounted) return;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('로그인 실패')));
              });
            }
          },
          child: const Text('구글로 로그인'),
        ),
      ),
    );
  }
}
