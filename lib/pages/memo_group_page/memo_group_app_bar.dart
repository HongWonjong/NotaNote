import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/models/sort_options.dart';
import 'popup_menu.dart'; // SettingsMenu

class MemoGroupAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String groupId;
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
  final Function(String) onSearchChanged;
  final String role; // role 추가

  const MemoGroupAppBar({
    super.key,
    required this.groupId,
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
    required this.onSearchChanged,
    this.selectedDeleteCount = 0,
    this.onDeletePressed,
    required this.role, // role 추가
  });

  @override
  Size get preferredSize => const Size.fromHeight(92);

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/CaretLeft.svg',
              width: 24, height: 24, color: Colors.black),
          onPressed: onCancelSearch,
        ),
        title: _SearchField(
            controller: searchController, onChanged: onSearchChanged),
        bottom: _buildCountText(memoCount),
      );
    }

    return AppBar(
      title: Text(groupName),
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0,
      elevation: 0,
      leading: isDeleteMode
          ? TextButton(
              onPressed: onCancelDelete,
              child: const Text('완료',
                  style: TextStyle(color: Colors.black, fontSize: 16)),
            )
          : IconButton(
              icon: SvgPicture.asset('assets/icons/CaretLeft.svg',
                  width: 24, height: 24, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
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
                icon: SvgPicture.asset('assets/icons/MagnifyingGlass.svg',
                    width: 24, height: 24, color: Colors.black),
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
                groupId: groupId,
                groupTitle: groupName,
                role: role, // role 전달
              ),
            ],
      bottom: _buildCountText(memoCount),
    );
  }

  PreferredSizeWidget _buildCountText(int count) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text('총 $count개', style: const TextStyle(fontSize: 18)),
          ),
          const Divider(
              height: 1,
              thickness: 1,
              indent: 0,
              endIndent: 0,
              color: Color(0x1A000000)),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
          color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/MagnifyingGlass.svg',
              width: 20, height: 20, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: widget.controller,
              autofocus: true,
              cursorColor: Colors.black,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: '제목, 해시태그를 검색해주세요',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: widget.onChanged,
            ),
          ),
          if (widget.controller.text.isNotEmpty) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                widget.controller.clear();
                widget.onChanged('');
              },
              child: SvgPicture.asset('assets/icons/Vector.svg',
                  width: 18, height: 18, color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
  }
}
