import 'package:go_router/go_router.dart';

import '../../data/models/meal_entry_model.dart';
import '../../presentation/screens/day_detail/day_detail_screen.dart';
import '../../presentation/screens/meal_entry_edit/meal_entry_edit_screen.dart';
import '../../presentation/screens/meal_list/meal_list_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MealListScreen(),
    ),
    GoRoute(
      path: '/day/:date',
      builder: (context, state) {
        final dateStr = state.pathParameters['date']!;
        return DayDetailScreen(date: DateTime.parse(dateStr));
      },
    ),
    GoRoute(
      path: '/meal/new',
      builder: (context, state) {
        final dateStr = state.uri.queryParameters['date'];
        final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
        return MealEntryEditScreen(initialDate: date);
      },
    ),
    GoRoute(
      path: '/meal/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        // The MealEntry is passed as extra so the edit screen can pre-fill.
        final entry = state.extra is MealEntry ? state.extra as MealEntry : null;
        return MealEntryEditScreen(entryId: id, existingEntry: entry);
      },
    ),
  ],
);

