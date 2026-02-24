import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// A primary call-to-action button with the accent gradient and glowing shadow.
///
/// Use for the main submit action on a screen (e.g. "Create Recipe",
/// "Check In"). Falls back to a disabled gray when [onPressed] is null.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 52,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final double height;
  final bool isLoading;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: _enabled ? AppColors.accentGradient : null,
        color: _enabled ? null : AppColors.disabled,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _enabled ? AppColors.primaryGlow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.white,
                    ),
                  )
                : DefaultTextStyle(
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.white,
                    ),
                    child: child,
                  ),
          ),
        ),
      ),
    );
  }
}
