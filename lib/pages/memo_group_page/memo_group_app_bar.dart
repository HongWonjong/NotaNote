import 'package:flutter/material.dart';
import 'popup_menu.dart'; // 수정한 SettingsMenu
import 'package:nota_note/models/sort_options.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MemoGroupAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String groupId;      // 그룹 ID 추가
  final String groupName;

  final bool isSearching;
  final bool isDeleteMode;
  final int memoCount;
  final TextEditingController searchController;
  final VoidCallback onCancelSearch;
  final VoidCallback onSearchPressed;
  final VoidCallback onCancelDelete;

  final bool isGrid;
  final SortOption sortOption;
  final Function(SortOption) onSortChanged;
  final VoidCallback onDeleteModeStart;
  final VoidCallback onRename;
  final VoidCallback onEditGroup;
  final VoidCallback onSharingSettingsToggle;
  final Function(bool) onGridToggle;

  final int selectedDeleteCount;
  final VoidCallback? onDeletePressed;

  final Function(String) onSearchChanged;  // 추가: 검색어 변경 콜백

  const MemoGroupAppBar({
    super.key,
    required this.groupId,           // 생성자에 추가
    required this.groupName,
    required this.isSearching,
    required this.isDeleteMode,
    required this.memoCount,
    required this.searchController,
    required this.onCancelSearch,
    required this.onSearchPressed,
    required this.onCancelDelete,
    required this.isGrid,
    required this.sortOption,
    required this.onSortChanged,
    required this.onDeleteModeStart,
    required this.onRename,
    required this.onEditGroup,
    required this.onSharingSettingsToggle,
    required this.onGridToggle,
    required this.onSearchChanged,  // 생성자에 포함
    this.selectedDeleteCount = 0,
    this.onDeletePressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(92);

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: onCancelSearch,
        ),
        title: _SearchField(
          controller: searchController,
          onChanged: onSearchChanged,  // 변경 콜백 연결
        ),
        bottom: _buildCountText(memoCount),
      );
    }

    return AppBar(
      title: Text(groupName),
      leading: isDeleteMode
    ? TextButton(
        onPressed: onCancelDelete,
        child: const Text(
          '완료',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
        ),
      )
    : null,
      actions: isDeleteMode
          ? [
              TextButton(
                onPressed: selectedDeleteCount > 0 ? onDeletePressed : null,
                child: Text(
                  '삭제',
                  style: TextStyle(
                    color: selectedDeleteCount > 0 ? Colors.red : Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]
          : [
              IconButton(
  icon: SvgPicture.asset(
    'assets/icons/MagnifyingGlass.svg',
    width: 24,
    height: 24,
    color: Colors.black, // 색상 필요시 적용
  ),
  onPressed: onSearchPressed,
),
              SettingsMenu(
                isGrid: isGrid,
                sortOption: sortOption,
                onSortChanged: onSortChanged,
                onDeleteModeStart: onDeleteModeStart,
                onRename: onRename,
                onSharingSettingsToggle: onSharingSettingsToggle,
                onGridToggle: onGridToggle,
                groupId: groupId,         // 수정된 부분
                groupTitle: groupName,    // 수정된 부분
              ),
            ],
      bottom: _buildCountText(memoCount),
    );
  }

  PreferredSizeWidget _buildCountText(int count) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(24),
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16, bottom: 8),
        child: Text('총 $count개', style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;  // 추가: onChanged 콜백

  const _SearchField({
    Key? key,
    required this.controller,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/MagnifyingGlass.svg', // 경로 확인!
            width: 20,
            height: 20,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              cursorColor: Colors.black,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: '제목, 해시태그를 검색해주세요',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: onChanged,  // 입력 변경 콜백 연결
            ),
          ),
        ],
      ),
    );
  }
}
