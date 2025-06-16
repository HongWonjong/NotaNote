import 'package:flutter/material.dart';

class PopupMenuWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 181,
      height: 216,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: ShapeDecoration(
        color: Color(0xFFF0F0F0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  child: Icon(Icons.lock_open, size: 20, color: Color(0xFF4C4C4C)),
                ),
                const SizedBox(width: 8),
                Text(
                  '고정 해제하기',
                  style: TextStyle(
                    color: Color(0xFF4C4C4C),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    height: 0.09,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  child: Icon(Icons.copy, size: 20, color: Color(0xFF4C4C4C)),
                ),
                const SizedBox(width: 8),
                Text(
                  '복제하기',
                  style: TextStyle(
                    color: Color(0xFF4C4C4C),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    height: 0.09,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  child: Icon(Icons.arrow_forward, size: 20, color: Color(0xFF4C4C4C)),
                ),
                const SizedBox(width: 8),
                Text(
                  '이동하기',
                  style: TextStyle(
                    color: Color(0xFF4C4C4C),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    height: 0.09,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  child: Icon(Icons.delete, size: 20, color: Color(0xFFFF2F2F)),
                ),
                const SizedBox(width: 8),
                Text(
                  '삭제하기',
                  style: TextStyle(
                    color: Color(0xFFFF2F2F),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    height: 0.09,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}