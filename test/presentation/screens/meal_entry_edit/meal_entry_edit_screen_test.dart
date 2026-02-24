import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:food_app/data/models/meal_entry_model.dart';
import 'package:food_app/data/repositories/meal_entry_repository.dart';
import 'package:food_app/presentation/providers/meal_entry_edit_provider.dart';
import 'package:food_app/presentation/providers/repository_provider.dart';
import 'package:food_app/presentation/screens/meal_entry_edit/meal_entry_edit_screen.dart';

class MockMealEntryRepository extends Mock implements MealEntryRepository {}

class FakeMealEntry extends Fake implements MealEntry {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMealEntry());
  });

  late MockMealEntryRepository mockRepository;

  setUp(() {
    mockRepository = MockMealEntryRepository();
  });

  Widget createTestWidget({
    MealEntry? existingEntry,
    DateTime? initialDate,
  }) {
    return ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(mockRepository),
      ],
      child: MaterialApp(
        home: MealEntryEditScreen(
          existingEntry: existingEntry,
          initialDate: initialDate,
        ),
      ),
    );
  }

  group('MealEntryEditScreen', () {
    testWidgets('shows loading indicator while isInitializing is true',
        (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Initially shows loading indicator (before addPostFrameCallback runs)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows form after initialization completes', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Pump to trigger addPostFrameCallback
      await tester.pump();

      // Now form should be visible (loading indicator gone)
      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('displays existing entry data when editing', (tester) async {
      final existingEntry = MealEntry(
        id: 1,
        date: DateTime(2024, 2, 24),
        text: 'Test meal description',
        calories: 500,
        protein: 30,
        totalFat: 20,
        carbohydrates: 50,
        dietaryFiber: 5,
        sugars: 10,
      );

      await tester.pumpWidget(createTestWidget(existingEntry: existingEntry));
      await tester.pump(); // Trigger init

      // Verify description field shows existing text
      expect(find.text('Test meal description'), findsOneWidget);
    });

    testWidgets('save button triggers repository update for existing entry',
        (tester) async {
      final existingEntry = MealEntry(
        id: 42,
        date: DateTime(2024, 2, 24),
        text: 'Existing meal', // Non-empty so validation passes
        calories: 500,
        protein: 30,
        totalFat: 20,
        carbohydrates: 50,
        dietaryFiber: 5,
        sugars: 10,
      );

      when(() => mockRepository.update(any())).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget(existingEntry: existingEntry));
      await tester.pump(); // Trigger init

      // Find and tap save button (it's a TextButton with 'Save' text)
      final saveButton = find.text('Save');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify update was called (not insert) with correct id
      final captured =
          verify(() => mockRepository.update(captureAny())).captured;
      expect(captured.length, equals(1));
      expect((captured.first as MealEntry).id, equals(42));
    });

    testWidgets('form validation prevents save when description is empty',
        (tester) async {
      // For new entries, validation requires description to be non-empty
      await tester.pumpWidget(
          createTestWidget(initialDate: DateTime(2024, 2, 24)));
      await tester.pump(); // Trigger init

      // Find and tap save button without entering any description
      final saveButton = find.text('Save');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify neither insert nor update was called (validation failed)
      verifyNever(() => mockRepository.insert(any()));
      verifyNever(() => mockRepository.update(any()));

      // Verify error message is shown
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('shows Edit Entry title for existing entry', (tester) async {
      final existingEntry = MealEntry(
        id: 1,
        date: DateTime(2024, 2, 24),
        text: 'Test',
        calories: 0,
        protein: 0,
        totalFat: 0,
        carbohydrates: 0,
        dietaryFiber: 0,
        sugars: 0,
      );

      await tester.pumpWidget(createTestWidget(existingEntry: existingEntry));
      await tester.pump();

      expect(find.text('Edit Entry'), findsOneWidget);
    });

    testWidgets('shows New Entry title for new entry', (tester) async {
      await tester.pumpWidget(
          createTestWidget(initialDate: DateTime(2024, 2, 24)));
      await tester.pump();

      expect(find.text('New Entry'), findsOneWidget);
    });
  });
}

