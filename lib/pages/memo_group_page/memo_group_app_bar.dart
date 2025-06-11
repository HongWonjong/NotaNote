import 'package:flutter/material.dart';
import 'popup_menu.dart'; // SettingsMenu, SortOption 포함

class MemoGroupAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String groupName;  // 그룹 이름 추가

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

  const MemoGroupAppBar({
    super.key,
    required this.groupName,  // 추가
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
        title: _SearchField(controller: searchController),
        bottom: _buildCountText(memoCount),
      );
    }

    return AppBar(
      title: Text(groupName),  // 고정 텍스트 대신 그룹 이름 표시
      leading: isDeleteMode
          ? IconButton(icon: const Icon(Icons.close), onPressed: onCancelDelete)
          : null,
      actions: [
        if (isDeleteMode) ...[
          IconButton(
            icon: Icon(Icons.delete,
                color: selectedDeleteCount > 0 ? Colors.red : Colors.grey),
            onPressed: selectedDeleteCount > 0 ? onDeletePressed : null,
          )
        ] else ...[
          IconButton(icon: const Icon(Icons.search), onPressed: onSearchPressed),
          SettingsMenu(
            isGrid: isGrid,
            sortOption: sortOption,
            onSortChanged: onSortChanged,
            onDeleteModeStart: onDeleteModeStart,
            onRename: onRename,
            onSharingSettingsToggle: onSharingSettingsToggle,
            onGridToggle: onGridToggle,
          ),
        ],
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

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              cursorColor: Colors.black,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: '태그로 검색',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
