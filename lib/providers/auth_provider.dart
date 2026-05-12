import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  static const _uuid = Uuid();
  final _usersCollection = FirebaseFirestore.instance.collection('users');

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    await _seedDefaultData();
    state = state.copyWith(isLoading: false);
  }

  Future<void> _seedDefaultData() async {
    final snapshot = await _usersCollection.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

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

  Future<List<UserModel>> _getUsers() async {
    final snapshot = await _usersCollection.get();
    return snapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
  }

  Future<void> _saveUsers(List<UserModel> users) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final user in users) {
      batch.set(_usersCollection.doc(user.id), user.toJson());
    }
    await batch.commit();
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
    String username,
    String email,
    String password,
    String role,
  ) async {
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
      await _usersCollection.doc(newUser.id).set(newUser.toJson());
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
