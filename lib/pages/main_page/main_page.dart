import 'package:flutter/material.dart';
import 'package:nota_note/pages/main_page/widgets/main_item.dart';
import 'package:nota_note/widgets/sliding_menu_scaffold.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final SlidingMenuController _menuController = SlidingMenuController();
  bool _isGroupExpanded = false;

  @override
  Widget build(BuildContext context) {
    return SlidingMenuScaffold(
      controller: _menuController,
      menuWidget: _buildMenu(),
      contentWidget: _buildContent(),
      animationDuration: const Duration(milliseconds: 250),
    );
  }

  Widget _buildMenu() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 47.5),
            Row(
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/folder_icon.png',
                      color: Color(0xffBFBFBF),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '그룹',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
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
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(
                        '그룹이름',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(
                        '그룹이름',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 31),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/trash_icon.png',
                  color: Color(0xffBFBFBF),
                ),
                SizedBox(width: 8),
                Text(
                  '휴지통',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/setting_icon.png',
                  color: Color(0xffBFBFBF),
                ),
                SizedBox(width: 8),
                Text(
                  '설정',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Text(
                    '총 2개',
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        MainItem(title: '그룹 이름 3'),
                        SizedBox(height: 5),
                        MainItem(title: '그룹 이름 3'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //
        },
        backgroundColor: Color(0xFFEFEFEF),
        shape: CircleBorder(),
        elevation: 0,
        child: Icon(
          Icons.add,
          size: 24,
        ),
      ),
    );
  }
}
