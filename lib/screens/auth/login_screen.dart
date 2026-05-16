import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _adminFormKey = GlobalKey<FormState>();
  final _adminUsernameController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  bool _hideAdminPassword = true;

  @override
  void dispose() {
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!success && mounted) {
      final error = ref.read(authProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Google sign-in failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _signInAsAdmin() async {
    if (!_adminFormKey.currentState!.validate()) return;

    final success = await ref
        .read(authProvider.notifier)
        .signInAsAdmin(
          username: _adminUsernameController.text,
          password: _adminPasswordController.text,
        );
    if (!success && mounted) {
      final error = ref.read(authProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Admin login failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? size.width * 0.2 : 24.w,
              vertical: 32.h,
            ),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _buildHero()),
                      SizedBox(width: 48.w),
                      Expanded(child: _buildForm(authState)),
                    ],
                  )
                : Column(
                    children: [
                      _buildHero(),
                      SizedBox(height: 32.h),
                      _buildForm(authState),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(
            Icons.menu_book_rounded,
            color: Colors.white,
            size: 28.sp,
          ),
        ),
        SizedBox(height: 20.h),
        Text(
          AppConstants.appName,
          style: TextStyle(
            fontSize: 32.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Your digital library,\nanytime, anywhere.',
          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        SizedBox(height: 24.h),
        _buildAuthNote(),
      ],
    );
  }

  Widget _buildAuthNote() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 18.sp,
            color: AppColors.primary,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Use Google Authentication to sign in. New accounts are created as User by default.',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AuthState authState) {
    return Container(
      padding: EdgeInsets.all(28.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Sign in to your account',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
          ),
          SizedBox(height: 24.h),
          _buildGoogleLogin(authState),
          SizedBox(height: 22.h),
          _buildDividerLabel('Admin login'),
          SizedBox(height: 18.h),
          _buildAdminLogin(authState),
        ],
      ),
    );
  }

  Widget _buildGoogleLogin(AuthState authState) {
    return OutlinedButton.icon(
      key: const ValueKey('google-login'),
      onPressed: authState.isLoading ? null : _signInWithGoogle,
      icon: authState.isLoading
          ? SizedBox(
              width: 18.w,
              height: 18.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.login, size: 20.sp),
      label: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Text(
          authState.isLoading ? 'Signing in...' : 'Continue with Google',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildDividerLabel(String label) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildAdminLogin(AuthState authState) {
    return Form(
      key: _adminFormKey,
      child: Column(
        key: const ValueKey('admin-login'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Admin username',
            hint: 'Enter admin username',
            controller: _adminUsernameController,
            prefixIcon: const Icon(Icons.person_outline),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Username required'
                : null,
          ),
          SizedBox(height: 14.h),
          AppTextField(
            label: 'Password',
            hint: 'Enter password',
            controller: _adminPasswordController,
            obscureText: _hideAdminPassword,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _hideAdminPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() => _hideAdminPassword = !_hideAdminPassword);
              },
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Password required' : null,
          ),
          SizedBox(height: 18.h),
          AppButton(
            label: authState.isLoading ? 'Signing in...' : 'Login as Admin',
            icon: Icons.admin_panel_settings_outlined,
            isLoading: authState.isLoading,
            backgroundColor: AppColors.adminColor,
            onPressed: authState.isLoading ? null : _signInAsAdmin,
          ),
          SizedBox(height: 12.h),
          Text(
            'Default admin: ${AppConstants.adminUsername} / ${AppConstants.adminPassword}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.sp, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
