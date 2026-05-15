import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/books_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _search = '';

  Future<void> _deleteUser(UserModel user) async {
    final current = ref.read(currentUserProvider);
    if (current?.id == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot delete your own account.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete "${user.username}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(usersProvider.notifier).deleteUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User deleted'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showEditDialog(UserModel user) {
    final usernameCtrl = TextEditingController(text: user.username);
    final emailCtrl = TextEditingController(text: user.email);
    String role = user.role;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(
            'Edit User',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 380.w,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    label: 'Username',
                    controller: usernameCtrl,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Username required' : null,
                  ),
                  SizedBox(height: 14.h),
                  AppTextField(
                    label: 'Email',
                    controller: emailCtrl,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Email required' : null,
                  ),
                  SizedBox(height: 14.h),
                  AppDropdown<String>(
                    label: 'Role',
                    value: role,
                    items: ['User', 'Admin']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setS(() => role = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await ref
                    .read(usersProvider.notifier)
                    .updateUser(
                      user.copyWith(
                        username: usernameCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        role: role,
                      ),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User updated!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(usersProvider);
    final booksState = ref.watch(booksProvider);

    final filtered = usersState.users.where((u) {
      final q = _search.toLowerCase();
      return q.isEmpty ||
          u.username.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.role.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44.h,
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        hintStyle: TextStyle(fontSize: 13.sp),
                        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  '${filtered.length} users',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: usersState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? const EmptyStateWidget(
                    title: 'No users found',
                    subtitle: 'Try a different search',
                    icon: Icons.people_outline,
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 700) {
                        return _buildTable(filtered, booksState.books);
                      }
                      return _buildList(filtered, booksState.books);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<UserModel> users, List books) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Card(
        child: DataTable(
          columnSpacing: 16.w,
          headingRowColor: WidgetStateProperty.all(AppColors.primaryLight),
          columns: const [
            DataColumn(label: Text('User')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Borrowed')),
            DataColumn(label: Text('Actions')),
          ],
          rows: users.map((user) {
            final borrowedCount = books
                .where((b) => b.borrowedBy == user.id)
                .length;
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16.r,
                        backgroundColor: user.role == 'Admin'
                            ? AppColors.adminColor
                            : AppColors.primary,
                        child: Text(
                          user.username[0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        user.username,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(user.email, style: TextStyle(fontSize: 13.sp))),
                DataCell(RoleBadge(role: user.role)),
                DataCell(
                  Text('$borrowedCount', style: TextStyle(fontSize: 13.sp)),
                ),

                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.primary,
                        ),
                        onPressed: () => _showEditDialog(user),
                        iconSize: 20.sp,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        onPressed: () => _deleteUser(user),
                        iconSize: 20.sp,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildList(List<UserModel> users, List books) {
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: users.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (_, i) {
        final user = users[i];
        final borrowedCount = books
            .where((b) => b.borrowedBy == user.id)
            .length;
        final borrowBookList = books
            .where((b) => b.borrowedBy == user.id)
            .toList();

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              radius: 22.r,
              backgroundColor: user.role == 'Admin'
                  ? AppColors.adminColor
                  : AppColors.primary,
              child: Text(
                user.username[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  user.username,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8.w),
                RoleBadge(role: user.role),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '$borrowedCount books borrowed',
                  style: TextStyle(fontSize: 11.sp, color: AppColors.textHint),
                ),
                Text(
                  "Borrowed: ${borrowBookList.map((b) => b.title).join(', ')}",
                  style: TextStyle(fontSize: 11.sp, color: AppColors.textHint),
                ),
              ],
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _showEditDialog(user),
                  iconSize: 20.sp,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  onPressed: () => _deleteUser(user),
                  iconSize: 20.sp,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
