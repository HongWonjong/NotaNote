// 사용자 정보를 표현하는 모델 클래스
// Firestore에서 사용자 데이터를 가져오고, 저장하는 기능 구현
// Firebase Authentication과 연동하여 사용자 정보 관리

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String displayName;
  final String email;
  final String photoUrl;
  final String hashTag;
  final String loginProviders;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.hashTag,
    required this.loginProviders,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'],
      displayName: map['displayName'],
      email: map['email'],
      photoUrl: map['photoUrl'],
      hashTag: map['hashTag'],
      loginProviders: map['loginProviders'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'hashTag': hashTag,
      'loginProviders': loginProviders,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
  }) {
    return UserModel(
      userId: userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      hashTag: hashTag,
      loginProviders: loginProviders,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
