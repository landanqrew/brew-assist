import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// A row of toggle pills for switching between profile content tabs.
///
/// Follows the same visual pattern as `_TogglePill` in `feed_screen.dart`.
class ProfileTabBar extends StatelessWidget {
  const ProfileTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: i == selectedIndex
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                labels[i],
                style: AppTextStyles.bodySmall.copyWith(
                  color: i == selectedIndex
                      ? AppColors.white
                      : AppColors.textSecondary,
                  fontWeight:
                      i == selectedIndex ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
