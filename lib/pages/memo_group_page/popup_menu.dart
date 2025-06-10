// popup_menu.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sort_option.dart';

enum SortOption { dateDesc, dateAsc, titleAsc }

class SettingsMenu extends StatefulWidget {
  final bool isGrid;
  final SortOption sortOption;
  final Function(SortOption) onSortChanged;
  final Function() onDeleteModeStart;
  final Function() onRename;
  final Function() onEditGroup;
  final Function() onSharingSettingsToggle;
  final Function(bool) onGridToggle;

  const SettingsMenu({
    super.key,
    required this.isGrid,
    required this.sortOption,
    required this.onSortChanged,
    required this.onDeleteModeStart,
    required this.onRename,
    required this.onEditGroup,
    required this.onSharingSettingsToggle,
    required this.onGridToggle,
  });

  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert),
      tooltip: '설정 메뉴',
      onSelected: (value) {
        switch (value) {
          case 1:
            _showSharingSettings();
            break;
          case 2:
            _showSortOptionsDialog();
            break;
          case 3:
            widget.onDeleteModeStart();
            break;
          case 4:
            widget.onRename();
            break;
          case 5:
            widget.onEditGroup();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 1,
          child: ListTile(leading: Icon(Icons.share), title: Text('공유')),
        ),
        const PopupMenuItem(
          value: 2,
          child: ListTile(leading: Icon(Icons.sort), title: Text('정렬')),
        ),
        PopupMenuItem(
          enabled: false,
          child: GestureDetector(
            onTap: () {
              widget.onGridToggle(!widget.isGrid);
              Navigator.of(context).pop();
            },
            child: Row(
              children: [
                Icon(widget.isGrid ? Icons.view_list : Icons.grid_view),
                const SizedBox(width: 8),
                Text(widget.isGrid ? '목록으로 보기' : '그리드로 보기'),
              ],
            ),
          ),
        ),
        const PopupMenuItem(
          value: 3,
          child: ListTile(leading: Icon(Icons.delete), title: Text('삭제')),
        ),
        const PopupMenuItem(
          value: 4,
          child: ListTile(leading: Icon(Icons.edit), title: Text('이름변경')),
        ),
        const PopupMenuItem(
          value: 5,
          child: ListTile(leading: Icon(Icons.settings), title: Text('그룹수정')),
        ),
      ],
    );
  }

  void _showSharingSettings() {
    showDialog(
      context: context,
      builder: (context) {
        bool canRead = true;
        bool canEdit = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('공유 설정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: const [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=3'),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('user@example.com', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('소유자', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  CheckboxListTile(
                    title: const Text('읽기 전용'),
                    value: canRead,
                    onChanged: (value) {
                      setState(() {
                        canRead = value ?? false;
                        if (!canRead) {
                          canEdit = false;
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('편집 전용'),
                    value: canEdit,
                    onChanged: canRead
                        ? (value) {
                            setState(() {
                              canEdit = value ?? false;
                            });
                          }
                        : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.link),
                    label: const Text('링크 복사'),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: 'https://example.com/memo_group_link'));
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('링크가 클립보드에 복사되었습니다.')),
                      );
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
                TextButton(
                  onPressed: () {
                    // TODO: 권한 저장 로직 구현 가능
                    Navigator.pop(context);
                  },
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSortOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('정렬 기준 선택'),
          children: SortOption.values.map((option) {
            String label;
            switch (option) {
              case SortOption.dateDesc:
                label = '최신순';
                break;
              case SortOption.dateAsc:
                label = '오래된순';
                break;
              case SortOption.titleAsc:
                label = '제목순';
                break;
            }
            return RadioListTile<SortOption>(
              title: Text(label),
              value: option,
              groupValue: widget.sortOption,
              onChanged: (value) {
                if (value != null) {
                  widget.onSortChanged(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        );
      },
    );
  }
}
