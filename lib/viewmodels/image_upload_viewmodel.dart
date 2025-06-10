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

    print('Picking image from $source');

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
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('notegroups/$groupId/notes/$noteId/pages/$pageId/images/$fileName');
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

  ImageProvider<Object> getImageProviderSync(String imageUrl) {
    final localPath = _localStorageService.getLocalImagePathSync(groupId, noteId, pageId, imageUrl);
    if (localPath.isNotEmpty) {
      print('Using cached image from local storage: $localPath for $imageUrl');
      return FileImage(File(localPath));
    }

    print('Using NetworkImage and initiating cache for: $imageUrl');
    cacheImageLocally(imageUrl);
    return NetworkImage(imageUrl);
  }

  Future<void> cacheImageLocally(String imageUrl) async {
    try {
      print('Starting image download: $imageUrl');
      final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.writeToFile(tempFile);
      print('Image downloaded to temp: ${tempFile.path}');

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

      print('Image caching completed: $localPath for $imageUrl');
    } catch (e) {
      print('Failed to cache image: $e for $imageUrl');
    }
  }

  String _generateFileName(String imageUrl) {
    final uri = Uri.parse(imageUrl);
    final pathSegments = uri.pathSegments;
    final fileName = pathSegments.lastWhere(
          (segment) => segment.endsWith('.jpg'),
      orElse: () => 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    print('Generated file name: $fileName for $imageUrl');
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