import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nota_note/models/user_model.dart';
import 'package:nota_note/pages/login_page/shared_prefs_helper.dart';
import 'package:nota_note/viewmodels/auth/auth_common.dart';

final googleAuthViewModelProvider =
    Provider<GoogleAuthViewModel>((ref) => GoogleAuthViewModel(ref));

class GoogleAuthViewModel {
  final Ref ref;
  GoogleAuthViewModel(this.ref);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return null;

      final userId = user.uid;
      final docRef = _firestore.collection('users').doc(userId);
      final userDoc = await docRef.get();

      if (!userDoc.exists) {
        final newUser = UserModel(
          userId: userId,
          email: user.email ?? 'unknown@email.com',
          displayName: user.displayName ?? 'Unknown',
          photoUrl: user.photoURL ?? '',
          hashTag: generateHashedTag(userId),
          loginProviders: 'google',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await docRef.set(newUser.toJson(), SetOptions(merge: true));
      }

      await saveLoginUserId(userId);
      await saveLoginProvider('google');
      ref.read(userIdProvider.notifier).state = userId;

      final freshDoc = await docRef.get();
      return UserModel.fromJson(freshDoc.data()!);
    } catch (e, st) {
      log('[구글 로그인 실패] $e', stackTrace: st);
      return null;
    }
  }
}
