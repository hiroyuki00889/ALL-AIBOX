import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  // auth_serviceのクラスインスタンス
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider() {
    _authService.authStateChanges.listen((User? user){
      _user = user;
      notifyListeners();
    });
  }

  // ゲッター
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // メールとパスワードでサインアップ
  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
}) async {
    _setLoading(true); // ローディング中
    _clearError();

    try {
      await _authService.signUpWithEmailAndPassword(
          email: email,
          password: password,
      );
      _setLoading(false); // ローディング中解除
      return true;
    } catch (e) {
      _setError(e.toString()); // エラー文章当てはめ、UI更新
      _setLoading(false); // ローディング中解除
      return false;
    }
  }

  // メールとパスワードでサインイン
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signInWithEmailAndPassword(
          email: email,
          password: password,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Google認証でサインイン
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signInWithGoogle();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // サインアウト
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signOut();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // パスワードリセットメールの送信
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();

    try{
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // ローディング状態の設定
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // エラーの設定
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // エラーのクリア
  void _clearError() {
    _error = null;
    notifyListeners();
  }
}