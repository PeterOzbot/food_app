import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/day_summary.dart';
import '../../providers/day_detail_provider.dart';
import 'widgets/meal_entry_tile.dart';

class DayDetailScreen extends ConsumerWidget {
  const DayDetailScreen({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dayDetailProvider(date));
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final title = DateFormat('EEEE, d MMMM yyyy').format(date);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'day_detail_fab',
        onPressed: () => context.push('/meal/new?date=$dateStr'),
        tooltip: 'New meal entry',
        child: const Icon(Icons.add),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Failed to load:\n$e', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(dayDetailProvider(date)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (entries) {
          // Build an on-the-fly DaySummary from entries for the summary card
          final summary = entries.isEmpty
              ? null
              : DaySummary(
                  date: date,
                  entryCount: entries.length,
                  totalCalories: entries.fold(0, (s, e) => s + e.calories),
                  totalProtein: entries.fold(0, (s, e) => s + e.protein),
                  totalFat: entries.fold(0, (s, e) => s + e.totalFat),
                  totalCarbohydrates:
                      entries.fold(0, (s, e) => s + e.carbohydrates),
                );

          return ListView(
            children: [
              if (summary != null) _SummaryCard(summary: summary),
              if (entries.isEmpty)
                _EmptyDayState(onAdd: () => context.push('/meal/new?date=$dateStr'))
              else
                ...entries.asMap().entries.map(
                  (kv) => MealEntryTile(
                    index: kv.key,
                    entry: kv.value,
                    onTap: () => context.push(
                      '/meal/${kv.value.id}',
                      extra: kv.value,
                    ),
                    onDelete: () => ref
                        .read(dayDetailProvider(date).notifier)
                        .delete(kv.value.id!),
                  ),
                ),
              const SizedBox(height: 80), // FAB clearance
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final DaySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(12),
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat('🔥', summary.totalCalories.toStringAsFixed(0), 'kcal'),
            _Stat('🥩', '${summary.totalProtein.toStringAsFixed(0)}g', 'protein'),
            _Stat('🥑', '${summary.totalFat.toStringAsFixed(0)}g', 'fat'),
            _Stat('🌾', '${summary.totalCarbohydrates.toStringAsFixed(0)}g', 'carbs'),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.emoji, this.value, this.label);
  final String emoji, value, label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _EmptyDayState extends StatelessWidget {
  const _EmptyDayState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_meals, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            const Text('No entries for this day.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add meal'),
            ),
          ],
        ),
      ),
    );
  }
}

