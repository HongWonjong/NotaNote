import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:nota_note/viewmodels/page_viewmodel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:nota_note/services/local_storage_service.dart';
import 'dart:convert';

enum ImageUploadState { idle, loading, success, error }

class ImageUploadViewModel extends StateNotifier<ImageUploadState> {
  final String groupId;
  final String noteId;
  final String pageId;
  final QuillController controller;
  final Ref ref;
  String? errorMessage;
  final LocalStorageService _localStorageService = LocalStorageService();

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


    if (kDebugMode && Platform.isIOS) {
    } else {
      final permission = source == ImageSource.gallery ? Permission.photos : Permission.camera;
      final permissionStatus = await permission.status;

      if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
        final requestStatus = await permission.request();
        if (requestStatus.isDenied || requestStatus.isPermanentlyDenied) {
          state = ImageUploadState.error;
          errorMessage = '${source == ImageSource.gallery ? '사진' : '카메라'} 접근 권한이 필요합니다.';
          return;
        }
      }
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) {
      state = ImageUploadState.error;
      errorMessage = '이미지를 선택하지 않았습니다.';
      return;
    }

    final imageFile = File(pickedFile.path);
    final imageUrl = await _uploadImageToStorage(imageFile);

    if (imageUrl != null) {
      final fileName = _generateFileName(imageUrl);
      final localPath = await _localStorageService.saveImageFileToLocal(imageFile, fileName);

      final style = controller.getSelectionStyle();
      final formattingData = jsonEncode(style.attributes);

      await _localStorageService.saveImageLocally(
        groupId: groupId,
        noteId: noteId,
        pageId: pageId,
        imageUrl: imageUrl,
        localPath: localPath,
        formattingData: formattingData,
      );

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

      await ref.read(pageViewModelProvider({
        'groupId': groupId,
        'noteId': noteId,
        'pageId': pageId,
      }).notifier).saveToFirestore(controller);

      state = ImageUploadState.success;
    } else {
      state = ImageUploadState.error;
      errorMessage = errorMessage ?? '이미지 업로드 실패';
    }
  }

  Future<String?> _uploadImageToStorage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('notegroups/$groupId/notes/$noteId/pages/$pageId/images/$fileName');
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      final imageUrl = await storageRef.getDownloadURL();
      return imageUrl;
    } catch (e, stackTrace) {
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

  ImageProvider<Object> getImageProviderSync(String imageUrl) {
    final localPath = _localStorageService.getLocalImagePathSync(groupId, noteId, pageId, imageUrl);
    if (localPath.isNotEmpty) {
      return FileImage(File(localPath));
    }

    cacheImageLocally(imageUrl);
    return NetworkImage(imageUrl);
  }

  Future<void> cacheImageLocally(String imageUrl) async {
    try {
      final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.writeToFile(tempFile);

      final fileName = _generateFileName(imageUrl);
      final localPath = await _localStorageService.saveImageFileToLocal(tempFile, fileName);

      final formattingData = jsonEncode({});
      await _localStorageService.saveImageLocally(
        groupId: groupId,
        noteId: noteId,
        pageId: pageId,
        imageUrl: imageUrl,
        localPath: localPath,
        formattingData: formattingData,
      );

    } catch (e) {
    }
  }

  String _generateFileName(String imageUrl) {
    final uri = Uri.parse(imageUrl);
    final pathSegments = uri.pathSegments;
    final fileName = pathSegments.lastWhere(
          (segment) => segment.endsWith('.jpg'),
      orElse: () => 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    return fileName;
  }

  Future<Map<String, dynamic>?> getFormattingData(String imageUrl) async {
    final data = await _localStorageService.getImageData(groupId, noteId, pageId, imageUrl);
    if (data != null && data['formattingData'] != null) {
      return jsonDecode(data['formattingData'] as String);
    }
    return null;
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