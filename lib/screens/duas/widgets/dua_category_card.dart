import 'package:flutter/material.dart';

import '../../../models/dua_model.dart';

class DuaCategoryCard extends StatelessWidget {
  const DuaCategoryCard({
    super.key,
    required this.category,
    required this.count,
    required this.onTap,
  });

  final DuaCategory category;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: t.colorScheme.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 8),
              Text(
                category.label,
                textAlign: TextAlign.center,
                style: t.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text('$count', style: t.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
