import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
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
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get isAuthenticated => currentUser != null;
  bool get isAdmin => currentUser?.role == AppConstants.roleAdmin;
}


class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  static const _uuid = Uuid();

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.currentUserKey);
    if (userJson != null) {
      final user = UserModel.fromJson(jsonDecode(userJson));
      state = state.copyWith(currentUser: user, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false);
    }
    await _seedDefaultData();
  }

  Future<void> _seedDefaultData() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(AppConstants.usersKey);
    if (usersJson == null) {
      final admin = UserModel(
        id: _uuid.v4(),
        username: 'admin',
        email: 'admin@bookshelf.com',
        password: 'admin123',
        role: AppConstants.roleAdmin,
      );
      final user = UserModel(
        id: _uuid.v4(),
        username: 'user',
        email: 'user@bookshelf.com',
        password: 'user123',
        role: AppConstants.roleUser,
      );
      await _saveUsers([admin, user]);
    }
  }

  Future<List<UserModel>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(AppConstants.usersKey);
    if (usersJson == null) return [];
    final List decoded = jsonDecode(usersJson);
    return decoded.map((e) => UserModel.fromJson(e)).toList();
  }

  Future<void> _saveUsers(List<UserModel> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.usersKey,
      jsonEncode(users.map((u) => u.toJson()).toList()),
    );
  }

  Future<bool> login(String username, String password, String role) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 600));
    try {
      final users = await _getUsers();
      final match = users.where(
        (u) =>
            u.username.toLowerCase() == username.toLowerCase() &&
            u.password == password &&
            u.role == role,
      );
      if (match.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Invalid credentials. Please try again.',
        );
        return false;
      }
      final user = match.first;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          AppConstants.currentUserKey, jsonEncode(user.toJson()));
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

  Future<bool> register(
      String username, String email, String password, String role) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 600));
    try {
      final users = await _getUsers();
      final exists = users.any(
        (u) =>
            u.username.toLowerCase() == username.toLowerCase() ||
            u.email.toLowerCase() == email.toLowerCase(),
      );
      if (exists) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Username or email already exists.',
        );
        return false;
      }
      final newUser = UserModel(
        id: _uuid.v4(),
        username: username,
        email: email,
        password: password,
        role: role,
      );
      users.add(newUser);
      await _saveUsers(users);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          AppConstants.currentUserKey, jsonEncode(newUser.toJson()));
      state = state.copyWith(currentUser: newUser, isLoading: false);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.currentUserKey);
    state = state.copyWith(clearUser: true);
  }

  Future<void> refreshCurrentUser() async {
    if (state.currentUser == null) return;
    final users = await _getUsers();
    final updated = users.where((u) => u.id == state.currentUser!.id);
    if (updated.isNotEmpty) {
      final u = updated.first;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          AppConstants.currentUserKey, jsonEncode(u.toJson()));
      state = state.copyWith(currentUser: u);
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
