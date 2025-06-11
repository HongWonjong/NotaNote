import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum SortOption { dateDesc, dateAsc, titleAsc }

class SettingsMenu extends StatefulWidget {
  final bool isGrid;
  final SortOption sortOption;
  final Function(SortOption) onSortChanged;
  final Function() onDeleteModeStart;
  final Function() onRename;
  final Function() onSharingSettingsToggle;
  final Function(bool) onGridToggle;

  const SettingsMenu({
    super.key,
    required this.isGrid,
    required this.sortOption,
    required this.onSortChanged,
    required this.onDeleteModeStart,
    required this.onRename,
    required this.onSharingSettingsToggle,
    required this.onGridToggle,
  });

  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  // 내부 role <-> 사용자 표시 텍스트 매핑
  final Map<String, String> roleDisplayMap = {
    '소유자': '소유자',
    '뷰어': '읽기 전용',
    '에디터': '편집 전용',
  };

  // 사용자 표시 텍스트 -> 내부 role 변환
  final Map<String, String> displayRoleToInternal = {
    '읽기 전용': '뷰어',
    '편집 전용': '에디터',
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert),
      tooltip: '설정 메뉴',
      onSelected: (value) {
        switch (value) {
          case 1:
            widget.onGridToggle(!widget.isGrid);
            break;
          case 2:
            _showSortOptionsDialog();
            break;
          case 3:
            _showSharingSettings();
            break;
          case 4:
            widget.onRename();
            break;
          case 5:
            widget.onDeleteModeStart();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 1,
          child: ListTile(
            leading: Icon(widget.isGrid ? Icons.list : Icons.grid_view),
            title: Text(widget.isGrid ? '목록으로 보기' : '그리드로 보기'),
          ),
        ),
        const PopupMenuItem(
          value: 2,
          child: ListTile(
            leading: Icon(Icons.swap_vert),
            title: Text('정렬'),
          ),
        ),
        const PopupMenuItem(
          value: 3,
          child: ListTile(
            leading: Icon(Icons.share),
            title: Text('공유'),
          ),
        ),
        PopupMenuItem(
          value: 4,
          child: ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('이름변경'),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 5,
          child: ListTile(
            leading: Image.asset(
              'assets/trash_icon.png',
              width: 24,
              height: 24,
              color: Colors.red,
            ),
            title: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  void _showSortOptionsDialog() {
    SortOption tempSelectedOption = widget.sortOption;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              height: 300,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
  children: [
    const Spacer(flex: 3),
    const Text(
      '정렬 기준',
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
    ),
    const Spacer(flex: 2),
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text(
        '확인',
        style: TextStyle(color: Color(0xFF61CFB2)),
      ),
    ),
  ],
),
                    const SizedBox(height: 8),
                    const Divider(),
                    ...SortOption.values.map((option) {
                      String label;
                      switch (option) {
                        case SortOption.dateDesc:
                          label = '수정일';
                          break;
                        case SortOption.dateAsc:
                          label = '생성일';
                          break;
                        case SortOption.titleAsc:
                          label = '제목';
                          break;
                      }

                      final isSelected = tempSelectedOption == option;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF61CFB2) : Colors.black,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? SvgPicture.asset(
                                'assets/Check.svg',
                                width: 20,
                                height: 20,
                                colorFilter: const ColorFilter.mode(Color(0xFF61CFB2), BlendMode.srcIn),
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            tempSelectedOption = option;
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSharingSettings() {
  List<Member> members = [
    Member(
      name: '홍길동',
      email: 'owner@example.com',
      imageUrl: 'https://i.pravatar.cc/150?img=3',
      role: '소유자',
      isEditable: false,
    ),
    Member(
      name: '김영희',
      email: 'viewer@example.com',
      imageUrl: 'https://i.pravatar.cc/150?img=5',
      role: '뷰어',
      isEditable: true,
    ),
    Member(
      name: '박철수',
      email: 'editor@example.com',
      imageUrl: 'https://i.pravatar.cc/150?img=8',
      role: '에디터',
      isEditable: true,
    ),
  ];

  int selectedMemberIndex = 1;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
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
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
    ),
    const Spacer(flex: 2),
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text(
        '확인',
        style: TextStyle(color: Color(0xFF61CFB2)),
      ),
    ),
  ],
),
                const SizedBox(height: 16),
                // 멤버 목록
                const Divider(),
                const Text('멤버', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
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
                if (members[selectedMemberIndex].isEditable) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                  const Text(
                  '권한 설정',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DropdownButton<String>(
          value: roleDisplayMap[members[selectedMemberIndex].role],
          style: const TextStyle(color: Colors.black),
          onChanged: (String? newDisplayRole) {
            if (newDisplayRole != null) {
              setState(() {
                members[selectedMemberIndex].role =
                    displayRoleToInternal[newDisplayRole]!;
              });
            }
          },
          items: ['읽기 전용', '편집 전용'].map((String displayText) {
            return DropdownMenuItem<String>(
              value: displayText,
              child: Text(displayText),
            );
          }).toList(),
          underline: Container(),
          icon: const Icon(Icons.arrow_drop_down),
          dropdownColor: Colors.white,
        ),
      ),
    ],
  ),
  const SizedBox(height: 24),
                ],
                // 링크 공유하기 버튼
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    icon: const Icon(Icons.link),
                    label: const Text('링크 공유하기'),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: 'https://example.com/memo_group_link'));
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('링크가 클립보드에 복사되었습니다.')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      });
    },
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
        CircleAvatar(radius: 20, backgroundImage: NetworkImage(imageUrl)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        Text(role, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class Member {
  String name;
  String email;
  String imageUrl;
  String role;
  bool isEditable;

  Member({
    required this.name,
    required this.email,
    required this.imageUrl,
    required this.role,
    required this.isEditable,
  });
}
