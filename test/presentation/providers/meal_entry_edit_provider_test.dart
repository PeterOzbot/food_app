import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:food_app/data/models/meal_entry_model.dart';
import 'package:food_app/data/repositories/meal_entry_repository.dart';
import 'package:food_app/presentation/providers/meal_entry_edit_provider.dart';
import 'package:food_app/presentation/providers/repository_provider.dart';

// Mock repository
class MockMealEntryRepository extends Mock implements MealEntryRepository {}

// Fake for registerFallbackValue
class FakeMealEntry extends Fake implements MealEntry {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMealEntry());
  });
  group('MealEntryEditState', () {
    final testEntry = MealEntry(
      id: 1,
      date: DateTime(2024, 2, 24),
      text: 'Test meal',
      calories: 500,
      protein: 30,
      totalFat: 20,
      carbohydrates: 50,
      dietaryFiber: 5,
      sugars: 10,
    );

    final newEntry = MealEntry(
      date: DateTime(2024, 2, 24),
      text: '',
      calories: 0,
      protein: 0,
      totalFat: 0,
      carbohydrates: 0,
      dietaryFiber: 0,
      sugars: 0,
    );

    test('isNew returns true when original is null', () {
      final state = MealEntryEditState(entry: newEntry, isInitializing: false);
      expect(state.isNew, isTrue);
      expect(state.original, isNull);
    });

    test('isNew returns false when original is not null', () {
      final state = MealEntryEditState(
        original: testEntry,
        entry: testEntry,
        isInitializing: false,
      );
      expect(state.isNew, isFalse);
      expect(state.original, isNotNull);
    });

    test('isInitializing defaults to true', () {
      final state = MealEntryEditState(entry: newEntry);
      expect(state.isInitializing, isTrue);
    });

    test('isDirty returns false when entry equals original', () {
      final state = MealEntryEditState(
        original: testEntry,
        entry: testEntry,
        isInitializing: false,
      );
      expect(state.isDirty, isFalse);
    });

    test('isDirty returns true when entry differs from original', () {
      final modifiedEntry = testEntry.copyWith(text: 'Modified meal');
      final state = MealEntryEditState(
        original: testEntry,
        entry: modifiedEntry,
        isInitializing: false,
      );
      expect(state.isDirty, isTrue);
    });

    test('copyWith preserves original', () {
      final state = MealEntryEditState(
        original: testEntry,
        entry: testEntry,
        isInitializing: false,
      );
      final modifiedEntry = testEntry.copyWith(text: 'Modified');
      final newState = state.copyWith(entry: modifiedEntry);

      expect(newState.original, equals(testEntry));
      expect(newState.entry, equals(modifiedEntry));
    });
  });

  group('MealEntryEditNotifier', () {
    late ProviderContainer container;
    late MockMealEntryRepository mockRepository;

    final existingEntry = MealEntry(
      id: 42,
      date: DateTime(2024, 2, 20),
      text: 'Existing meal',
      calories: 600,
      protein: 35,
      totalFat: 25,
      carbohydrates: 60,
      dietaryFiber: 8,
      sugars: 15,
    );

    setUp(() {
      mockRepository = MockMealEntryRepository();
      container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('init with existing entry sets original and entry correctly', () {
      final notifier = container.read(mealEntryEditProvider.notifier);
      notifier.init(existing: existingEntry);

      final state = container.read(mealEntryEditProvider);
      expect(state.original, equals(existingEntry));
      expect(state.entry, equals(existingEntry));
      expect(state.isNew, isFalse);
      expect(state.isInitializing, isFalse);
    });

    test('init without existing entry creates new entry with given date', () {
      final testDate = DateTime(2024, 3, 15);
      final notifier = container.read(mealEntryEditProvider.notifier);
      notifier.init(date: testDate);

      final state = container.read(mealEntryEditProvider);
      expect(state.original, isNull);
      expect(state.entry.date, equals(testDate));
      expect(state.entry.id, isNull);
      expect(state.isNew, isTrue);
      expect(state.isInitializing, isFalse);
    });

    test('init sets isInitializing to false', () {
      final notifier = container.read(mealEntryEditProvider.notifier);

      // Before init, default state has isInitializing = true
      var state = container.read(mealEntryEditProvider);
      expect(state.isInitializing, isTrue);

      notifier.init(existing: existingEntry);

      state = container.read(mealEntryEditProvider);
      expect(state.isInitializing, isFalse);
    });

    test('update() changes entry but preserves original', () {
      final notifier = container.read(mealEntryEditProvider.notifier);
      notifier.init(existing: existingEntry);

      final modifiedEntry = existingEntry.copyWith(text: 'Modified text');
      notifier.update(modifiedEntry);

      final state = container.read(mealEntryEditProvider);
      expect(state.original, equals(existingEntry));
      expect(state.entry, equals(modifiedEntry));
      expect(state.entry.id, equals(existingEntry.id));
      expect(state.isDirty, isTrue);
    });

    test('update() preserves entry id when modifying other fields', () {
      final notifier = container.read(mealEntryEditProvider.notifier);
      notifier.init(existing: existingEntry);

      // Simulate changing the date (like user picking a new date)
      final newDate = DateTime(2024, 3, 1);
      final modifiedEntry = existingEntry.copyWith(date: newDate);
      notifier.update(modifiedEntry);

      final state = container.read(mealEntryEditProvider);
      expect(state.entry.id, equals(42)); // ID must be preserved
      expect(state.entry.date, equals(newDate));
    });

    test('save() calls repository.update() for existing entry', () async {
      when(() => mockRepository.update(any())).thenAnswer((_) async {});

      final notifier = container.read(mealEntryEditProvider.notifier);
      notifier.init(existing: existingEntry);

      final success = await notifier.save();

      expect(success, isTrue);
      verify(() => mockRepository.update(existingEntry)).called(1);
      verifyNever(() => mockRepository.insert(any()));
    });

    test('save() calls repository.insert() for new entry', () async {
      final newEntry = MealEntry(
        date: DateTime(2024, 2, 24),
        text: 'New meal',
        calories: 300,
        protein: 20,
        totalFat: 10,
        carbohydrates: 30,
        dietaryFiber: 3,
        sugars: 5,
      );

      when(() => mockRepository.insert(any()))
          .thenAnswer((_) async => newEntry.copyWith(id: 99));

      final notifier = container.read(mealEntryEditProvider.notifier);
      notifier.init(); // No existing entry = new entry

      // Update to set the entry content
      notifier.update(container.read(mealEntryEditProvider).entry.copyWith(
            text: 'New meal',
            calories: 300,
          ));

      final success = await notifier.save();

      expect(success, isTrue);
      verify(() => mockRepository.insert(any())).called(1);
      verifyNever(() => mockRepository.update(any()));
    });

    test('save() with modified existing entry calls update with correct id',
        () async {
      when(() => mockRepository.update(any())).thenAnswer((_) async {});

      final notifier = container.read(mealEntryEditProvider.notifier);
      notifier.init(existing: existingEntry);

      // Modify the entry (change date and text)
      final modifiedEntry = existingEntry.copyWith(
        date: DateTime(2024, 3, 10),
        text: 'Updated meal description',
      );
      notifier.update(modifiedEntry);

      final success = await notifier.save();

      expect(success, isTrue);

      // Verify update was called with entry that has the original id
      final captured = verify(() => mockRepository.update(captureAny()))
          .captured
          .first as MealEntry;
      expect(captured.id, equals(42));
      expect(captured.date, equals(DateTime(2024, 3, 10)));
      expect(captured.text, equals('Updated meal description'));
    });
  });
}

