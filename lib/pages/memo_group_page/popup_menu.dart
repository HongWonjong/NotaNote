import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/sort_options.dart';
import 'package:nota_note/widgets/dialogs/rename_group_dialog.dart';

// 멤버 모델
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

// SettingsMenu 위젯
class SettingsMenu extends ConsumerStatefulWidget {
  final bool isGrid;
  final SortOption sortOption;
  final Function(SortOption) onSortChanged;
  final Function() onDeleteModeStart;
  final Function() onRename;
  final Function() onSharingSettingsToggle;
  final Function(bool) onGridToggle;
  final String groupId;
  final String groupTitle;

  const SettingsMenu({
    super.key,
    required this.isGrid,
    required this.sortOption,
    required this.onSortChanged,
    required this.onDeleteModeStart,
    required this.onRename,
    required this.onSharingSettingsToggle,
    required this.onGridToggle,
    required this.groupId,
    required this.groupTitle,
  });

  @override
  ConsumerState<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends ConsumerState<SettingsMenu> {
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
Widget build(BuildContext context) {
  return PopupMenuButton<int>(
    icon: SvgPicture.asset(
      'assets/icons/DotsThreeCircle.svg',
      width: 24,
      height: 24,
    ),
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
          showRenameGroupBottomSheet(
            context: context,
            ref: ref,
            groupId: widget.groupId,
            currentTitle: widget.groupTitle,
          );
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
          leading: SvgPicture.asset(
            widget.isGrid
                ? 'assets/icons/ListDashes.svg'
                : 'assets/icons/GridFour.svg',
            width: 24,
            height: 24,
          ),
          title: Text(widget.isGrid ? '목록으로 보기' : '그리드로 보기'),
        ),
      ),
      PopupMenuItem(
        value: 2,
        child: ListTile(
          leading: SvgPicture.asset(
            'assets/icons/ArrowsDownUp.svg',
            width: 24,
            height: 24,
          ),
          title: const Text('정렬'),
        ),
      ),
      PopupMenuItem(
        value: 3,
        child: ListTile(
          leading: SvgPicture.asset(
            'assets/icons/Share.svg',
            width: 24,
            height: 24,
          ),
          title: const Text('공유'),
        ),
      ),
      PopupMenuItem(
        value: 4,
        child: ListTile(
          leading: SvgPicture.asset(
            'assets/icons/PencilSimple.svg',
            width: 24,
            height: 24,
          ),
          title: const Text('이름변경'),
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: 5,
        child: ListTile(
          leading: SvgPicture.asset(
            'assets/icons/Delete.svg',
            width: 24,
            height: 24,
            color: Colors.red, // SVG가 색상 변경을 지원할 경우만 적용됨
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
                          onPressed: () {
                            widget.onSortChanged(tempSelectedOption);
                            Navigator.pop(context);
                          },
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
                        case SortOption.titleAsc:
                          label = '제목';
                          break;
                        case SortOption.dateAsc:
                          label = '생성일';
                          break;
                        case SortOption.dateDesc:
                          label = '최신순';
                          break;
                        default:
                          label = '알 수 없음';
                      }
                      if (label == '알 수 없음') return const SizedBox.shrink();

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
                                'assets/icons/Check.svg',
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
                    DropdownButton<String>(
                      value: roleDisplayMap[members[selectedMemberIndex].role] ?? '읽기 전용',
                      items: const [
                        DropdownMenuItem(value: '읽기 전용', child: Text('읽기 전용')),
                        DropdownMenuItem(value: '편집 전용', child: Text('편집 전용')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          members[selectedMemberIndex].role = displayRoleToInternal[value] ?? '뷰어';
                        });
                      },
                    ),
                  ],
                ),
              ] else
                const Text('권한 설정이 불가능한 멤버입니다.'),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              const Text('링크 공유', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              GestureDetector(
  onTap: () {
    Clipboard.setData(const ClipboardData(text: 'https://nota.page/abc123'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('링크가 복사되었습니다.')),
    );
  },
  child: Center(   // Center로 감싸기
    child: SvgPicture.asset(
      'assets/icons/Button.svg',
      width: 200,    // 적당한 고정 크기 지정
      height: 48,
      fit: BoxFit.contain,
    ),
  ),
)
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