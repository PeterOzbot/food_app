import 'package:equatable/equatable.dart';

/// Aggregated nutritional totals for a single calendar day.
/// Built inside the repository layer from raw [MealEntry] rows.
class DaySummary extends Equatable {
  const DaySummary({
    required this.date,
    required this.entryCount,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalFat,
    required this.totalCarbohydrates,
    this.entryTexts = const [],
  });

  final DateTime date;
  final int entryCount;
  final double totalCalories;
  final double totalProtein;
  final double totalFat;
  final double totalCarbohydrates;

  /// Descriptions/texts from all meal entries for this day, ordered by entry id.
  final List<String> entryTexts;

  @override
  List<Object?> get props => [
        date,
        entryCount,
        totalCalories,
        totalProtein,
        totalFat,
        totalCarbohydrates,
        entryTexts,
      ];
}

