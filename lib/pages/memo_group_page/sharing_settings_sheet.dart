import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/models/member.dart';

class SharingSettingsSheet extends StatefulWidget {
  final List<Member> members;
  final int initialSelectedIndex;

  const SharingSettingsSheet({
    super.key,
    required this.members,
    this.initialSelectedIndex = 1,
  });

  @override
  State<SharingSettingsSheet> createState() => _SharingSettingsSheetState();
}

class _SharingSettingsSheetState extends State<SharingSettingsSheet> {
  late int selectedMemberIndex;
  final Map<String, String> roleDisplayMap = {
    '소유자': '소유자',
    '뷰어': '읽기 전용',
    '에디터': '편집 전용',
  };
  final Map<String, String> displayRoleToInternal = {
    '읽기 전용': '뷰어',
    '편집 전용': '에디터',
  };

  @override
  void initState() {
    super.initState();
    selectedMemberIndex = widget.initialSelectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 32),
      child: SizedBox(
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Spacer(flex: 3),
                const Text(
                  '공유',
                  style: TextStyle(fontSize: 24),
                ),
                const Spacer(flex: 2),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '완료',
                    style: TextStyle(
                      color: Color(0xFF61CFB2),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text('멤버', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: widget.members.length,
                itemBuilder: (context, index) {
                  final member = widget.members[index];
                  return GestureDetector(
                    onTap: member.isEditable
                        ? () => setState(() {
                      selectedMemberIndex = index;
                    })
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: selectedMemberIndex == index ? Colors.grey.shade100 : null,
                      child: _buildMemberTile(
                        imageUrl: member.imageUrl,
                        name: member.name,
                        email: member.email,
                        role: member.role,
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),
            if (widget.members[selectedMemberIndex].isEditable) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '권한 설정',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  DropdownButton<String>(
                    value: roleDisplayMap[widget.members[selectedMemberIndex].role] ?? '읽기 전용',
                    items: const [
                      DropdownMenuItem(value: '읽기 전용', child: Text('읽기 전용')),
                      DropdownMenuItem(value: '편집 전용', child: Text('편집 전용')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        widget.members[selectedMemberIndex].role = displayRoleToInternal[value] ?? '뷰어';
                      });
                    },
                  ),
                ],
              ),
            ] else
              const Text('권한 설정이 불가능한 멤버입니다.'),
            const SizedBox(height: 24),
            const SizedBox(height: 12),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Clipboard.setData(const ClipboardData(text: 'https://nota.page/abc123'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('링크가 복사되었습니다.')),
                );
              },
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/Button.svg',
                  width: 250,
                  height: 72,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile({
    required String imageUrl,
    required String name,
    required String email,
    required String role,
  }) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(imageUrl),
          radius: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(email, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        Text(
          role,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}