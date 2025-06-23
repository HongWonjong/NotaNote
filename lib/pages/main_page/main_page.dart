import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/models/group_model.dart';
import 'package:nota_note/pages/main_page/widgets/main_item.dart';
import 'package:nota_note/pages/setting_page/settings_page.dart';
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

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  final SlidingMenuController _menuController = SlidingMenuController();
  bool _isGroupExpanded = false;
  String? _newGroupName;
  final TextEditingController _textController = TextEditingController();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
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
    _textController.dispose();
    super.dispose();
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
                    suffixText: '$textLength/10',
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
                  maxLength: 10,
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

  @override
  Widget build(BuildContext context) {
    final groupViewModel = ref.watch(groupViewModelProvider);
    final groups = groupViewModel.groups;
    final isLoading = groupViewModel.isLoading;
    final error = groupViewModel.error;

    final userId = ref.watch(userIdProvider);

    return SlidingMenuScaffold(
      controller: _menuController,
      menuWidget: _buildMenu(groups, userId),
      contentWidget: _buildContent(groups, isLoading, error, userId),
      animationDuration: const Duration(milliseconds: 250),
      menuBackgroundColor: Colors.white,
    );
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
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
                      SvgPicture.asset(
                        'assets/icons/ProfileImage3.svg',
                        width: 32,
                        height: 32,
                      ),
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
                            _isGroupExpanded ? Color(0xFF60CFB1) : Color(0xffBFBFBF),
                            BlendMode.srcIn),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '그룹',
                        style: PretendardTextStyles.bodyM
                      ),
                      Spacer(),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isGroupExpanded = !_isGroupExpanded;
                          });
                        },
                        icon: Icon(
                          _isGroupExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          size: 24,
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${group.name} 그룹 선택됨 (ID: ${group.id})'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  _menuController.closeMenu();
                                },
                                child: Text(
                                  group.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                  ),
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
                          colorFilter:
                          ColorFilter.mode(Color(0xffBFBFBF), BlendMode.srcIn),
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
                        colorFilter:
                        ColorFilter.mode(Color(0xffBFBFBF), BlendMode.srcIn),
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
                        colorFilter:
                        ColorFilter.mode(Color(0xffBFBFBF), BlendMode.srcIn),
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
      List<GroupModel> groups, bool isLoading, String? error, String? userId) {
    return Scaffold(
      body: Column(
        children: [
          AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              onPressed: _menuController.toggleMenu,
              icon: Icon(
                Icons.menu,
                color: Color(0xffB5B5B5),
                size: 24,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.search,
                  color: Color(0xffB1B1B1),
                  size: 24,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none,
                  color: Color(0xffB5B5B5),
                  size: 24,
                ),
              ),
            ],
          ),
          Expanded(
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
                    child: Row(
                      children: [
                        Text(
                          '총 ${groups.length}개',
                          style: TextStyle(
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 16),
                Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : groups.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                    padding: EdgeInsets.zero,
                    itemCount: groups.length,
                    separatorBuilder: (context, index) => Container(),
                    itemBuilder: (context, index) {
                      return MainItem(
                        title: groups[index].name,
                        groupId: groups[index].id,
                        noteCount: groups[index].noteCount,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MemoGroupPage(
                                groupId: groups[index].id,
                                groupName: groups[index].name,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: FloatingActionButton(
          onPressed: _showAddGroupDialog,
          backgroundColor: Color(0xFF61CFB2),
          shape: CircleBorder(),
          elevation: 0,
          child: SvgPicture.asset('assets/icons/floatingActionButton_icon.svg'),
        ),
      ),
    );
  }
}