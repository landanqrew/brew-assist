import 'package:flutter/material.dart';

import 'toggle_pill.dart';

/// A row of toggle pills for switching between profile content tabs.
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
          TogglePill(
            label: labels[i],
            selected: i == selectedIndex,
            onTap: () => onSelected(i),
          ),
        ],
      ],
    );
  }
}
