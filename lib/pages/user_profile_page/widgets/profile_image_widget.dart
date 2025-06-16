// lib/pages/user_profile_page/widgets/profile_image_widget.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nota_note/services/firebase_storage_service.dart';

/// 프로필 이미지 위젯 (이미지 선택 및 업로드 기능 포함)
class ProfileImageWidget extends ConsumerStatefulWidget {
  final String userId;
  final String currentPhotoUrl;
  final String displayName;
  final bool isEditable; // 프로필 수정 가능 여부

  const ProfileImageWidget({
    super.key,
    required this.userId,
    required this.currentPhotoUrl,
    required this.displayName,
    this.isEditable = false,
  });

  @override
  ConsumerState<ProfileImageWidget> createState() => _ProfileImageWidgetState();
}

class _ProfileImageWidgetState extends ConsumerState<ProfileImageWidget> {
  bool _isUploading = false;

  /// 이미지 선택 및 업로드 처리
  Future<void> _pickAndUploadImage() async {
    if (!widget.isEditable) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() => _isUploading = true);

    final File imageFile = File(picked.path);

    try {
      // Firebase Storage에 업로드 및 Firestore 반영
      await uploadProfileImage(
        userId: widget.userId,
        imageFile: imageFile,
      );
    } catch (e) {
      debugPrint('이미지 업로드 실패: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 업로드에 실패했습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 프로필 이미지 영역 (수정 가능 시 터치 가능)
        GestureDetector(
          onTap:
              _isUploading || !widget.isEditable ? null : _pickAndUploadImage,
          child: CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[300], // gray[300]
            backgroundImage: widget.currentPhotoUrl.isNotEmpty
                ? NetworkImage(widget.currentPhotoUrl)
                : null,
            child: widget.currentPhotoUrl.isEmpty
                ? Text(
                    widget.displayName.characters.first,
                    style: TextStyle(fontSize: 24, color: Colors.grey[100]),
                  )
                : null,
          ),
        ),

        // 업로드 중이면 로딩 인디케이터 표시
        if (_isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
