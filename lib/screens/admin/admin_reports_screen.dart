import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../providers/books_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksState = ref.watch(booksProvider);
    final usersState = ref.watch(usersProvider);

    final books = booksState.books;
    final users = usersState.users;

    final totalBooks = books.length;
    final availableBooks = books.where((b) => b.isAvailable).length;
    final borrowedBooks = books.where((b) => !b.isAvailable).length;

    final genreMap = <String, int>{};
    for (final b in books) {
      genreMap[b.genre] = (genreMap[b.genre] ?? 0) + 1;
    }
    final genreSorted = genreMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final currentlyBorrowed = books.where((b) => !b.isAvailable).toList();

    final activeUsers = users.where((u) =>
        books.any((b) => b.borrowedBy == u.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1000.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overview', style: Theme.of(context).textTheme.headlineSmall),
                SizedBox(height: 12.h),
                LayoutBuilder(builder: (context, constraints) {
                  final cols = constraints.maxWidth > 600 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: cols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 1.1,
                    children: [
                      StatCard(
                        label: 'Total Books',
                        value: '$totalBooks',
                        icon: Icons.library_books_outlined,
                        color: AppColors.primary,
                      ),
                      StatCard(
                        label: 'Available',
                        value: '$availableBooks',
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                      StatCard(
                        label: 'Borrowed',
                        value: '$borrowedBooks',
                        icon: Icons.bookmark_outlined,
                        color: AppColors.warning,
                      ),
                      StatCard(
                        label: 'Active Users',
                        value: '${activeUsers.length}',
                        icon: Icons.people_outline,
                        color: AppColors.secondary,
                      ),
                    ],
                  );
                }),
                SizedBox(height: 24.h),

                Text('Books by Genre',
                    style: Theme.of(context).textTheme.headlineSmall),
                SizedBox(height: 12.h),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: genreSorted.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.w),
                              child: Text('No data available',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                            ),
                          )
                        : Column(
                            children: genreSorted.map((entry) {
                              final pct = totalBooks > 0
                                  ? entry.value / totalBooks
                                  : 0.0;
                              return Padding(
                                padding:
                                    EdgeInsets.symmetric(vertical: 6.h),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          '${entry.value} books (${(pct * 100).toStringAsFixed(0)}%)',
                                          style: TextStyle(
                                              fontSize: 12.sp,
                                              color:
                                                  AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6.h),
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(4.r),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        minHeight: 8.h,
                                        backgroundColor: AppColors.border,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ),
                SizedBox(height: 24.h),

                Text('Currently Borrowed Books',
                    style: Theme.of(context).textTheme.headlineSmall),
                SizedBox(height: 12.h),
                currentlyBorrowed.isEmpty
                    ? Card(
                        child: Padding(
                          padding: EdgeInsets.all(24.w),
                          child: Center(
                            child: Text('No books currently borrowed.',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                          ),
                        ),
                      )
                    : Card(
                        child: Column(
                          children: currentlyBorrowed.map((book) {
                            final borrower = users.where(
                                (u) => u.id == book.borrowedBy);
                            final borrowerName = borrower.isNotEmpty
                                ? borrower.first.username
                                : 'Unknown';
                            return ListTile(
                              leading: BookAvatar(
                                  title: book.title, size: 40),
                              title: Text(book.title,
                                  style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  '${book.author} • Borrowed by: $borrowerName',
                                  style: TextStyle(fontSize: 12.sp)),
                              trailing: book.borrowedAt != null
                                  ? Text(
                                      '${book.borrowedAt!.day}/${book.borrowedAt!.month}/${book.borrowedAt!.year}',
                                      style: TextStyle(
                                          fontSize: 11.sp,
                                          color: AppColors.textHint),
                                    )
                                  : null,
                            );
                          }).toList(),
                        ),
                      ),
                SizedBox(height: 24.h),

            
                Text('Active Users',
                    style: Theme.of(context).textTheme.headlineSmall),
                SizedBox(height: 12.h),
                activeUsers.isEmpty
                    ? Card(
                        child: Padding(
                          padding: EdgeInsets.all(24.w),
                          child: Center(
                            child: Text('No active users.',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                          ),
                        ),
                      )
                    : Card(
                        child: Column(
                          children: activeUsers.map((user) {
                            final count = books
                                .where((b) => b.borrowedBy == user.id)
                                .length;
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 20.r,
                                backgroundColor: user.role == 'Admin'
                                    ? AppColors.adminColor
                                    : AppColors.primary,
                                child: Text(
                                  user.username[0].toUpperCase(),
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp),
                                ),
                              ),
                              title: Text(user.username,
                                  style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(user.email,
                                  style: TextStyle(fontSize: 12.sp)),
                              trailing: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius:
                                      BorderRadius.circular(20.r),
                                ),
                                child: Text(
                                  '$count books',
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
