import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/pages/login_page/shared_prefs_helper.dart';
import 'package:nota_note/viewmodels/auth/user_id_provider.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 구글 로그인 메서드
  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // 사용자가 취소한 경우

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  Future<bool> logout(WidgetRef ref) async {
    try {
      await signOut();

      await clearLoginInfo();

      ref.read(userIdProvider.notifier).state = null;

      return true;
    } catch (e) {
      print('로그아웃 중 오류 발생: $e');
      return false;
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
