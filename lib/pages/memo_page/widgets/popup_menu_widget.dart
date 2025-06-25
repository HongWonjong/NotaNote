import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/pages/memo_page/widgets/pdf_helper.dart';

class PopupMenuWidget extends StatefulWidget {
  final VoidCallback onClose;
  final quill.QuillController quillController;

  const PopupMenuWidget({
    required this.onClose,
    required this.quillController,
    super.key,
  });

  @override
  _PopupMenuWidgetState createState() => _PopupMenuWidgetState();
}

class _PopupMenuWidgetState extends State<PopupMenuWidget> {
  bool _isPinned = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 181,
        height: 270, // 파일 변환 추가로 세로 크기 수정 함
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
            InkWell(
              onTap: () {
                setState(() {
                  _isPinned = !_isPinned;
                });
                print('고정 버튼 클릭됨');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 20),
                    SvgPicture.asset(
                      'assets/icons/PushPin.svg',
                      width: 20,
                      height: 20,
                      color: _isPinned ? Color(0xFF61CFB2) : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isPinned ? '고정 해제하기' : '고정하기',
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
            ),
            InkWell(
              onTap: () {
                print('복제 버튼 클릭됨');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 20),
                    SvgPicture.asset(
                      'assets/icons/Files.svg',
                      width: 20,
                      height: 20,
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
            ),
            InkWell(
              onTap: () {
                print('이동 버튼 클릭됨');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 20),
                    SvgPicture.asset(
                      'assets/icons/FileArrowUp.svg',
                      width: 20,
                      height: 20,
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
            ),
            InkWell(
              onTap: () {
                print('삭제 버튼 클릭됨');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 20),
                    SvgPicture.asset(
                      'assets/icons/Delete.svg',
                      width: 20,
                      height: 20,
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
            ),
            //pdf 변환 + 디바이더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Divider(),
            ),
            InkWell(
              onTap: () async {
                await saveTextAsPdfAndShare(
                  text: widget.quillController.document.toPlainText(),
                  fileName: "my_note_${DateTime.now().millisecondsSinceEpoch}",
                  context: context,
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    SvgPicture.asset(
                      'assets/icons/FilePdf.svg',
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PDF로 내보내기',
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
            ),
          ],
        ),
      ),
    );
  }
}
