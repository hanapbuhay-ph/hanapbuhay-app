import 'package:flutter/material.dart';

class StatusFilterChips<T> extends StatelessWidget {
  final List<T> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String Function(T item) labelBuilder;
  final int Function(T item) countBuilder;
  final Color Function(T item, ColorScheme colorScheme) colorBuilder;

  const StatusFilterChips({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.labelBuilder,
    required this.countBuilder,
    required this.colorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = selectedIndex == index;
          final count = countBuilder(item);
          final color = colorBuilder(item, colorScheme);

          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : colorScheme.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.onPrimary : color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    labelBuilder(item),
                    style: TextStyle(
                      color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? colorScheme.onPrimary.withValues(alpha: 0.25) : color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isSelected ? colorScheme.onPrimary : color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
