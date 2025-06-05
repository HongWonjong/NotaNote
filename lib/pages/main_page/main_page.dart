// import 'package:flutter/material.dart';
// import 'package:nota_note/pages/main_page/widgets/main_item.dart';
// import 'package:nota_note/pages/setting_page/settings_page.dart';
// import 'package:nota_note/widgets/sliding_menu_scaffold.dart';

// class MainPage extends StatefulWidget {

//   const MainPage({super.key,});

//   @override
//   State<MainPage> createState() => _MainPageState();
// }

// class _MainPageState extends State<MainPage> {
//   final SlidingMenuController _menuController = SlidingMenuController();

//   @override
//   Widget build(BuildContext context) {
//     return SlidingMenuScaffold(
//       controller: _menuController,
//       menuWidget: _buildMenu(),
//       contentWidget: _buildContent(),
//       animationDuration: const Duration(milliseconds: 250),
//     );
//   }

//   Widget _buildMenu() {
//     return SafeArea(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Row(
//               children: [
//                 CircleAvatar(
//                   radius: 30,
//                   backgroundColor: Colors.white,
//                 ),
//                 const SizedBox(width: 15),
//                 const Text(
//                   '프로필 정보',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const ListTile(
//             title: Text('그룹'),
//             trailing: Icon(Icons.keyboard_arrow_down),
//           ),
//           const ListTile(
//             title: Text('그룹 이름 3'),
//             contentPadding: EdgeInsets.only(left: 30.0, right: 16.0),
//           ),
//           const ListTile(
//             title: Text('그룹 이름 3'),
//             contentPadding: EdgeInsets.only(left: 30.0, right: 16.0),
//           ),
//           const Divider(),
//           ListTile(
//             title: const Text('휴지통'),
//             onTap: () {},
//           ),
//           ListTile(
//             title: const Text('설정'),
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => SettingsPage(userId: userId),
//                 ),
//               );
//             },
//           ),
//           const ListTile(
//             title: Text('내용'),
//           ),
//           const ListTile(
//             title: Text('내용'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildContent() {
//     return Column(
//       children: [
//         AppBar(
//           backgroundColor: Colors.white,
//           elevation: 0,
//           leading: IconButton(
//             onPressed: _menuController.toggleMenu,
//             icon: const Icon(
//               Icons.menu,
//               color: Color(0xffB5B5B5),
//               size: 24,
//             ),
//           ),
//           actions: [
//             IconButton(
//               onPressed: () {},
//               icon: const Icon(
//                 Icons.search,
//                 color: Color(0xffB1B1B1),
//                 size: 24,
//               ),
//             ),
//             IconButton(
//               onPressed: () {},
//               icon: const Icon(
//                 Icons.notifications_none,
//                 color: Color(0xffB5B5B5),
//                 size: 24,
//               ),
//             ),
//           ],
//         ),
//         Expanded(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 20),
//                 const Text(
//                   '총 2개',
//                   style: TextStyle(fontSize: 15),
//                 ),
//                 const SizedBox(height: 16),
//                 Expanded(
//                   child: ListView(
//                     padding: EdgeInsets.zero,
//                     children: const [
//                       MainItem(title: '그룹 이름 3'),
//                       SizedBox(height: 5),
//                       MainItem(title: '그룹 이름 3'),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:nota_note/pages/main_page/widgets/main_item.dart';
import 'package:nota_note/pages/setting_page/settings_page.dart';
import 'package:nota_note/widgets/sliding_menu_scaffold.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final SlidingMenuController _menuController = SlidingMenuController();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                ),
                SizedBox(width: 15),
                Text(
                  '프로필 정보',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text('그룹'),
            trailing: Icon(Icons.keyboard_arrow_down),
          ),
          ListTile(
            title: Text('그룹 이름 3'),
            contentPadding: EdgeInsets.only(left: 30.0, right: 16.0),
          ),
          ListTile(
            title: Text('그룹 이름 3'),
            contentPadding: EdgeInsets.only(left: 30.0, right: 16.0),
          ),
          Divider(),
          ListTile(
            title: Text('휴지통'),
          ),
          ListTile(
            title: Text('설정'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          ListTile(
            title: Text('내용'),
          ),
          ListTile(
            title: Text('내용'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
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
    );
  }
}
