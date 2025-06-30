import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/viewmodels/recording_viewmodel.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BottomSheetMenu extends ConsumerWidget {
  final RecordingInfo recording;
  final QuillController? controller;

  BottomSheetMenu({required this.recording, this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
          GestureDetector(
            onTap: () async {
              await ref
                  .read(recordingViewModelProvider.notifier)
                  .downloadRecording(recording.path);
              Navigator.pop(context);
            },
            child: Container(
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
          ),
          GestureDetector(
            onTap: () async {
              if (controller != null) {
                await ref
                    .read(recordingViewModelProvider.notifier)
                    .transcribeRecording(recording.path, 'ko', controller!);
                Navigator.pop(context);
              }
            },
            child: Container(
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
          ),
          GestureDetector(
            onTap: () async {
              final newName = await showDialog<String>(
                context: context,
                builder: (context) {
                  final controller = TextEditingController();
                  return AlertDialog(
                    title: Text('이름 변경'),
                    content: TextField(
                      controller: controller,
                      decoration: InputDecoration(hintText: '새로운 이름 입력'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('취소'),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, controller.text),
                        child: Text('확인'),
                      ),
                    ],
                  );
                },
              );
              if (newName != null && newName.isNotEmpty) {
                await ref
                    .read(recordingViewModelProvider.notifier)
                    .renameRecording(recording.path, newName);
              }
              Navigator.pop(context);
            },
            child: Container(
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
          ),
          GestureDetector(
            onTap: () async {
              await ref
                  .read(recordingViewModelProvider.notifier)
                  .deleteRecording(recording.path);
              Navigator.pop(context);
            },
            child: Container(
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
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}
