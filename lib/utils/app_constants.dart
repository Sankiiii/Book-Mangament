class AppConstants {
  static const String appName = 'BookShelf';
  static const String appTagline = 'Your Digital Library';

  // Routes
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String userHomeRoute = '/home';
  static const String adminHomeRoute = '/admin';
  static const String profileRoute = '/profile';
  static const String adminBooksRoute = '/admin/books';
  static const String adminUsersRoute = '/admin/users';
  static const String adminReportsRoute = '/admin/reports';

  // Storage Keys
  static const String currentUserKey = 'current_user';
  static const String usersKey = 'users_data';
  static const String booksKey = 'books_data';

  // Roles
  static const String roleUser = 'User';
  static const String roleAdmin = 'Admin';

  // Genres
  static const List<String> genres = [
    'Fiction',
    'Non-Fiction',
    'Science',
    'Technology',
    'History',
    'Biography',
    'Mystery',
    'Romance',
    'Fantasy',
    'Self-Help',
    'Philosophy',
    'Art',
  ];
}
