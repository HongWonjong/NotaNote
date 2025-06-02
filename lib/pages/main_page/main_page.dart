import 'package:flutter/material.dart';
import 'package:nota_note/pages/main_page/widgets/main_item.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            
          },
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text(
              '총 3개',
              style: TextStyle(
                fontSize: 15,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  MainItem(title: '그룹이름 1'),
                  SizedBox(height: 5),
                  MainItem(title: '그룹이름 2'),
                  SizedBox(height: 5),
                  MainItem(title: '그룹이름 3'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
