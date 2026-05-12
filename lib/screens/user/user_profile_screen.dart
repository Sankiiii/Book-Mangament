import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/books_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final booksState = ref.watch(booksProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final borrowed =
        booksState.books.where((b) => b.borrowedBy == user.id).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.logout_outlined, size: 18),
            label: const Text('Logout'),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 700.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile card
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36.r,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            user.username[0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: 20.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.username,
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                user.email,
                                style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppColors.textSecondary),
                              ),
                              SizedBox(height: 8.h),
                              RoleBadge(role: user.role),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Stats
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Books Borrowed',
                        value: '${borrowed.length}',
                        icon: Icons.bookmark_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: StatCard(
                        label: 'Total Borrowed',
                        value: '${user.borrowedBookIds.length}',
                        icon: Icons.history_outlined,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Currently borrowed
                SectionHeader(title: 'Currently Borrowed'),
                SizedBox(height: 12.h),
                if (borrowed.isEmpty)
                  Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Text(
                        'No books currently borrowed.',
                        style: TextStyle(
                            fontSize: 14.sp, color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ...borrowed.map(
                    (book) => Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: Card(
                        child: ListTile(
                          leading: BookAvatar(title: book.title, size: 42),
                          title: Text(book.title,
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(book.author,
                              style: TextStyle(fontSize: 12.sp)),
                          trailing: book.borrowedAt != null
                              ? Text(
                                  '${book.borrowedAt!.day}/${book.borrowedAt!.month}/${book.borrowedAt!.year}',
                                  style: TextStyle(
                                      fontSize: 11.sp,
                                      color: AppColors.textHint),
                                )
                              : null,
                        ),
                      ),
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
