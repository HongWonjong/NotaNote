import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomSheetMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 37,
            height: 4,
            decoration: ShapeDecoration(
              color: Color(0xFF4C4C4C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: SizedBox(
                    child: Text(
                      '다운받기',
                      style: TextStyle(
                        color: Color(0xFF4C4C4C),
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        height: 0.09,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                SvgPicture.asset(
                  'assets/icons/DownloadSimple.svg',
                  width: 20,
                  height: 20,
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: SizedBox(
                    child: Text(
                      '텍스트 변환하기',
                      style: TextStyle(
                        color: Color(0xFF4C4C4C),
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        height: 0.09,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                SvgPicture.asset(
                  'assets/icons/Edit.svg',
                  width: 20,
                  height: 20,
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: SizedBox(
                    child: Text(
                      '이름 변경하기',
                      style: TextStyle(
                        color: Color(0xFF4C4C4C),
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        height: 0.09,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                SvgPicture.asset(
                  'assets/icons/Name.svg',
                  width: 20,
                  height: 20,
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: SizedBox(
                    child: Text(
                      '삭제하기',
                      style: TextStyle(
                        color: Color(0xFFFF2F2F),
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        height: 0.09,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                SvgPicture.asset(
                  'assets/icons/Delete.svg',
                  color: Color(0xFFFF2F2F),
                  width: 20,
                  height: 20,
                ),
              ],
            ),
          ),
          SizedBox(height: 30)
        ],
      ),
    );
  }
}