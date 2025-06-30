import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/models/member.dart';
import 'package:nota_note/viewmodels/sharing_settings_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late List<Member> members;
  final Map<String, String> roleDisplayMap = {
    'owner': '소유자',
    'guest': '읽기 전용',
    'editor': '편집 전용',
    'guest_waiting': '읽기 전용 (대기 중)',
    'editor_waiting': '편집 전용 (대기 중)',
  };
  final Map<String, String> displayRoleToInternal = {
    '읽기 전용': 'guest',
    '편집 전용': 'editor',
  };

  final TextEditingController _hashTagController = TextEditingController();
  String _selectedInviteRole = 'guest';

  Future<String?> get _userId async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  @override
  void initState() {
    super.initState();
    members = List.from(widget.members);
    selectedMemberIndex = members.isNotEmpty
        ? widget.initialSelectedIndex.clamp(0, members.length - 1)
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
            const Text('멤버',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 20),
            Expanded(
              child: members.isEmpty
                  ? const Center(child: Text('소유자 정보가 없습니다.'))
                  : ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (member.role == 'owner') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('소유자는 선택할 수 없습니다.')),
                              );
                              return;
                            }
                            print(
                                'Tapped member: ${member.name}, index: $index, role: ${member.role}');
                            setState(() {
                              selectedMemberIndex = index;
                              print(
                                  'Updated selectedMemberIndex: $selectedMemberIndex');
                            });
                          },
                          child: Container(
                            key: ValueKey(member.hashTag),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 8),
                            color: selectedMemberIndex == index
                                ? Colors.grey.shade100
                                : null,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildMemberTile(
                                    imageUrl: member.imageUrl,
                                    name: member.name,
                                    hashTag: member.hashTag,
                                    role: member.role,
                                  ),
                                ),
                                if (member.role.contains('waiting'))
                                  SizedBox(
                                    width: 48,
                                    child: IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.red),
                                      onPressed: () async {
                                        final viewModel =
                                            SharingSettingsViewModel(
                                                groupId: widget.groupId);
                                        final userId =
                                            await _getUserIdFromHashTag(
                                                member.hashTag);
                                        if (userId != null) {
                                          final success = await viewModel
                                              .cancelInvitation(userId);
                                          if (success) {
                                            setState(() {
                                              members.removeAt(index);
                                              selectedMemberIndex = members
                                                      .isNotEmpty
                                                  ? selectedMemberIndex.clamp(
                                                      0, members.length - 1)
                                                  : 0;
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content:
                                                      Text('초대가 취소되었습니다.')),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content:
                                                      Text('초대 취소에 실패했습니다.')),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  )
                                else if (member.role == 'editor' ||
                                    member.role == 'guest')
                                  SizedBox(
                                    width: 48,
                                    child: IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.redAccent),
                                      onPressed: () async {
                                        // 확인 다이얼로그 표시
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('멤버 탈퇴'),
                                            content: Text(
                                                '${member.name}을(를) 그룹에서 탈퇴시키겠습니까?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text('취소'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: const Text('탈퇴',
                                                    style: TextStyle(
                                                        color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          final viewModel =
                                              SharingSettingsViewModel(
                                                  groupId: widget.groupId);
                                          final userId =
                                              await _getUserIdFromHashTag(
                                                  member.hashTag);
                                          if (userId != null) {
                                            final success = await viewModel
                                                .removeMember(userId);
                                            if (success) {
                                              setState(() {
                                                members.removeAt(index);
                                                selectedMemberIndex = members
                                                        .isNotEmpty
                                                    ? selectedMemberIndex.clamp(
                                                        0, members.length - 1)
                                                    : 0;
                                              });
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content:
                                                        Text('멤버가 탈퇴되었습니다.')),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content:
                                                        Text('멤버 탈퇴에 실패했습니다.')),
                                              );
                                            }
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content:
                                                      Text('사용자를 찾을 수 없습니다.')),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),
            const SizedBox(height: 16),
            if (members.isNotEmpty &&
                members[selectedMemberIndex].role != 'owner') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '권한 설정',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  DropdownButton<String>(
                    value: roleDisplayMap[members[selectedMemberIndex]
                                .role
                                .contains('waiting')
                            ? displayRoleToInternal[roleDisplayMap[
                                    members[selectedMemberIndex].role]] ??
                                'guest'
                            : members[selectedMemberIndex].role] ??
                        '읽기 전용',
                    items: const [
                      DropdownMenuItem(value: '읽기 전용', child: Text('읽기 전용')),
                      DropdownMenuItem(value: '편집 전용', child: Text('편집 전용')),
                    ],
                    onChanged: (value) async {
                      if (value == null) return;
                      final newRole = displayRoleToInternal[value] ?? 'guest';
                      final viewModel =
                          SharingSettingsViewModel(groupId: widget.groupId);
                      final userId = await _getUserIdFromHashTag(
                          members[selectedMemberIndex].hashTag);
                      if (userId != null) {
                        final success =
                            await viewModel.updateMemberRole(userId, newRole);
                        if (success) {
                          setState(() {
                            members[selectedMemberIndex] = Member(
                              name: members[selectedMemberIndex].name,
                              hashTag: members[selectedMemberIndex].hashTag,
                              imageUrl: members[selectedMemberIndex].imageUrl,
                              role: newRole,
                              isEditable: true,
                            );
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
            const Text('멤버 초대',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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
                  final currentUserId = await _userId;
                  if (currentUserId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('현재 사용자 정보를 가져올 수 없습니다.')),
                    );
                    return;
                  }
                  final viewModel =
                      SharingSettingsViewModel(groupId: widget.groupId);
                  final success = await viewModel.inviteMember(
                      hashTag, _selectedInviteRole, currentUserId);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('초대가 완료되었습니다.')),
                    );
                    _hashTagController.clear();
                    final updatedMembers = await viewModel.getMembers();
                    setState(() {
                      members.clear();
                      members.addAll(updatedMembers);
                      selectedMemberIndex = members.isNotEmpty ? 0 : 0;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('초대 실패: 사용자를 찾을 수 없거나 이미 초대된 사용자입니다.')),
                    );
                  }
                },
                child: SvgPicture.asset(
                  'assets/icons/MemberInviteButton.svg',
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
          radius: 20,
          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
          child: imageUrl.isEmpty
              ? const Icon(Icons.person, size: 20, color: Colors.grey)
              : null,
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
