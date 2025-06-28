import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/models/member.dart';
import 'package:nota_note/viewmodels/sharing_settings_viewmodel.dart';

class SharingSettingsSheet extends StatefulWidget {
  final List<Member> members;
  final int initialSelectedIndex;
  final String groupId;

  const SharingSettingsSheet({
    super.key,
    required this.members,
    required this.groupId,
    this.initialSelectedIndex = 0,
  });

  @override
  State<SharingSettingsSheet> createState() => _SharingSettingsSheetState();
}

class _SharingSettingsSheetState extends State<SharingSettingsSheet> {
  late int selectedMemberIndex;
  final Map<String, String> roleDisplayMap = {
    'owner': '소유자',
    'guest': '읽기 전용',
    'editor': '편집 전용',
  };
  final Map<String, String> displayRoleToInternal = {
    '읽기 전용': 'guest',
    '편집 전용': 'editor',
  };

  final TextEditingController _hashTagController = TextEditingController();
  String _selectedInviteRole = 'guest'; // Default role for invitation

  @override
  void initState() {
    super.initState();
    // Safely set selectedMemberIndex based on members list length
    selectedMemberIndex = widget.members.isNotEmpty
        ? widget.initialSelectedIndex.clamp(0, widget.members.length - 1)
        : 0;
  }

  @override
  void dispose() {
    _hashTagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 32),
      child: SizedBox(
        height: 720,
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
              child: widget.members.isEmpty
                  ? const Center(child: Text('소유자 정보가 없습니다.'))
                  : ListView.builder(
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
                        hashTag: member.hashTag,
                        role: member.role,
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),
            if (widget.members.isNotEmpty && widget.members[selectedMemberIndex].isEditable) ...[
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
                    onChanged: (value) async {
                      if (value == null) return;
                      final newRole = displayRoleToInternal[value] ?? 'guest';
                      final viewModel = SharingSettingsViewModel(groupId: widget.groupId);
                      final userId = await _getUserIdFromHashTag(widget.members[selectedMemberIndex].hashTag);
                      if (userId != null) {
                        final success = await viewModel.updateMemberRole(userId, newRole);
                        if (success) {
                          setState(() {
                            widget.members[selectedMemberIndex].role = newRole;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('권한이 변경되었습니다.')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('권한 변경에 실패했습니다.')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('사용자를 찾을 수 없습니다.')),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            // Invite Member Section
            const Text('멤버 초대', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 8),
            TextField(
              controller: _hashTagController,
              decoration: const InputDecoration(
                labelText: '해시태그 (예: #username)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '역할 선택',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                DropdownButton<String>(
                  value: _selectedInviteRole,
                  items: const [
                    DropdownMenuItem(value: 'guest', child: Text('읽기 전용')),
                    DropdownMenuItem(value: 'editor', child: Text('편집 전용')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedInviteRole = value;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: () async {
                  final hashTag = _hashTagController.text.trim();
                  if (hashTag.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('해시태그를 입력해주세요.')),
                    );
                    return;
                  }
                  final viewModel = SharingSettingsViewModel(groupId: widget.groupId);
                  final success = await viewModel.inviteMember(hashTag, _selectedInviteRole);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('초대가 완료되었습니다.')),
                    );
                    _hashTagController.clear();
                    // Refresh members list
                    final updatedMembers = await viewModel.getMembers();
                    setState(() {
                      widget.members.clear();
                      widget.members.addAll(updatedMembers);
                      selectedMemberIndex = widget.members.isNotEmpty ? 0 : 0;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('초대 실패: 사용자를 찾을 수 없습니다.')),
                    );
                  }
                },
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

  // Helper method to get userId from hashTag
  Future<String?> _getUserIdFromHashTag(String hashTag) async {
    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('hashTag', isEqualTo: hashTag)
          .limit(1)
          .get();
      if (userQuery.docs.isNotEmpty) {
        return userQuery.docs.first.id;
      }
      return null;
    } catch (e) {
      print('Error fetching userId for hashTag $hashTag: $e');
      return null;
    }
  }

  Widget _buildMemberTile({
    required String imageUrl,
    required String name,
    required String hashTag,
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
              Text(hashTag, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        Text(
          roleDisplayMap[role] ?? role,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}