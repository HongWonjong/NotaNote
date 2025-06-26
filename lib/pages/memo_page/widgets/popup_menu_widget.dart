import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/viewmodels/pin_viewmodel.dart';

class PopupMenuWidget extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final String groupId;
  final String noteId;

  PopupMenuWidget({
    required this.onClose,
    required this.groupId,
    required this.noteId,
  });

  @override
  _PopupMenuWidgetState createState() => _PopupMenuWidgetState();
}

class _PopupMenuWidgetState extends ConsumerState<PopupMenuWidget> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('PopupMenuWidget initState: groupId=${widget.groupId}, noteId=${widget.noteId}');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('Loading pin status...');
      await ref.read(pinViewModelProvider({
        'groupId': widget.groupId,
        'noteId': widget.noteId,
      }).notifier).loadPinStatus();
      if (mounted) {
        setState(() {
          _isLoading = false;
          print('Loading complete, _isLoading=false');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pinStatus = ref.watch(pinViewModelProvider({
      'groupId': widget.groupId,
      'noteId': widget.noteId,
    }));
    print('PopupMenuWidget build: pinStatus=$pinStatus');

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 181,
        height: 216,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: ShapeDecoration(
          color: Color(0xFFF0F0F0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _isLoading
                  ? null
                  : () async {
                print('Pin button tapped: current pinStatus=$pinStatus');
                final notifier = ref.read(pinViewModelProvider({
                  'groupId': widget.groupId,
                  'noteId': widget.noteId,
                }).notifier);
                await notifier.togglePinStatus();
                print('Pin button tap completed');
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
                      color: pinStatus ? Color(0xFF61CFB2) : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pinStatus ? '고정 해제하기' : '고정하기',
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
              onTap: () {},
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
              onTap: () {},
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
              onTap: () {},
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
          ],
        ),
      ),
    );
  }
}