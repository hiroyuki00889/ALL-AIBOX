import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 現在のユーザーを取得
  User? get currentUser => _auth.currentUser;

  // 認証状態の変更を監視するStream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // メールとパスワードでサインアップ
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // メールとパスワードでサインイン
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try{
      return await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Google認証でサインイン
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Googleサインインフローを開始
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google認証に失敗しました');
      }

      // 認証情報を取得
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebaseで使用する認証情報を作成
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase認証を実行
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Google認証でのサインインに失敗しました： ${e.toString()}');
    }
  }

  // サインアウト
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // パスワードリセットメールの送信
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // エラーハンドリング
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('ユーザーが見つかりませんでした。');
      case 'wrong-password':
        return Exception('パスワードが間違っています。');
      case 'email-already-in-use':
        return Exception('このメールアドレスは既に使用されています。');
      case 'weak-password':
        return Exception('パスワードが弱すぎます。12文字以上の英大文字、英子文字、数字、記号を組み合わせてください。');
      case 'invalid-email':
        return Exception('無効なメールアドレスです。');
      case 'operation-not-allowed':
        return Exception('この操作は許可されていません。');
      case 'too-many-requests':
        return Exception('リクエストが多すぎます。しばらく待ってから再試行してください。');
      default:
        return Exception('認証エラーが発生しました: ${e.message}');
    }
  }
}