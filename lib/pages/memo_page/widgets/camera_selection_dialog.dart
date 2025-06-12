import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nota_note/viewmodels/image_upload_viewmodel.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CameraSelectionDialog extends ConsumerWidget {
  final String groupId;
  final String noteId;
  final String pageId;
  final QuillController controller;

  const CameraSelectionDialog({
    required this.groupId,
    required this.noteId,
    required this.pageId,
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const ShapeDecoration(
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
            decoration:  ShapeDecoration(
              color: Color(0xFF4C4C4C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              ref.read(imageUploadProvider({
                'groupId': groupId,
                'noteId': noteId,
                'pageId': pageId,
                'controller': controller,
              }).notifier).pickAndUploadImage(ImageSource.camera, context);
              Navigator.pop(context);
            },
            splashColor: Colors.grey.withOpacity(0.2),
            highlightColor: Colors.grey.withOpacity(0.1),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '사진 촬영하기',
                    style: TextStyle(
                      color: Color(0xFF4C4C4C),
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/icons/Camera.svg',
                    width: 24,
                    height: 24,
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {
              ref.read(imageUploadProvider({
                'groupId': groupId,
                'noteId': noteId,
                'pageId': pageId,
                'controller': controller,
              }).notifier).pickAndUploadImage(ImageSource.gallery, context);
              Navigator.pop(context);
            },
            splashColor: Colors.grey.withOpacity(0.2),
            highlightColor: Colors.grey.withOpacity(0.1),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '이미지 선택하기',
                    style: TextStyle(
                      color: Color(0xFF4C4C4C),
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/icons/Image.svg',
                    width: 24,
                    height: 24,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}