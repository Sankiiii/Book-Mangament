import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_theme.dart';


class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            width: 20.w,
            height: 20.w,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: isOutlined ? AppColors.primary : Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18.sp),
                SizedBox(width: 8.w),
              ],
              Text(label),
            ],
          );

    if (isOutlined) {
      return SizedBox(
        width: width,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor ?? AppColors.primary,
            side: BorderSide(
                color: foregroundColor ?? AppColors.primary),
          ),
          child: child,
        ),
      );
    }
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: foregroundColor ?? Colors.white,
        ),
        child: child,
      ),
    );
  }
}


class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int maxLines;
  final bool enabled;
  final void Function(String)? onChanged;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 13.sp,
              ),
        ),
        SizedBox(height: 6.h),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          enabled: enabled,
          onChanged: onChanged,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
          ),
        ),
      ],
    );
  }
}


class AppDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;

  const AppDropdown({
    super.key,
    required this.label,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 13.sp,
              ),
        ),
        SizedBox(height: 6.h),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontSize: 14.sp),
          decoration: const InputDecoration(),
        ),
      ],
    );
  }
}


class StatusBadge extends StatelessWidget {
  final bool isAvailable;

  const StatusBadge({super.key, required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isAvailable
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              color: isAvailable ? AppColors.success : AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 5.w),
          Text(
            isAvailable ? 'Available' : 'Borrowed',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: isAvailable ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}


class RoleBadge extends StatelessWidget {
  final String role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'Admin';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: (isAdmin ? AppColors.adminColor : AppColors.userColor)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: isAdmin ? AppColors.adminColor : AppColors.userColor,
        ),
      ),
    );
  }
}


class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(icon, size: 36.sp, color: AppColors.primary),
            ),
            SizedBox(height: 20.h),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 24.h),
              AppButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}


class BookAvatar extends StatelessWidget {
  final String title;
  final double size;

  const BookAvatar({super.key, required this.title, this.size = 48});

  Color _colorFromTitle(String title) {
    const colors = [
      Color(0xFF4F46E5),
      Color(0xFF0891B2),
      Color(0xFF7C3AED),
      Color(0xFF059669),
      Color(0xFFDC2626),
      Color(0xFFD97706),
      Color(0xFF0D9488),
    ];
    final idx = title.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[idx];
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFromTitle(title);
    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Center(
        child: Text(
          title.isNotEmpty ? title[0].toUpperCase() : 'B',
          style: TextStyle(
            fontSize: (size * 0.4).sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}


class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}


class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
