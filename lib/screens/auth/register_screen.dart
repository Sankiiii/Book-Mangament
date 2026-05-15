import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  Future<void> _signInWithGoogle(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!success && context.mounted) {
      final error = ref.read(authProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Google sign-in failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Container(
              constraints: BoxConstraints(maxWidth: 420.w),
              padding: EdgeInsets.all(28.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.primary,
                    size: 44.sp,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Create your account with Google',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  OutlinedButton.icon(
                    onPressed: authState.isLoading
                        ? null
                        : () => _signInWithGoogle(context, ref),
                    icon: authState.isLoading
                        ? SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.login, size: 20.sp),
                    label: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Text(
                        authState.isLoading
                            ? 'Signing in...'
                            : 'Continue with Google',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
