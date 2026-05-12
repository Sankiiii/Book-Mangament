import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/book_model.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';
import 'auth_provider.dart';

// ─── Books State ─────────────────────────────────────────────────────────────

class BooksState {
  final List<BookModel> books;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String? selectedGenre;
  final String sortBy;

  const BooksState({
    this.books = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedGenre,
    this.sortBy = 'title',
  });

  BooksState copyWith({
    List<BookModel>? books,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? selectedGenre,
    String? sortBy,
    bool clearError = false,
    bool clearGenre = false,
  }) {
    return BooksState(
      books: books ?? this.books,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedGenre:
          clearGenre ? null : (selectedGenre ?? this.selectedGenre),
      sortBy: sortBy ?? this.sortBy,
    );
  }

  List<BookModel> get filteredBooks {
    List<BookModel> result = List.from(books);
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where((b) =>
              b.title.toLowerCase().contains(q) ||
              b.author.toLowerCase().contains(q) ||
              b.genre.toLowerCase().contains(q))
          .toList();
    }
    if (selectedGenre != null && selectedGenre!.isNotEmpty) {
      result = result.where((b) => b.genre == selectedGenre).toList();
    }
    switch (sortBy) {
      case 'author':
        result.sort((a, b) => a.author.compareTo(b.author));
        break;
      case 'genre':
        result.sort((a, b) => a.genre.compareTo(b.genre));
        break;
      case 'availability':
        result.sort((a, b) =>
            b.isAvailable ? 1 : -1);
        break;
      default:
        result.sort((a, b) => a.title.compareTo(b.title));
    }
    return result;
  }

  List<BookModel> borrowedBy(String userId) =>
      books.where((b) => b.borrowedBy == userId).toList();
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class BooksNotifier extends StateNotifier<BooksState> {
  BooksNotifier(this.ref) : super(const BooksState()) {
    _loadBooks();
  }

  final Ref ref;
  static const _uuid = Uuid();

  Future<void> _loadBooks() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(AppConstants.booksKey);
    if (json == null) {
      await _seedBooks();
    } else {
      final List decoded = jsonDecode(json);
      state = state.copyWith(
        books: decoded.map((e) => BookModel.fromJson(e)).toList(),
        isLoading: false,
      );
    }
  }

  Future<void> _seedBooks() async {
    final seeded = [
      BookModel(
        id: _uuid.v4(),
        title: 'The Great Gatsby',
        author: 'F. Scott Fitzgerald',
        genre: 'Fiction',
        description:
            'A story of wealth, love, and the American Dream in the 1920s.',
      ),
      BookModel(
        id: _uuid.v4(),
        title: 'Clean Code',
        author: 'Robert C. Martin',
        genre: 'Technology',
        description:
            'A handbook of agile software craftsmanship and best practices.',
      ),
      BookModel(
        id: _uuid.v4(),
        title: 'Sapiens',
        author: 'Yuval Noah Harari',
        genre: 'History',
        description:
            'A brief history of humankind from the Stone Age to modern times.',
      ),
      BookModel(
        id: _uuid.v4(),
        title: 'Dune',
        author: 'Frank Herbert',
        genre: 'Fantasy',
        description:
            'An epic science fiction saga set in the far future amid interstellar politics.',
      ),
      BookModel(
        id: _uuid.v4(),
        title: 'Atomic Habits',
        author: 'James Clear',
        genre: 'Self-Help',
        description:
            'An easy and proven way to build good habits and break bad ones.',
      ),
      BookModel(
        id: _uuid.v4(),
        title: 'The Pragmatic Programmer',
        author: 'David Thomas & Andrew Hunt',
        genre: 'Technology',
        description:
            'Your journey to mastery in software development.',
      ),
      BookModel(
        id: _uuid.v4(),
        title: 'To Kill a Mockingbird',
        author: 'Harper Lee',
        genre: 'Fiction',
        description:
            'A powerful story of racial injustice and moral growth in the American South.',
      ),
      BookModel(
        id: _uuid.v4(),
        title: 'A Brief History of Time',
        author: 'Stephen Hawking',
        genre: 'Science',
        description: 'An exploration of cosmology and the nature of time.',
      ),
    ];
    await _saveBooks(seeded);
    state = state.copyWith(books: seeded, isLoading: false);
  }

  Future<void> _saveBooks(List<BookModel> books) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.booksKey,
      jsonEncode(books.map((b) => b.toJson()).toList()),
    );
  }

  Future<void> addBook(BookModel book) async {
    final updated = [...state.books, book];
    await _saveBooks(updated);
    state = state.copyWith(books: updated);
  }

  Future<void> updateBook(BookModel book) async {
    final updated = state.books.map((b) => b.id == book.id ? book : b).toList();
    await _saveBooks(updated);
    state = state.copyWith(books: updated);
  }

  Future<void> deleteBook(String bookId) async {
    final updated = state.books.where((b) => b.id != bookId).toList();
    await _saveBooks(updated);
    state = state.copyWith(books: updated);
  }

  Future<bool> borrowBook(String bookId, String userId) async {
    final book = state.books.firstWhere((b) => b.id == bookId,
        orElse: () => throw Exception('Book not found'));
    if (!book.isAvailable) return false;

    final updatedBook = book.copyWith(
      isAvailable: false,
      borrowedBy: userId,
      borrowedAt: DateTime.now(),
    );
    await updateBook(updatedBook);

    // Update user's borrowed list
    await _updateUserBorrowedBooks(userId, bookId, add: true);
    await ref.read(authProvider.notifier).refreshCurrentUser();
    return true;
  }

  Future<bool> returnBook(String bookId, String userId) async {
    final book = state.books.firstWhere((b) => b.id == bookId,
        orElse: () => throw Exception('Book not found'));

    final updatedBook = BookModel(
      id: book.id,
      title: book.title,
      author: book.author,
      genre: book.genre,
      description: book.description,
      isAvailable: true,
    );
    await updateBook(updatedBook);

    await _updateUserBorrowedBooks(userId, bookId, add: false);
    await ref.read(authProvider.notifier).refreshCurrentUser();
    return true;
  }

  Future<void> _updateUserBorrowedBooks(String userId, String bookId,
      {required bool add}) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(AppConstants.usersKey);
    if (usersJson == null) return;
    final List decoded = jsonDecode(usersJson);
    final users = decoded.map((e) {
      final u = e as Map<String, dynamic>;
      if (u['id'] == userId) {
        final borrowed = List<String>.from(u['borrowedBookIds'] ?? []);
        if (add) {
          borrowed.add(bookId);
        } else {
          borrowed.remove(bookId);
        }
        return {...u, 'borrowedBookIds': borrowed};
      }
      return u;
    }).toList();
    await prefs.setString(AppConstants.usersKey, jsonEncode(users));
  }

  void setSearch(String query) => state = state.copyWith(searchQuery: query);
  void setGenre(String? genre) =>
      genre == null ? state = state.copyWith(clearGenre: true) : state = state.copyWith(selectedGenre: genre);
  void setSortBy(String sortBy) => state = state.copyWith(sortBy: sortBy);

  Future<void> refresh() => _loadBooks();

  String newId() => _uuid.v4();
}

// ─── Users Notifier for Admin ─────────────────────────────────────────────────

class UsersState {
  final List<UserModel> users;
  final bool isLoading;

  const UsersState({this.users = const [], this.isLoading = false});

  UsersState copyWith({List<UserModel>? users, bool? isLoading}) {
    return UsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class UsersNotifier extends StateNotifier<UsersState> {
  UsersNotifier() : super(const UsersState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(AppConstants.usersKey);
    if (json == null) {
      state = state.copyWith(users: [], isLoading: false);
      return;
    }
    final List decoded = jsonDecode(json);
    state = state.copyWith(
      users: decoded.map((e) => UserModel.fromJson(e)).toList(),
      isLoading: false,
    );
  }

  Future<void> _saveUsers(List<UserModel> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.usersKey,
      jsonEncode(users.map((u) => u.toJson()).toList()),
    );
  }

  Future<void> deleteUser(String userId) async {
    final updated = state.users.where((u) => u.id != userId).toList();
    await _saveUsers(updated);
    state = state.copyWith(users: updated);
  }

  Future<void> updateUser(UserModel user) async {
    final updated =
        state.users.map((u) => u.id == user.id ? user : u).toList();
    await _saveUsers(updated);
    state = state.copyWith(users: updated);
  }

  Future<void> refresh() => _load();
}

// ─── Providers ───────────────────────────────────────────────────────────────

final booksProvider = StateNotifierProvider<BooksNotifier, BooksState>((ref) {
  return BooksNotifier(ref);
});

final usersProvider = StateNotifierProvider<UsersNotifier, UsersState>((ref) {
  return UsersNotifier();
});
