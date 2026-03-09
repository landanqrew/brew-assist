import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// A row of 5 star icons that displays a rating with half-star support.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final IconData icon;
        final Color color;

        if (rating >= starValue) {
          icon = Icons.star;
          color = AppColors.ratingFilled;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half;
          color = AppColors.ratingFilled;
        } else {
          icon = Icons.star_border;
          color = AppColors.ratingEmpty;
        }

        return Icon(icon, size: size, color: color);
      }),
    );
  }
}
