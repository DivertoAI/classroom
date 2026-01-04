import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class ResourceList extends StatelessWidget {
  const ResourceList({super.key});

  @override
  Widget build(BuildContext context) {
    final resources = <_ResourceItem>[
      const _ResourceItem(
        title: 'Quadratic Lab Sheet',
        meta: 'PDF · 3 pages',
        accent: AppPalette.accentWarm,
        icon: Icons.description_outlined,
      ),
      const _ResourceItem(
        title: 'Graphing Demo',
        meta: 'Video · 5:12',
        accent: AppPalette.accent,
        icon: Icons.play_circle_outline,
      ),
      const _ResourceItem(
        title: 'Homework Board',
        meta: 'Interactive · Live',
        accent: Color(0xFF2E4057),
        icon: Icons.auto_graph_outlined,
      ),
      const _ResourceItem(
        title: 'Formula Pack',
        meta: 'Cheat sheet',
        accent: Color(0xFF9B5C2B),
        icon: Icons.book_outlined,
      ),
    ];

    return ListView.separated(
      itemCount: resources.length,
      padding: EdgeInsets.zero,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = resources[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppPalette.wash,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppPalette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.meta,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppPalette.muted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppPalette.muted),
            ],
          ),
        );
      },
    );
  }
}

class _ResourceItem {
  const _ResourceItem({
    required this.title,
    required this.meta,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String meta;
  final Color accent;
  final IconData icon;
}
