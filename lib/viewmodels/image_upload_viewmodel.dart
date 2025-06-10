import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nota_note/viewmodels/page_viewmodel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

enum ImageUploadState { idle, loading, success, error }

class ImageUploadViewModel extends StateNotifier<ImageUploadState> {
  final String groupId;
  final String noteId;
  final String pageId;
  final QuillController controller;
  final Ref ref;
  String? errorMessage;

  ImageUploadViewModel({
    required this.groupId,
    required this.noteId,
    required this.pageId,
    required this.controller,
    required this.ref,
  }) : super(ImageUploadState.idle);

  Future<void> pickAndUploadImage(ImageSource source, BuildContext context) async {
    state = ImageUploadState.loading;
    errorMessage = null;

    print('Picking image from $source');

    // 시뮬레이터에서는 권한 체크 우회
    if (kDebugMode && Platform.isIOS) {
      print('Simulator detected, bypassing permission check');
    } else {
      final permission = source == ImageSource.gallery ? Permission.photos : Permission.camera;
      final permissionStatus = await permission.status;
      print('Permission status for $source: $permissionStatus');

      if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
        final requestStatus = await permission.request();
        print('Permission request result: $requestStatus');
        if (requestStatus.isDenied || requestStatus.isPermanentlyDenied) {
          print('Permission denied for $source');
          state = ImageUploadState.error;
          errorMessage = '${source == ImageSource.gallery ? '사진' : '카메라'} 접근 권한이 필요합니다.';
          return;
        }
      }
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    print('Picked file: $pickedFile');

    if (pickedFile == null) {
      state = ImageUploadState.error;
      errorMessage = '이미지를 선택하지 않았습니다.';
      print('No image picked');
      return;
    }

    final imageFile = File(pickedFile.path);
    final imageUrl = await _uploadImageToStorage(imageFile);

    if (imageUrl != null) {
      final index = controller.selection.start;
      controller.document.insert(index, '\n');
      controller.document.insert(
        index + 1,
        Embeddable('image', imageUrl),
      );
      controller.updateSelection(
        TextSelection.collapsed(offset: index + 2),
        ChangeSource.local,
      );
      print('Image inserted, new selection: ${controller.selection}');
      print('Current Delta: ${controller.document.toDelta().toJson()}');

      await ref.read(pageViewModelProvider({
        'groupId': groupId,
        'noteId': noteId,
        'pageId': pageId,
      }).notifier).saveToFirestore(controller);
      print('Firestore save triggered after image insertion');

      state = ImageUploadState.success;
    } else {
      state = ImageUploadState.error;
      errorMessage = errorMessage ?? '이미지 업로드 실패';
      print('Image upload returned null URL');
    }
  }

  Future<String?> _uploadImageToStorage(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('notegroups/$groupId/notes/$noteId/pages/$pageId/images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      print('Uploading image to: ${storageRef.fullPath}');
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      print('Upload task state: ${snapshot.state}, bytes transferred: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
      final imageUrl = await storageRef.getDownloadURL();
      print('Image uploaded successfully: $imageUrl');
      return imageUrl;
    } catch (e, stackTrace) {
      print('Image upload failed: $e');
      print('Stack trace: $stackTrace');
      if (e is FirebaseException) {
        switch (e.code) {
          case 'unauthorized':
            errorMessage = '스토리지 접근 권한이 없습니다. 로그인 상태를 확인해주세요.';
            break;
          case 'canceled':
            errorMessage = '업로드가 취소되었습니다.';
            break;
          default:
            errorMessage = '이미지 업로드 실패: ${e.message}';
        }
      } else {
        errorMessage = '이미지 업로드 실패: $e';
      }
      return null;
    }
  }

  void reset() {
    state = ImageUploadState.idle;
    errorMessage = null;
  }
}

final imageUploadProvider = StateNotifierProvider.family<ImageUploadViewModel, ImageUploadState, Map<String, dynamic>>(
      (ref, params) => ImageUploadViewModel(
    groupId: params['groupId']!,
    noteId: params['noteId']!,
    pageId: params['pageId']!,
    controller: params['controller']!,
    ref: ref,
  ),
);