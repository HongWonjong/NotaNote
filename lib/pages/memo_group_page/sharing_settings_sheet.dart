import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
    'guest': '열람자',
    'editor': '편집자',
    'guest_waiting': '열람자 (대기 중)',
    'editor_waiting': '편집자 (대기 중)',
  };
  final Map<String, String> displayRoleToInternal = {
    '열람자': 'guest',
    '편집자': 'editor',
  };

  final TextEditingController _hashTagController = TextEditingController();
  String _selectedInviteRole = 'guest';
  bool _hasHashTagInput = false;

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
    _hashTagController.addListener(_updateButtonText);
  }

  @override
  void dispose() {
    _hashTagController.removeListener(_updateButtonText);
    _hashTagController.dispose();
    super.dispose();
  }

  void _updateButtonText() {
    setState(() {
      _hasHashTagInput = _hashTagController.text.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단바: 공유 타이틀과 초대/완료 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Spacer(),
                const Text(
                  '공유',
                  style: TextStyle(
                    color: Color(0xFF191919),
                    fontSize: 18,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    if (_hasHashTagInput) {
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
                      final viewModel = SharingSettingsViewModel(groupId: widget.groupId);
                      final success = await viewModel.inviteMember(hashTag, _selectedInviteRole, currentUserId);
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
                            content: Text('초대 실패: 사용자를 찾을 수 없거나 이미 초대된 사용자입니다.'),
                          ),
                        );
                      }
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    _hasHashTagInput ? '초대하기' : '완료',
                    style: const TextStyle(
                      color: Color(0xFF60CFB1),
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 멤버 추가 섹션
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '멤버 추가',
                  style: TextStyle(
                    color: Color(0xFF191919),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(width: 1, color: Color(0xFFB3B3B3)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: TextField(
                          controller: _hashTagController,
                          decoration: const InputDecoration(
                            hintText: '초대태그를 입력해주세요',
                            hintStyle: TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 14,
                              fontFamily: 'Pretendard',
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    DropdownButton<String>(
                      dropdownColor: Colors.white,
                      value: _selectedInviteRole,
                      items: const [
                        DropdownMenuItem(
                          value: 'guest',
                          child: Text(
                            '읽기 권한',
                            style: TextStyle(
                              color: Color(0xFF4C4C4C),
                              fontSize: 14,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'editor',
                          child: Text(
                            '편집 권한',
                            style: TextStyle(
                              color: Color(0xFF4C4C4C),
                              fontSize: 14,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedInviteRole = value;
                          });
                        }
                      },
                      style: const TextStyle(
                        color: Color(0xFF4C4C4C),
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                      ),
                      underline: const SizedBox(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 멤버 목록 섹션
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '멤버',
                      style: TextStyle(
                        color: Color(0xFF191919),
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${members.length}명',
                      style: const TextStyle(
                        color: Color(0xFF2F9C7F),
                        fontSize: 12,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(
            child: members.isEmpty
                ? const Center(child: Text('소유자 정보가 없습니다.'))
                : ListView.builder(
              physics: const ClampingScrollPhysics(),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(width: 1, color: Color(0xFFF0F0F0)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 멤버 정보
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: member.imageUrl.isNotEmpty
                                ? NetworkImage(member.imageUrl)
                                : null,
                            backgroundColor: _getAvatarColor(index),
                            child: member.imageUrl.isEmpty
                                ? const Icon(Icons.person, size: 18, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<String?>(
                                future: _userId,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Text(
                                      member.name,
                                      style: TextStyle(
                                        color: const Color(0xFF191919),
                                        fontSize: 16,
                                        fontFamily: 'Pretendard',
                                        fontWeight: member.role == 'owner' ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    );
                                  }
                                  final currentUserId = snapshot.data;
                                  return FutureBuilder<DocumentSnapshot>(
                                    future: currentUserId != null
                                        ? FirebaseFirestore.instance.collection('users').doc(currentUserId).get()
                                        : Future.value(null),
                                    builder: (context, userSnapshot) {
                                      final currentUserHashTag = userSnapshot.data?.get('hashTag') as String?;
                                      final isCurrentUser = currentUserHashTag != null && member.hashTag == currentUserHashTag;
                                      return Text(
                                        member.name + (isCurrentUser ? ' (나)' : ''),
                                        style: TextStyle(
                                          color: const Color(0xFF191919),
                                          fontSize: 16,
                                          fontFamily: 'Pretendard',
                                          fontWeight: member.role == 'owner' ? FontWeight.bold : FontWeight.w500,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      // 권한 및 액션
                      Row(
                        children: [
                          if (member.role == 'owner')
                            Text(
                              roleDisplayMap[member.role] ?? member.role,
                              style: const TextStyle(
                                color: Color(0xFF191919),
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          if (member.role.contains('waiting'))
                            GestureDetector(
                              onTap: () async {
                                final viewModel = SharingSettingsViewModel(
                                    groupId: widget.groupId);
                                final userId = await _getUserIdFromHashTag(
                                    member.hashTag);
                                if (userId != null) {
                                  final success = await viewModel
                                      .cancelInvitation(userId);
                                  if (success) {
                                    setState(() {
                                      members.removeAt(index);
                                      selectedMemberIndex = members.isNotEmpty
                                          ? selectedMemberIndex.clamp(
                                          0, members.length - 1)
                                          : 0;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('초대가 취소되었습니다.')),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('초대 취소에 실패했습니다.')),
                                    );
                                  }
                                }
                              },
                              child: Row(
                                children: [
                                  const Text(
                                    '수락 대기중',
                                    style: TextStyle(
                                      color: Color(0xFF191919),
                                      fontSize: 14,
                                      fontFamily: 'Pretendard',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                      Icons.close, color: Colors.red, size: 24),
                                ],
                              ),
                            )
                          else if (member.role == 'editor' || member.role == 'guest')
                            DropdownButton<String>(
                              dropdownColor: Colors.white,
                              value: roleDisplayMap[member.role] ?? '열람자',
                              items: const [
                                DropdownMenuItem(value: '열람자', child: Text('열람자')),
                                DropdownMenuItem(value: '편집자', child: Text('편집자')),
                              ],
                              onChanged: (value) async {
                                if (value == null) return;
                                final newRole = displayRoleToInternal[value] ?? 'guest';
                                final viewModel = SharingSettingsViewModel(groupId: widget.groupId);
                                final userId = await _getUserIdFromHashTag(member.hashTag);
                                if (userId != null) {
                                  final success = await viewModel.updateMemberRole(userId, newRole);
                                  if (success) {
                                    setState(() {
                                      members[index] = Member(
                                        name: member.name,
                                        hashTag: member.hashTag,
                                        imageUrl: member.imageUrl,
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
                              style: const TextStyle(
                                color: Color(0xFF191919),
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                              ),
                              underline: const SizedBox(),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
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

  Color _getAvatarColor(int index) {
    const colors = [
      Color(0xFFB0E7D8),
      Color(0xFFCAE7B0),
      Color(0xFFE7CBB0),
    ];
    return colors[index % colors.length];
  }
}