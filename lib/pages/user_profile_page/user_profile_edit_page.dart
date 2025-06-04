import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/user_profile_viewmodel.dart';

class UserProfileEditPage extends ConsumerStatefulWidget {
  const UserProfileEditPage({super.key});

  @override
  ConsumerState<UserProfileEditPage> createState() =>
      _UserProfileEditPageState();
}

class _UserProfileEditPageState extends ConsumerState<UserProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProfileViewModelProvider).value;
    _emailController = TextEditingController(text: user?.email ?? '');
    _nameController = TextEditingController(text: user?.displayName ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userNotifier = ref.read(userProfileViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              await userNotifier.updateUser(
                email: _emailController.text,
                displayName: _nameController.text,
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('완료'),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('이메일', style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (val) => (val ?? '').isEmpty ? '이메일을 입력하세요' : null,
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('닉네임', style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (val) => (val ?? '').isEmpty ? '닉네임을 입력하세요' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
