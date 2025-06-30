import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/models/group_model.dart';
import 'package:nota_note/pages/main_page/widgets/main_item.dart';
import 'package:nota_note/pages/main_page/widgets/shared_main_item.dart';
import 'package:nota_note/pages/setting_page/settings_page.dart';
import 'package:nota_note/theme/colors.dart';
import 'package:nota_note/viewmodels/group_viewmodel.dart';
import 'package:nota_note/widgets/sliding_menu_scaffold.dart';
import 'package:nota_note/viewmodels/auth/auth_common.dart' hide userIdProvider;
import 'package:nota_note/viewmodels/auth/user_id_provider.dart';
import 'package:nota_note/pages/record_page/record_page.dart';
import 'package:nota_note/services/auth_service.dart';
import 'package:nota_note/pages/login_page/login_page.dart';
import 'package:nota_note/pages/memo_group_page/memo_group_page.dart';
import 'package:nota_note/providers/user_profile_provider.dart';
import 'package:nota_note/theme/pretendard_text_styles.dart';
import 'package:nota_note/services/notification_service.dart';
import 'package:nota_note/pages/notification_page/notification_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:nota_note/viewmodels/notification_viewmodel.dart';
import 'package:nota_note/viewmodels/memo_viewmodel.dart';
import 'package:nota_note/pages/memo_page/memo_page.dart';
import 'package:nota_note/models/role.dart';
import 'package:nota_note/models/shared_group_with_role.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage>
    with TickerProviderStateMixin {
  final SlidingMenuController _menuController = SlidingMenuController();
  bool _isGroupExpanded = false;
  String? _newGroupName;
  final TextEditingController _textController = TextEditingController();
  String? _currentUserId;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  bool _isFabOpen = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _searchController.addListener(_onSearchChanged);
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOut,
    );
  }

  void _onSearchChanged() {
    ref.read(groupViewModelProvider).searchGroups(_searchController.text);
  }

  Future<void> _loadUserInfo() async {
    final userId = await getCurrentUserId();

    if (userId != null) {
      setState(() {
        _currentUserId = userId;
      });

      ref.read(userIdProvider.notifier).state = userId;

      Future.microtask(() {
        final viewModel = ref.read(groupViewModelProvider);
        viewModel.updateExistingGroups().then((_) {
          viewModel.fetchGroupsWithNoteCounts();
        });
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인이 필요합니다. 로그인 페이지로 이동해주세요.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _textController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isFabOpen = !_isFabOpen;
      if (_isFabOpen) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

  void _showAddGroupDialog() {
    _textController.clear();
    _newGroupName = null;

    int textLength = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '새 그룹 만들기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (_newGroupName != null &&
                            _newGroupName!.isNotEmpty) {
                          ref
                              .read(groupViewModelProvider)
                              .createGroup(_newGroupName!);
                          _textController.clear();
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('그룹 이름을 입력하세요'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Text(
                        '완료',
                        style: TextStyle(
                          color: Color(0xFF61CFB2),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _textController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '그룹 이름',
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF61CFB2)),
                    ),
                    suffixText: '$textLength/25',
                    suffixStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                  onChanged: (value) {
                    setModalState(() {
                      textLength = value.length;
                    });
                    setState(() {
                      _newGroupName = value;
                    });
                  },
                  maxLength: 25,
                  buildCounter: (context,
                      {required currentLength, required isFocused, maxLength}) {
                    return null;
                  },
                ),
                SizedBox(height: 24),
              ],
            ),
          );
        });
      },
    );
  }

  void _handleLogout() async {
    final authService = ref.read(authServiceProvider);
    final success = await authService.logout(ref);

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그아웃 중 오류가 발생했습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showTestNotification() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알림을 전송하고 있습니다...'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.blue,
          ),
        );
      }

      await Future.delayed(Duration(milliseconds: 500));

      await NotificationService().showTestNotification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('테스트 알림이 전송되었습니다!'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF61CFB2),
          ),
        );
      }
    } catch (e) {
      debugPrint('알림 전송 오류: $e');
      if (mounted) {
        String errorMessage = '알림 전송 중 오류가 발생했습니다';

        if (e.toString().contains('permission')) {
          errorMessage = '알림 권한이 필요합니다. 설정에서 알림을 허용해주세요.';
        } else if (e.toString().contains('channel')) {
          errorMessage = '알림 채널 설정 오류가 발생했습니다.';
        } else {
          errorMessage = '알림 전송 중 오류가 발생했습니다: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupViewModel = ref.watch(groupViewModelProvider);
    final ownedGroups = groupViewModel.ownedGroups;
    final sharedGroupsWithRole = groupViewModel.sharedGroupsWithRole;
    final isLoading = groupViewModel.isLoading;
    final error = groupViewModel.error;
    final userId = ref.watch(userIdProvider);

    return SlidingMenuScaffold(
      controller: _menuController,
      menuWidget: _buildMenu(ownedGroups, userId),
      contentWidget: _buildContent(
          ownedGroups, sharedGroupsWithRole, isLoading, error, userId),
      animationDuration: const Duration(milliseconds: 250),
      menuBackgroundColor: Colors.white,
    );
  }

  Widget _buildProfileImage(String? photoUrl) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(photoUrl),
        backgroundColor: AppColors.gray200,
      );
    } else {
      return SvgPicture.asset(
        'assets/icons/ProfileImage3.svg',
        width: 32,
        height: 32,
      );
    }
  }

  Widget _buildMenu(List<GroupModel> groups, String? userId) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 5, right: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userId != null)
              ref.watch(userProfileProvider(userId)).when(
                data: (user) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF0F0F0)),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileImage(user?.photoUrl),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? '닉네임',
                            style: TextStyle(
                              color: Color(0xFF191919),
                              fontSize: 14,
                              fontFamily: 'Pretendard',
                              height: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.hashTag ?? '@해시태그',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 12,
                              fontFamily: 'Pretendard',
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '이메일',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 12,
                              fontFamily: 'Pretendard',
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                loading: () => Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
            SizedBox(height: 25),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/folder_icon.svg',
                        colorFilter: ColorFilter.mode(
                            _isGroupExpanded
                                ? Color(0xFF60CFB1)
                                : Color(0xFF616161),
                            BlendMode.srcIn),
                      ),
                      SizedBox(width: 8),
                      Text('그룹',
                          style: PretendardTextStyles.bodyM.copyWith(
                            color: _isGroupExpanded
                                ? Color(0xFF60CFB1)
                                : Colors.black,
                          )),
                      Spacer(),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isGroupExpanded = !_isGroupExpanded;
                          });
                        },
                        icon: _isGroupExpanded
                            ? SvgPicture.asset(
                          'assets/icons/ArrowDown.svg',
                          width: 24,
                          height: 24,
                          color: Color(0xFF616161),
                        )
                            : SvgPicture.asset(
                          'assets/icons/ArrowRight.svg',
                          width: 24,
                          height: 24,
                          color: Color(0xFF616161),
                        ),
                      ),
                    ],
                  ),
                  if (_isGroupExpanded) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var group in groups)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MemoGroupPage(
                                        groupId: group.id,
                                        groupName: group.name,
                                        role: Role.owner.value,
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Text(group.name,
                                        style: PretendardTextStyles.bodyS
                                            .copyWith()),
                                    SizedBox(width: 4),
                                    Text(
                                      '(${group.noteCount})',
                                      style: PretendardTextStyles.bodyS.copyWith(
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (groups.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Text(
                                '그룹이 없습니다',
                                style: PretendardTextStyles.bodyM,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 15),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RecordPage()),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/WaveForm.svg',
                          colorFilter: ColorFilter.mode(
                              Color(0xFF616161), BlendMode.srcIn),
                        ),
                        SizedBox(width: 5),
                        Text(
                          '녹음 기록',
                          style: PretendardTextStyles.bodyM,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/trash_icon.svg',
                        colorFilter: ColorFilter.mode(
                            Color(0xFF616161), BlendMode.srcIn),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '휴지통',
                        style: PretendardTextStyles.bodyM,
                      ),
                    ],
                  ),
                  SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/setting_icon.svg',
                        colorFilter: ColorFilter.mode(
                            Color(0xFF616161), BlendMode.srcIn),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SettingsPage()),
                          );
                        },
                        child: Text(
                          '설정',
                          style: PretendardTextStyles.bodyM,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      List<GroupModel> ownedGroups,
      List<SharedGroupWithRole> sharedGroupsWithRole,
      bool isLoading,
      String? error,
      String? userId) {
    final invitationCount =
        ref.watch(notificationViewModelProvider).invitationCount;

    return Scaffold(
      body: Column(
        children: [
          AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
                onPressed: _menuController.toggleMenu,
                icon: SvgPicture.asset('assets/icons/List.svg')),
            centerTitle: true,
            actions: [
              _isSearching
                  ? IconButton(
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                    ref.read(groupViewModelProvider).searchGroups('');
                  });
                },
                icon: Icon(Icons.close, color: Color(0xFF616161)),
              )
                  : IconButton(
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
                icon: SvgPicture.asset(
                  'assets/icons/MagnifyingGlass.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                      Color(0xFF616161), BlendMode.srcIn),
                ),
              ),
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotificationPage()),
                      );
                    },
                    icon: SvgPicture.asset(
                      'assets/icons/Bell.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                          Color(0xFF616161), BlendMode.srcIn),
                    ),
                  ),
                  if (invitationCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFF60CFB1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$invitationCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            title: _isSearching
                ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '그룹 이름 검색',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                ),
                style: TextStyle(fontSize: 16),
              ),
            )
                : null,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  if (isLoading)
                    Center(child: CircularProgressIndicator())
                  else if (error != null)
                    Text(
                      error,
                      style: TextStyle(color: Colors.red),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '내 그룹 (총 ${(_isSearching
                                ? ref.watch(groupViewModelProvider).filteredSharedGroupsWithRole.length + ref.watch(groupViewModelProvider).filteredOwnedGroups.length
                                : sharedGroupsWithRole.length + ownedGroups.length)}개)',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          (_isSearching
                              ? ref.watch(groupViewModelProvider).filteredSharedGroupsWithRole
                              : sharedGroupsWithRole)
                              .isEmpty
                              ? Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.share,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '공유된 그룹이 없습니다',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                              : ListView.separated(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: _isSearching
                                ? ref.watch(groupViewModelProvider).filteredSharedGroupsWithRole.length
                                : sharedGroupsWithRole.length,
                            separatorBuilder: (context, index) => Container(),
                            itemBuilder: (context, index) {
                              final sharedGroup = _isSearching
                                  ? ref.watch(groupViewModelProvider).filteredSharedGroupsWithRole[index]
                                  : sharedGroupsWithRole[index];
                              return SharedMainItem(
                                title: sharedGroup.group.name,
                                groupId: sharedGroup.group.id,
                                noteCount: sharedGroup.group.noteCount,
                                role: sharedGroup.role,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MemoGroupPage(
                                        groupId: sharedGroup.group.id,
                                        groupName: sharedGroup.group.name,
                                        role: sharedGroup.role,
                                      ),
                                    ),
                                  );
                                },
                                searchQuery: _isSearching ? _searchController.text : null,
                              );
                            },
                          ),
                          (_isSearching
                              ? ref.watch(groupViewModelProvider).filteredOwnedGroups
                              : ownedGroups)
                              .isEmpty
                              ? Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.folder_open,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '생성된 그룹이 없습니다',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '새 그룹을 추가해보세요',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                              : ListView.separated(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: _isSearching
                                ? ref.watch(groupViewModelProvider).filteredOwnedGroups.length
                                : ownedGroups.length,
                            separatorBuilder: (context, index) => Container(),
                            itemBuilder: (context, index) {
                              final group = _isSearching
                                  ? ref.watch(groupViewModelProvider).filteredOwnedGroups[index]
                                  : ownedGroups[index];
                              return MainItem(
                                title: group.name,
                                groupId: group.id,
                                noteCount: group.noteCount,
                                role: Role.owner.value,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MemoGroupPage(
                                        groupId: group.id,
                                        groupName: group.name,
                                        role: Role.owner.value,
                                      ),
                                    ),
                                  );
                                },
                                searchQuery: _isSearching ? _searchController.text : null,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          AnimatedBuilder(
            animation: _fabAnimationController,
            builder: (context, child) {
              final visible = _fabAnimationController.value > 0.0;
              return Visibility(
                visible: visible,
                child: IgnorePointer(
                  ignoring: _fabAnimationController.value == 0.0,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, 1.5),
                      end: Offset(0, 0),
                    ).animate(_fabAnimation),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 160),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '빠른 메모 작성하기',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF191919),
                            ),
                          ),
                          SizedBox(width: 8),
                          FloatingActionButton(
                            heroTag: 'memo',
                            onPressed: () async {
                              _toggleFab();
                              final groupViewModel =
                              ref.read(groupViewModelProvider);
                              final groups = groupViewModel.ownedGroups;
                              if (groups.isEmpty) {
                                if (mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => CupertinoAlertDialog(
                                      title: Text(
                                        '알림',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                      content: Text('먼저 그룹을 생성해주세요.'),
                                      actions: [
                                        CupertinoDialogAction(
                                          child: Text('확인'),
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return;
                              }
                              final groupId = groups.first.id;
                              final memoViewModel =
                              ref.read(memoViewModelProvider(groupId));
                              final newNoteId = await memoViewModel.addMemo();
                              if (newNoteId != null && mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MemoPage(
                                      groupId: groupId,
                                      noteId: newNoteId,
                                      pageId: '1',
                                      role: Role.owner.value,
                                    ),
                                  ),
                                );
                              }
                            },
                            backgroundColor: Color(0xFFD7F3EB),
                            shape: CircleBorder(),
                            elevation: 0,
                            child: SvgPicture.asset(
                                'assets/icons/PencilSimple_green.svg'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _fabAnimationController,
            builder: (context, child) {
              final visible = _fabAnimationController.value > 0.0;
              return Visibility(
                visible: visible,
                child: IgnorePointer(
                  ignoring: _fabAnimationController.value == 0.0,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, 1),
                      end: Offset(0, 0),
                    ).animate(_fabAnimation),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 80),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '새 그룹 생성',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF191919),
                            ),
                          ),
                          SizedBox(width: 8),
                          FloatingActionButton(
                            heroTag: 'group',
                            onPressed: () {
                              _toggleFab();
                              _showAddGroupDialog();
                            },
                            backgroundColor: Color(0xFFD7F3EB),
                            shape: CircleBorder(),
                            elevation: 0,
                            child:
                            SvgPicture.asset('assets/icons/FolderPlus.svg'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          FloatingActionButton(
            heroTag: 'main',
            onPressed: _toggleFab,
            shape: CircleBorder(),
            backgroundColor: Color(0xFF60CFB1),
            elevation: 0,
            child: AnimatedRotation(
              turns: _isFabOpen ? 0.125 : 0,
              duration: Duration(milliseconds: 250),
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}