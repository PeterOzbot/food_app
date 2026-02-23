import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/meal_list_provider.dart';
import 'widgets/day_summary_tile.dart';

class MealListScreen extends ConsumerWidget {
  const MealListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mealListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Tracker'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'meal_list_fab',
        onPressed: () => context.push('/meal/new'),
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
              Text('Failed to load data:\n$e', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(mealListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (summaries) => summaries.isEmpty
            ? _EmptyState(onAdd: () => context.push('/meal/new'))
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(mealListProvider.notifier).refresh(),
                child: ListView.builder(
                  itemCount: summaries.length,
                  itemBuilder: (context, index) {
                    final summary = summaries[index];
                    return DaySummaryTile(
                      summary: summary,
                      onEdit: () => context.push(
                        '/day/${DateFormat('yyyy-MM-dd').format(summary.date)}',
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 72,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No meals recorded yet.',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add your first entry.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add meal'),
          ),
        ],
      ),
    );
  }
}

