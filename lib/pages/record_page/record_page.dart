import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/recording_viewmodel.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'widgets/bottom_sheet_menu.dart';

class RecordPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recordingViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('녹음 기록'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 24),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/DotCircle.svg',
              color: Colors.black,
              width: 24,
              height: 24,
            ),
            onPressed: () {
              print('설정 버튼 클릭');
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                '총 ${state.recordings.length}개',
                style: TextStyle(
                  color: Color(0xFF191919),
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: state.recordings.length,
                itemBuilder: (context, index) {
                  final recording = state.recordings[index];
                  final duration = recording.duration;
                  final timeString = duration.inMinutes < 60
                      ? '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
                      : '${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(width: 1, color: Color(0xFFF0F0F0)),
                        bottom: BorderSide(width: 1, color: Color(0xFFF0F0F0)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recording.path.split('/').last.replaceAll('.m4a', ''),
                              style: TextStyle(
                                color: Color(0xFF191919),
                                fontSize: 16,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              timeString,
                              style: TextStyle(
                                color: Color(0xFFB3B3B3),
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                            Text(
                              '${recording.createdAt.year}. ${recording.createdAt.month}. ${recording.createdAt.day}.',
                              style: TextStyle(
                                color: Color(0xFFB3B3B3),
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: SvgPicture.asset(
                            'assets/icons/DotsThree.svg',
                            color: Colors.black,
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                              ),
                              builder: (context) => BottomSheetMenu(recording: recording),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}