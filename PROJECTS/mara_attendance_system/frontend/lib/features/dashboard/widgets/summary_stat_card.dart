import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';

class SummaryStatItem {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const SummaryStatItem({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });
}

class SummaryStatCard extends StatelessWidget {
  final SummaryStatItem item;

  const SummaryStatCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      border: Border.all(color: item.color.withValues(alpha: 0.14)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: item.color == AppColors.primary
                        ? AppColors.text
                        : item.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryStatGrid extends StatelessWidget {
  final List<SummaryStatItem> items;

  const SummaryStatGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        if (isWide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: SummaryStatCard(item: items[i])),
                ],
              ],
            ),
          );
        }

        return Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              SummaryStatCard(item: items[i]),
            ],
          ],
        );
      },
    );
  }
}
