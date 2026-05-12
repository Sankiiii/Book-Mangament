import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/books_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final booksState = ref.watch(booksProvider);
    final usersState = ref.watch(usersProvider);

    final totalBooks = booksState.books.length;
    final availableBooks = booksState.books.where((b) => b.isAvailable).length;
    final borrowedBooks = totalBooks - availableBooks;
    final totalUsers = usersState.users.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: AppColors.adminColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 16.sp,
              ),
            ),
            SizedBox(width: 8.w),
            const Text('Admin Dashboard'),
          ],
        ),
        actions: [
          if (user != null)
            Padding(
              padding: EdgeInsets.only(right: 4.w),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15.r,
                    backgroundColor: AppColors.adminColor,
                    child: Text(
                      user.username[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1200.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.adminColor, Color(0xFF9F3DE8)],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${user?.username ?? 'Admin'}!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Manage your library from here.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth > 600 ? 4 : 2;
                    return GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                      childAspectRatio: 1.2,
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
                          label: 'Total Users',
                          value: '$totalUsers',
                          icon: Icons.people_outline,
                          color: AppColors.secondary,
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 20.h),

                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 12.h),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth > 600 ? 4 : 2;
                    return GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                      childAspectRatio: 1.5,
                      children: [
                        _actionCard(
                          context,
                          icon: Icons.library_add_outlined,
                          label: 'Manage Books',
                          color: AppColors.primary,
                          onTap: () => context.go('/admin/books'),
                        ),
                        _actionCard(
                          context,
                          icon: Icons.people_outline,
                          label: 'Manage Users',
                          color: AppColors.secondary,
                          onTap: () => context.go('/admin/users'),
                        ),
                        _actionCard(
                          context,
                          icon: Icons.bar_chart_outlined,
                          label: 'Reports',
                          color: AppColors.success,
                          onTap: () => context.go('/admin/reports'),
                        ),
                        _actionCard(
                          context,
                          icon: Icons.refresh_outlined,
                          label: 'Refresh Data',
                          color: AppColors.warning,
                          onTap: () {
                            ref.read(booksProvider.notifier).refresh();
                            ref.read(usersProvider.notifier).refresh();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Data refreshed!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 20.h),

                SectionHeader(
                  title: 'Recent Books',
                  actionLabel: 'View All',
                  onAction: () => context.go('/admin/books'),
                ),
                SizedBox(height: 12.h),
                ...booksState.books
                    .take(5)
                    .map(
                      (book) => Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Card(
                          child: ListTile(
                            leading: BookAvatar(title: book.title, size: 42),
                            title: Text(
                              book.title,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${book.author} • ${book.genre}',
                              style: TextStyle(fontSize: 12.sp),
                            ),
                            trailing: StatusBadge(
                              isAvailable: book.isAvailable,
                            ),
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

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: color, size: 22.sp),
              ),
              SizedBox(height: 10.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
