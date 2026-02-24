import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/entities/day_summary.dart';

class DaySummaryTile extends StatelessWidget {
  const DaySummaryTile({
    super.key,
    required this.summary,
    required this.onEdit,
  });

  final DaySummary summary;
  final VoidCallback onEdit;

  /// Maximum number of entry descriptions to show before truncating.
  static const _maxVisibleEntries = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date column ──────────────────────────────────────────
            SizedBox(
              width: 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEE').format(summary.date),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: colorScheme.primary),
                  ),
                  Text(
                    DateFormat('d').format(summary.date),
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat('MMM').format(summary.date),
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.entryCount} ${summary.entryCount == 1 ? 'entry' : 'entries'}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: colorScheme.outline),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ── Macro grid ───────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _MacroChip(
                      emoji: '🔥',
                      value: summary.totalCalories,
                      unit: 'kcal',
                    ),
                    const SizedBox(width: 8),
                    _MacroChip(
                      emoji: '🥩',
                      value: summary.totalProtein,
                      unit: 'g protein',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _MacroChip(
                      emoji: '🥑',
                      value: summary.totalFat,
                      unit: 'g fat',
                    ),
                    const SizedBox(width: 8),
                    _MacroChip(
                      emoji: '🌾',
                      value: summary.totalCarbohydrates,
                      unit: 'g carbs',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 16),
            // ── Entry descriptions ───────────────────────────────────
            Expanded(
              child: summary.entryTexts.isNotEmpty
                  ? _EntryTextsList(
                      texts: summary.entryTexts,
                      maxVisible: _maxVisibleEntries,
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            // ── Edit button ──────────────────────────────────────────
            OutlinedButton(
              onPressed: onEdit,
              child: const Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays a list of entry descriptions with overflow handling.
/// Shows up to [maxVisible] entries, then a "+N more" indicator.
class _EntryTextsList extends StatelessWidget {
  const _EntryTextsList({
    required this.texts,
    required this.maxVisible,
  });

  final List<String> texts;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final visibleTexts = texts.take(maxVisible).toList();
    final remaining = texts.length - maxVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final text in visibleTexts)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                Expanded(
                  child: Text(
                    text,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        if (remaining > 0)
          Text(
            '+$remaining more',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.emoji,
    required this.value,
    required this.unit,
  });

  final String emoji;
  final double value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final formatted = value >= 1000
        ? '${(value / 1000).toStringAsFixed(1)}k'
        : value.toStringAsFixed(0);
    return Text(
      '$emoji $formatted $unit',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

