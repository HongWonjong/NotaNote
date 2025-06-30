import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:nota_note/viewmodels/recording_viewmodel.dart';
import 'package:nota_note/pages/loading_page/loading_page.dart';

class TranscribeDialog extends ConsumerStatefulWidget {
  final String recordingPath;
  final QuillController controller;
  final RecordingViewModel recordingViewModel;

  const TranscribeDialog({
    required this.recordingPath,
    required this.controller,
    required this.recordingViewModel,
    super.key,
  });

  @override
  _TranscribeDialogState createState() => _TranscribeDialogState();
}

class _TranscribeDialogState extends ConsumerState<TranscribeDialog> {
  String selectedLanguage = 'ko';
  String selectedMode = 'original';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      content: Container(
        width: 268,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '변환 설정',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF191919),
                fontSize: 18,
                fontFamily: 'Pretendard',
              ),
            ),
            SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '언어',
                        style: TextStyle(
                          color: Color(0xFF4C4C4C),
                          fontSize: 16,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      SizedBox(height: 14),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedLanguage = 'ko';
                              });
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: ShapeDecoration(
                                          color: selectedLanguage == 'ko'
                                              ? Color(0xFF60CFB1)
                                              : Colors.white,
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                                width: 1,
                                                color: Color(0xFFCCCCCC)),
                                            borderRadius:
                                            BorderRadius.circular(999),
                                          ),
                                        ),
                                      ),
                                      if (selectedLanguage == 'ko')
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: ShapeDecoration(
                                            color: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(999),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '한국어',
                                  style: TextStyle(
                                    color: selectedLanguage == 'ko'
                                        ? Color(0xFF60CFB1)
                                        : Color(0xFF4C4C4C),
                                    fontSize: 16,
                                    fontFamily: 'Pretendard',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 14),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedLanguage = 'en';
                              });
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: ShapeDecoration(
                                          color: selectedLanguage == 'en'
                                              ? Color(0xFF60CFB1)
                                              : Colors.white,
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                                width: 1,
                                                color: Color(0xFFCCCCCC)),
                                            borderRadius:
                                            BorderRadius.circular(999),
                                          ),
                                        ),
                                      ),
                                      if (selectedLanguage == 'en')
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: ShapeDecoration(
                                            color: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(999),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '영어',
                                  style: TextStyle(
                                    color: selectedLanguage == 'en'
                                        ? Color(0xFF60CFB1)
                                        : Color(0xFF4C4C4C),
                                    fontSize: 16,
                                    fontFamily: 'Pretendard',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '보기 방식',
                        style: TextStyle(
                          color: Color(0xFF4C4C4C),
                          fontSize: 16,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      SizedBox(height: 14),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedMode = 'original';
                              });
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: ShapeDecoration(
                                          color: selectedMode == 'original'
                                              ? Color(0xFF60CFB1)
                                              : Colors.white,
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                                width: 1,
                                                color: Color(0xFFCCCCCC)),
                                            borderRadius:
                                            BorderRadius.circular(999),
                                          ),
                                        ),
                                      ),
                                      if (selectedMode == 'original')
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: ShapeDecoration(
                                            color: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(999),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '원문으로 보기',
                                  style: TextStyle(
                                    color: selectedMode == 'original'
                                        ? Color(0xFF60CFB1)
                                        : Color(0xFF4C4C4C),
                                    fontSize: 16,
                                    fontFamily: 'Pretendard',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 14),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedMode = 'summarized';
                              });
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: ShapeDecoration(
                                          color: selectedMode == 'summarized'
                                              ? Color(0xFF60CFB1)
                                              : Colors.white,
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                                width: 1,
                                                color: Color(0xFFCCCCCC)),
                                            borderRadius:
                                            BorderRadius.circular(999),
                                          ),
                                        ),
                                      ),
                                      if (selectedMode == 'summarized')
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: ShapeDecoration(
                                            color: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(999),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '요약해서 보기',
                                  style: TextStyle(
                                    color: selectedMode == 'summarized'
                                        ? Color(0xFF60CFB1)
                                        : Color(0xFF4C4C4C),
                                    fontSize: 16,
                                    fontFamily: 'Pretendard',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            Container(
              width: 114,
              height: 50,
              decoration: ShapeDecoration(
                color: Color(0xFF60CFB1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: TextButton(
                onPressed: () {
                  // 키보드 포커스 해제
                  FocusScope.of(context).unfocus();
                  // 다이얼로그 닫고 LoadingPage로 이동
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LoadingPage(
                        recordingPath: widget.recordingPath,
                        language: selectedLanguage,
                        mode: selectedMode,
                        controller: widget.controller,
                        recordingViewModel: widget.recordingViewModel,
                      ),
                    ),
                  );
                },
                child: Text(
                  '변환하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}