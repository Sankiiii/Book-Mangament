import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';

class AuthState {
  final UserModel? currentUser;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.currentUser,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    UserModel? currentUser,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get isAuthenticated => currentUser != null;
  bool get isAdmin => currentUser?.role == AppConstants.roleAdmin;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final _usersCollection = FirebaseFirestore.instance.collection('users');

  Future<void> _init() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      final appUser = await _getOrCreateUser(firebaseUser);
      state = state.copyWith(currentUser: appUser);
    }
    state = state.copyWith(isLoading: false);
  }

  Future<UserModel> _getOrCreateUser(firebase_auth.User firebaseUser) async {
    final doc = await _usersCollection.doc(firebaseUser.uid).get();
    final data = doc.data();
    if (data != null) {
      return UserModel.fromJson(data);
    }

    final email = firebaseUser.email ?? '';
    final displayName = firebaseUser.displayName?.trim();
    final username = displayName != null && displayName.isNotEmpty
        ? displayName
        : email.split('@').first;

    final newUser = UserModel(
      id: firebaseUser.uid,
      username: username,
      email: email,
      role: AppConstants.roleUser,
    );

    await _usersCollection.doc(newUser.id).set(newUser.toJson());
    return newUser;
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      firebase_auth.UserCredential credential;

      if (kIsWeb) {
        final provider = firebase_auth.GoogleAuthProvider();
        credential = await _firebaseAuth.signInWithPopup(provider);
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          state = state.copyWith(isLoading: false);
          return false;
        }

        final googleAuth = await googleUser.authentication;
        final authCredential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        credential = await _firebaseAuth.signInWithCredential(authCredential);
      }

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Google sign-in failed. Please try again.',
        );
        return false;
      }

      final user = await _getOrCreateUser(firebaseUser);
      state = state.copyWith(currentUser: user, isLoading: false);
      return true;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An error occurred. Please try again.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await GoogleSignIn().signOut();
    await _firebaseAuth.signOut();
    state = state.copyWith(clearUser: true);
  }

  Future<void> refreshCurrentUser() async {
    if (state.currentUser == null) return;
    final doc = await _usersCollection.doc(state.currentUser!.id).get();
    final data = doc.data();
    if (data != null) {
      state = state.copyWith(currentUser: UserModel.fromJson(data));
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).currentUser;
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAdmin;
});
