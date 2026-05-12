import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../models/book_model.dart';
import '../../providers/books_provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class AdminBooksScreen extends ConsumerStatefulWidget {
  const AdminBooksScreen({super.key});

  @override
  ConsumerState<AdminBooksScreen> createState() => _AdminBooksScreenState();
}

class _AdminBooksScreenState extends ConsumerState<AdminBooksScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showBookDialog({BookModel? existing}) {
    final titleCtrl =
        TextEditingController(text: existing?.title ?? '');
    final authorCtrl =
        TextEditingController(text: existing?.author ?? '');
    final descCtrl =
        TextEditingController(text: existing?.description ?? '');
    String genre = existing?.genre ?? AppConstants.genres.first;
    bool available = existing?.isAvailable ?? true;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(
            existing == null ? 'Add New Book' : 'Edit Book',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 420.w,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      label: 'Book Title',
                      hint: 'Enter book title',
                      controller: titleCtrl,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Title is required'
                          : null,
                    ),
                    SizedBox(height: 14.h),
                    AppTextField(
                      label: 'Author',
                      hint: 'Enter author name',
                      controller: authorCtrl,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Author is required'
                          : null,
                    ),
                    SizedBox(height: 14.h),
                    AppDropdown<String>(
                      label: 'Genre',
                      value: genre,
                      items: AppConstants.genres
                          .map((g) =>
                              DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => setS(() => genre = v!),
                      validator: (v) => v == null ? 'Genre required' : null,
                    ),
                    SizedBox(height: 14.h),
                    AppTextField(
                      label: 'Description',
                      hint: 'Enter book description',
                      controller: descCtrl,
                      maxLines: 3,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Description is required'
                          : null,
                    ),
                    SizedBox(height: 14.h),
                    Row(
                      children: [
                        Text('Available',
                            style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Switch(
                          value: available,
                          onChanged: (v) => setS(() => available = v),
                          activeColor: AppColors.success,
                        ),
                      ],
                    ),
                  ],
                ),
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
                final notifier = ref.read(booksProvider.notifier);
                if (existing == null) {
                  await notifier.addBook(BookModel(
                    id: notifier.newId(),
                    title: titleCtrl.text.trim(),
                    author: authorCtrl.text.trim(),
                    genre: genre,
                    description: descCtrl.text.trim(),
                    isAvailable: available,
                  ));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Book added successfully!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } else {
                  await notifier.updateBook(existing.copyWith(
                    title: titleCtrl.text.trim(),
                    author: authorCtrl.text.trim(),
                    genre: genre,
                    description: descCtrl.text.trim(),
                    isAvailable: available,
                  ));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Book updated successfully!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(existing == null ? 'Add Book' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteBook(BookModel book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text(
          'Are you sure you want to delete "${book.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(booksProvider.notifier).deleteBook(book.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book deleted'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booksState = ref.watch(booksProvider);
    final filtered = booksState.filteredBooks;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: AppButton(
              label: 'Add Book',
              icon: Icons.add,
              onPressed: () => _showBookDialog(),
            ),
          ),
        ],
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
                      controller: _searchCtrl,
                      onChanged: (v) =>
                          ref.read(booksProvider.notifier).setSearch(v),
                      decoration: InputDecoration(
                        hintText: 'Search books...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        hintStyle: TextStyle(fontSize: 13.sp),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10.h),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  '${filtered.length} books',
                  style: TextStyle(
                      fontSize: 13.sp, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: booksState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? EmptyStateWidget(
                        title: 'No books found',
                        subtitle: 'Add some books to get started',
                        icon: Icons.library_books_outlined,
                        actionLabel: 'Add Book',
                        onAction: () => _showBookDialog(),
                      )
                    : LayoutBuilder(builder: (context, constraints) {
                        if (constraints.maxWidth > 700) {
                          return _buildTable(filtered);
                        }
                        return _buildList(filtered);
                      }),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<BookModel> books) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Card(
        child: DataTable(
          columnSpacing: 20.w,
          headingRowColor: WidgetStateProperty.all(AppColors.primaryLight),
          columns: const [
            DataColumn(label: Text('Title')),
            DataColumn(label: Text('Author')),
            DataColumn(label: Text('Genre')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: books.map((book) {
            return DataRow(cells: [
              DataCell(Row(
                children: [
                  BookAvatar(title: book.title, size: 32),
                  SizedBox(width: 10.w),
                  Flexible(
                    child: Text(
                      book.title,
                      style: TextStyle(
                          fontSize: 13.sp, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )),
              DataCell(Text(book.author,
                  style: TextStyle(fontSize: 13.sp))),
              DataCell(Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(book.genre,
                    style: TextStyle(
                        fontSize: 11.sp, color: AppColors.primary)),
              )),
              DataCell(StatusBadge(isAvailable: book.isAvailable)),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.primary),
                    tooltip: 'Edit',
                    onPressed: () => _showBookDialog(existing: book),
                    iconSize: 20.sp,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                    tooltip: 'Delete',
                    onPressed: () => _deleteBook(book),
                    iconSize: 20.sp,
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildList(List<BookModel> books) {
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: books.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (_, i) {
        final book = books[i];
        return Card(
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                BookAvatar(title: book.title, size: 44),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title,
                          style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 2.h),
                      Text(book.author,
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary)),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(book.genre,
                                style: TextStyle(
                                    fontSize: 10.sp,
                                    color: AppColors.primary)),
                          ),
                          SizedBox(width: 8.w),
                          StatusBadge(isAvailable: book.isAvailable),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.primary),
                      onPressed: () => _showBookDialog(existing: book),
                      iconSize: 20.sp,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error),
                      onPressed: () => _deleteBook(book),
                      iconSize: 20.sp,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
