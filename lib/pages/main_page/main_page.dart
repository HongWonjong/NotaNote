import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {},
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
      body: const Center(
        child: Text('메인 페이지'),
      ),
    );
  }
}
