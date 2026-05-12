import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../models/book_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/books_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../widgets/shared_widgets.dart';

class UserHomeScreen extends ConsumerStatefulWidget {
  const UserHomeScreen({super.key});

  @override
  ConsumerState<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends ConsumerState<UserHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _page = 0;
  static const int _perPage = 8;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _borrow(BookModel book) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final ok =
        await ref.read(booksProvider.notifier).borrowBook(book.id, user.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              ok ? '"${book.title}" borrowed successfully!' : 'Book unavailable'),
          backgroundColor: ok ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _return(BookModel book) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(booksProvider.notifier).returnBook(book.id, user.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${book.title}" returned successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final booksState = ref.watch(booksProvider);

    final borrowedBooks = user != null
        ? booksState.books.where((b) => b.borrowedBy == user.id).toList()
        : <BookModel>[];

    final allFiltered = booksState.filteredBooks;
    final totalPages = (allFiltered.length / _perPage).ceil().clamp(1, 999);
    final paginated = allFiltered
        .skip(_page * _perPage)
        .take(_perPage)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.menu_book_rounded,
                  color: Colors.white, size: 16.sp),
            ),
            SizedBox(width: 8.w),
            const Text('BookShelf'),
          ],
        ),
        actions: [
          if (user != null)
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: InkWell(
                onTap: () => context.go('/home/profile'),
                borderRadius: BorderRadius.circular(20.r),
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16.r,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          user.username[0].toUpperCase(),
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        user.username,
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.library_books_outlined, size: 18),
                  SizedBox(width: 6.w),
                  const Text('Browse Books'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bookmark_outlined, size: 18),
                  SizedBox(width: 6.w),
                  Text('My Books (${borrowedBooks.length})'),
                ],
              ),
            ),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrowseTab(booksState, paginated, allFiltered.length, totalPages),
          _buildMyBooksTab(borrowedBooks),
        ],
      ),
    );
  }

  Widget _buildBrowseTab(BooksState state, List<BookModel> paginated,
      int total, int totalPages) {
    return Column(
      children: [
        _buildSearchBar(state),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : paginated.isEmpty
                  ? EmptyStateWidget(
                      title: 'No books found',
                      subtitle: 'Try a different search or filter',
                      icon: Icons.search_off_outlined,
                    )
                  : _buildBookGrid(paginated),
        ),
        if (total > _perPage) _buildPagination(total, totalPages),
      ],
    );
  }

  Widget _buildSearchBar(BooksState state) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44.h,
                  child: TextField(
                    onChanged: (v) {
                      ref.read(booksProvider.notifier).setSearch(v);
                      setState(() => _page = 0);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by title, author or genre...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10.h),
                      hintStyle: TextStyle(fontSize: 13.sp),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              PopupMenuButton<String>(
                icon: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10.r),
                    color: AppColors.surface,
                  ),
                  child: const Icon(Icons.sort_outlined, size: 20),
                ),
                onSelected: (v) {
                  ref.read(booksProvider.notifier).setSortBy(v);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'title', child: Text('Sort by Title')),
                  const PopupMenuItem(value: 'author', child: Text('Sort by Author')),
                  const PopupMenuItem(value: 'genre', child: Text('Sort by Genre')),
                  const PopupMenuItem(
                      value: 'availability',
                      child: Text('Sort by Availability')),
                ],
              ),
            ],
          ),
          SizedBox(height: 10.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _genreChip(null, state.selectedGenre, 'All'),
                ...AppConstants.genres.map(
                    (g) => _genreChip(g, state.selectedGenre, g)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _genreChip(String? genre, String? selected, String label) {
    final isSelected = genre == selected;
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          if (genre == null) {
            ref.read(booksProvider.notifier).setGenre(null);
          } else {
            ref.read(booksProvider.notifier).setGenre(isSelected ? null : genre);
          }
          setState(() => _page = 0);
        },
        selectedColor: AppColors.primaryLight,
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          fontSize: 12.sp,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight:
              isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildBookGrid(List<BookModel> books) {
    final user = ref.read(currentUserProvider);
    return LayoutBuilder(builder: (context, constraints) {
      final crossAxis = constraints.maxWidth > 900
          ? 4
          : constraints.maxWidth > 600
              ? 3
              : constraints.maxWidth > 400
                  ? 2
                  : 1;
      return GridView.builder(
        padding: EdgeInsets.all(16.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxis,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 0.72,
        ),
        itemCount: books.length,
        itemBuilder: (_, i) => _buildBookCard(books[i], user?.id),
      );
    });
  }

  Widget _buildBookCard(BookModel book, String? userId) {
    final isBorrowedByMe = book.borrowedBy == userId;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookAvatar(title: book.title, size: 48),
            SizedBox(height: 10.h),
            Text(
              book.title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 3.h),
            Text(
              book.author,
              style:
                  TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 6.h),
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                book.genre,
                style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const Spacer(),
            StatusBadge(isAvailable: book.isAvailable),
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isBorrowedByMe
                    ? () => _return(book)
                    : book.isAvailable
                        ? () => _borrow(book)
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBorrowedByMe
                      ? AppColors.warning
                      : AppColors.primary,
                  padding:
                      EdgeInsets.symmetric(vertical: 8.h),
                  textStyle: TextStyle(fontSize: 12.sp),
                ),
                child: Text(
                    isBorrowedByMe ? 'Return' : 'Borrow'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(int total, int totalPages) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Page ${_page + 1} of $totalPages  •  $total books',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
          SizedBox(width: 16.w),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _page > 0
                ? () => setState(() => _page--)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _page < totalPages - 1
                ? () => setState(() => _page++)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMyBooksTab(List<BookModel> borrowed) {
    if (borrowed.isEmpty) {
      return const EmptyStateWidget(
        title: 'No borrowed books',
        subtitle: 'Browse the library and borrow some books!',
        icon: Icons.bookmark_border_outlined,
      );
    }
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: borrowed.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (_, i) => _buildBorrowedBookCard(borrowed[i]),
    );
  }

  Widget _buildBorrowedBookCard(BookModel book) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            BookAvatar(title: book.title, size: 52),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title,
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2.h),
                  Text(book.author,
                      style: TextStyle(
                          fontSize: 12.sp, color: AppColors.textSecondary)),
                  SizedBox(height: 6.h),
                  if (book.borrowedAt != null)
                    Text(
                      'Borrowed on ${_formatDate(book.borrowedAt!)}',
                      style: TextStyle(
                          fontSize: 11.sp, color: AppColors.textHint),
                    ),
                ],
              ),
            ),
            AppButton(
              label: 'Return',
              onPressed: () => _return(book),
              backgroundColor: AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}
