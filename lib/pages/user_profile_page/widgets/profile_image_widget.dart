import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nota_note/services/firebase_storage_service.dart';
import 'package:nota_note/theme/colors.dart';

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
  late String _photoUrl;

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.currentPhotoUrl; // 초기 이미지 URL 저장
  }

  /// 이미지 선택 및 업로드 처리
  Future<void> _pickAndUploadImage() async {
    if (!widget.isEditable) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isUploading = true);
    final File imageFile = File(picked.path);

    try {
      // 1. Firebase Storage에 업로드
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(widget.userId)
          .child('profile.jpg');
      final uploadTask = await storageRef.putFile(imageFile);

      // 2. 업로드된 이미지의 다운로드 URL 획득
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // 3. Firestore 업데이트 (기존 함수 호출)
      await uploadProfileImage(
        userId: widget.userId,
        imageFile: imageFile,
      );

      // 4. UI에 즉시 반영
      if (mounted) {
        setState(() {
          _photoUrl = downloadUrl;
        });
      }
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
        // 프로필 이미지 (수정 가능 시 터치 가능)
        GestureDetector(
          onTap:
              _isUploading || !widget.isEditable ? null : _pickAndUploadImage,
          child: CircleAvatar(
            radius: 43,
            backgroundColor: AppColors.gray300,
            backgroundImage:
                _photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null,
            child: _photoUrl.isEmpty
                ? SvgPicture.asset(
                    'assets/icons/ProfileImage2.svg',
                    width: 86,
                    height: 86,
                  )
                : null,
          ),
        ),

        // 업로드 중 로딩 표시
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
