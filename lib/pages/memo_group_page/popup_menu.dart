import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/models/sort_options.dart';
import 'package:nota_note/widgets/dialogs/rename_group_dialog.dart';
import 'sharing_settings_sheet.dart';
import 'package:nota_note/viewmodels/sharing_settings_viewmodel.dart';

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
  final String role;

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
    required this.role,
  });

  @override
  ConsumerState<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends ConsumerState<SettingsMenu> {
  @override
  Widget build(BuildContext context) {
    final isOwnerOrEditor = widget.role == 'owner' || widget.role == 'editor';

    return PopupMenuButton<int>(
      icon: Padding(
        padding: EdgeInsets.only(right: 20),
    child: SvgPicture.asset('assets/icons/DotsThreeCircle.svg', width: 24, height: 24),
      ),
      tooltip: '설정 메뉴',
      color: const Color(0xFFF5F5F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, 40),
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 220, maxHeight: 300),
      onSelected: (value) {
        switch (value) {
          case 1:
            widget.onGridToggle(!widget.isGrid);
            break;
          case 2:
            _showSortOptionsDialog();
            break;
          case 3:
            if (widget.role == 'owner') _showSharingSettings();
            break;
          case 4:
            if (widget.role == 'owner') {
              showRenameGroupBottomSheet(
                context: context,
                ref: ref,
                groupId: widget.groupId,
                currentTitle: widget.groupTitle,
              );
            }
            break;
          case 5:
            if (isOwnerOrEditor) widget.onDeleteModeStart();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              SvgPicture.asset(
                widget.isGrid ? 'assets/icons/ListDashes.svg' : 'assets/icons/GridFour.svg',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 12),
              Text(widget.isGrid ? '목록으로 보기' : '그리드로 보기'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              SvgPicture.asset('assets/icons/ArrowsDownUp.svg', width: 24, height: 24),
              const SizedBox(width: 12),
              const Text('정렬'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 3,
          enabled: widget.role == 'owner',
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/Share.svg',
                width: 24,
                height: 24,
                color: widget.role == 'owner' ? null : Colors.grey,
              ),
              const SizedBox(width: 12),
              Text(
                '공유',
                style: TextStyle(color: widget.role == 'owner' ? Colors.black : Colors.grey),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 4,
          enabled: widget.role == 'owner',
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/PencilSimple.svg',
                width: 24,
                height: 24,
                color: widget.role == 'owner' ? null : Colors.grey,
              ),
              const SizedBox(width: 12),
              Text(
                '이름변경',
                style: TextStyle(color: widget.role == 'owner' ? Colors.black : Colors.grey),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 5,
          enabled: isOwnerOrEditor,
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/Delete.svg',
                width: 24,
                height: 24,
                color: isOwnerOrEditor ? Colors.red : Colors.grey,
              ),
              const SizedBox(width: 12),
              Text(
                '삭제',
                style: TextStyle(color: isOwnerOrEditor ? Colors.red : Colors.grey),
              ),
            ],
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
                        const Text('정렬 기준', style: TextStyle(fontSize: 24)),
                        const Spacer(flex: 2),
                        TextButton(
                          onPressed: () {
                            widget.onSortChanged(tempSelectedOption);
                            Navigator.pop(context);
                          },
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
                    const SizedBox(height: 8),
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

  void _showSharingSettings() async {
    final viewModel = SharingSettingsViewModel(groupId: widget.groupId);
    final members = await viewModel.getMembers();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SharingSettingsSheet(
          groupId: widget.groupId,
          members: members,
          initialSelectedIndex: members.isNotEmpty ? 1 : 0,
        );
      },
    );
  }
}