import 'package:flutter/material.dart';

import '../../../../data/models/meal_entry_model.dart';

class MealEntryTile extends StatelessWidget {
  const MealEntryTile({
    super.key,
    required this.index,
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  final int index;
  final MealEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(child: Text('${index + 1}')),
        title: Text(
          entry.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Cal: ${entry.calories.toStringAsFixed(0)}  '
          'Pro: ${entry.protein.toStringAsFixed(0)}g  '
          'Fat: ${entry.totalFat.toStringAsFixed(0)}g  '
          'Carbs: ${entry.carbohydrates.toStringAsFixed(0)}g',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        onLongPress: () => _confirmDelete(context),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text(
          '"${entry.text}" will be permanently removed.',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete();
  }
}

