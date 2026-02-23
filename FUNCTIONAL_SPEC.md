# FoodApp — Functional Specification

## Table of Contents

1. [Project Baseline](#1-project-baseline)
2. [Package Recommendations](#2-package-recommendations)
3. [Code Structure & Architecture](#3-code-structure--architecture)
4. [Data Model: MealEntry](#4-data-model-mealentry)
5. [Database Schema & Migration System](#5-database-schema--migration-system)
6. [Navigation Flow](#6-navigation-flow)
7. [Screen Specifications](#7-screen-specifications)
8. [State Management Design](#8-state-management-design)
9. [Repository Layer](#9-repository-layer)
10. [Implementation Sequencing](#10-implementation-sequencing)

---

## 1. Project Baseline

The existing project (`food_app`) is a minimal Flutter app with no dependencies beyond
`cupertino_icons`. This document describes the full implementation of the food tracking
application — `main.dart` and `pubspec.yaml` will both be replaced entirely.

| Property | Value |
|---|---|
| Package name | `food_app` |
| Dart SDK | `^3.11.0` |
| Primary dev platform | Windows (desktop) |
| Target platforms | Android, iOS, Windows, macOS, Linux |

---

## 2. Package Recommendations

| Package | Version | Purpose |
|---|---|---|
| `sqflite` | `^2.4` | SQLite engine (Android / iOS) |
| `sqflite_common_ffi` | `^2.3` | SQLite on Windows / Linux / macOS desktop |
| `path` | `^1.9` | Resolve the database file path portably |
| `flutter_riverpod` | `^2.6` | State management — compile-safe, async-first |
| `go_router` | `^14.0` | Declarative navigation with deep-link support |
| `intl` | `^0.20` | Date / number formatting |
| `equatable` | `^2.0` | Value equality on model classes without boilerplate |

### Why Riverpod over BLoC or Provider?

Riverpod 2.x `AsyncNotifier` maps directly onto the "load from DB → display → mutate → reload"
cycle without extra boilerplate. It is context-independent, compile-safe, and pairs naturally with
the repository pattern. BLoC is equally valid but adds ceremony that is disproportionate for a
data-CRUD app of this size.

### Why `sqflite` over `drift`?

`drift` (type-safe code-gen ORM) is excellent but adds `build_runner` complexity early on.
Starting with raw `sqflite` plus a hand-rolled migration runner keeps setup transparent. Migrating
to `drift` later is straightforward because the table schema is already defined here.

### Desktop SQLite initialisation note

On Windows / Linux / macOS, `sqflite_common_ffi` must be initialised before the first DB call:

```dart
// main.dart  (desktop only)
if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
```

---

## 3. Code Structure & Architecture

```
lib/
├── main.dart                              ← entry point, ProviderScope wrapper
├── app.dart                               ← MaterialApp.router + theme
│
├── core/
│   ├── database/
│   │   ├── app_database.dart              ← opens SQLite, runs migrations
│   │   └── migrations/
│   │       ├── app_migration.dart         ← abstract Migration base class
│   │       └── v1_create_meal_entries.dart
│   └── router/
│       └── app_router.dart               ← GoRouter route definitions
│
├── data/
│   ├── models/
│   │   └── meal_entry_model.dart          ← fromMap / toMap / copyWith
│   └── repositories/
│       ├── meal_entry_repository.dart     ← abstract interface
│       └── sqlite_meal_entry_repository.dart
│
├── domain/
│   └── entities/
│       └── day_summary.dart              ← aggregated view-model for list screen
│
└── presentation/
    ├── providers/
    │   ├── database_provider.dart         ← AppDatabase singleton
    │   ├── repository_provider.dart       ← MealEntryRepository instance
    │   ├── meal_list_provider.dart        ← AsyncNotifier<List<DaySummary>>
    │   ├── day_detail_provider.dart       ← AsyncNotifier<List<MealEntry>>
    │   └── meal_entry_edit_provider.dart  ← Notifier<MealEntryEditState>
    └── screens/
        ├── meal_list/
        │   ├── meal_list_screen.dart
        │   └── widgets/
        │       └── day_summary_tile.dart
        ├── day_detail/
        │   ├── day_detail_screen.dart
        │   └── widgets/
        │       └── meal_entry_tile.dart
        └── meal_entry_edit/
            ├── meal_entry_edit_screen.dart
            └── widgets/
                ├── nutrient_section.dart  ← labelled collapsible ExpansionTile section
                └── nutrient_field.dart    ← labelled numeric TextFormField
```

### Architectural constraints

- The `presentation/` layer imports only from `domain/` and `data/models/` — **never** directly
  from `core/database/`.
- All database access goes through the `MealEntryRepository` interface.
- Providers are the sole bridge between the presentation and data layers.

---

## 4. Data Model: MealEntry

### 4a. Entity definition

```dart
// lib/data/models/meal_entry_model.dart

class MealEntry extends Equatable {
  final int?   id;       // null before first persist
  final DateTime date;
  final String text;     // free-text description

  // ── Macronutrients (required) ──────────────────────────────────────────
  final double calories;       // kcal
  final double protein;        // g
  final double totalFat;       // g
  final double carbohydrates;  // g
  final double dietaryFiber;   // g
  final double sugars;         // g

  // ── Macronutrients (optional) ──────────────────────────────────────────
  final double? saturatedFat;  // g
  final double? transFat;      // g

  // ── Vitamins (all optional) ────────────────────────────────────────────
  final double? vitaminA;          // µg RAE
  final double? vitaminC;          // mg
  final double? vitaminD;          // µg
  final double? vitaminE;          // mg
  final double? vitaminK;          // µg
  final double? thiaminB1;         // mg
  final double? riboflavinB2;      // mg
  final double? niacinB3;          // mg
  final double? vitaminB6;         // mg
  final double? folateB9;          // µg DFE
  final double? vitaminB12;        // µg
  final double? pantothenicAcidB5; // mg
  final double? biotinB7;          // µg

  // ── Minerals (all optional) ────────────────────────────────────────────
  final double? calcium;    // mg
  final double? iron;       // mg
  final double? magnesium;  // mg
  final double? phosphorus; // mg
  final double? potassium;  // mg
  final double? sodium;     // mg
  final double? zinc;       // mg
  final double? copper;     // mg
  final double? manganese;  // mg
  final double? selenium;   // µg

  // ── Extras (optional) ─────────────────────────────────────────────────
  final double? cholesterol; // mg
  final double? water;       // g

  const MealEntry({
    this.id,
    required this.date,
    required this.text,
    required this.calories,
    required this.protein,
    required this.totalFat,
    required this.carbohydrates,
    required this.dietaryFiber,
    required this.sugars,
    this.saturatedFat,
    this.transFat,
    this.vitaminA, this.vitaminC, this.vitaminD, this.vitaminE, this.vitaminK,
    this.thiaminB1, this.riboflavinB2, this.niacinB3, this.vitaminB6,
    this.folateB9, this.vitaminB12, this.pantothenicAcidB5, this.biotinB7,
    this.calcium, this.iron, this.magnesium, this.phosphorus, this.potassium,
    this.sodium, this.zinc, this.copper, this.manganese, this.selenium,
    this.cholesterol, this.water,
  });

  factory MealEntry.fromMap(Map<String, dynamic> map) { /* ... */ }
  Map<String, dynamic> toMap() { /* ... */ }
  MealEntry copyWith({/* all fields nullable-overridable */}) { /* ... */ }

  @override
  List<Object?> get props => [id, date, text, calories, protein, totalFat,
      carbohydrates, dietaryFiber, sugars, /* … all remaining fields … */];
}
```

### 4b. Type mapping rules

| Dart type | SQLite type | Notes |
|---|---|---|
| `int? id` | `INTEGER PRIMARY KEY AUTOINCREMENT` | `null` before insert |
| `DateTime` | `TEXT NOT NULL` | ISO 8601: `"2024-02-23T00:00:00.000"` |
| `String` | `TEXT NOT NULL` | — |
| `double` (required) | `REAL NOT NULL` | — |
| `double?` (optional) | `REAL` | SQL `NULL` when not set |

### 4c. DaySummary aggregation entity

```dart
// lib/domain/entities/day_summary.dart

class DaySummary extends Equatable {
  final DateTime date;
  final int      entryCount;
  final double   totalCalories;
  final double   totalProtein;
  final double   totalFat;
  final double   totalCarbohydrates;

  // Built from List<MealEntry> inside the repository layer, not in the UI.
  factory DaySummary.fromEntries(DateTime date, List<MealEntry> entries) {
    return DaySummary(
      date:               date,
      entryCount:         entries.length,
      totalCalories:      entries.fold(0, (s, e) => s + e.calories),
      totalProtein:       entries.fold(0, (s, e) => s + e.protein),
      totalFat:           entries.fold(0, (s, e) => s + e.totalFat),
      totalCarbohydrates: entries.fold(0, (s, e) => s + e.carbohydrates),
    );
  }
}
```

---

## 5. Database Schema & Migration System

### 5a. Abstract migration base

```dart
// lib/core/database/migrations/app_migration.dart

abstract class AppMigration {
  /// Schema version this migration produces (1-based, monotonically increasing).
  int get toVersion;
  String get description;

  Future<void> up(Database db);
  Future<void> down(Database db);   // implement for rollback support
}
```

### 5b. Version 1 — initial schema

```dart
// lib/core/database/migrations/v1_create_meal_entries.dart

class V1CreateMealEntries extends AppMigration {
  @override int get toVersion => 1;
  @override String get description => 'Create meal_entries table';

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE meal_entries (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        date             TEXT    NOT NULL,
        text             TEXT    NOT NULL,

        -- Macronutrients (required)
        calories         REAL    NOT NULL,
        protein          REAL    NOT NULL,
        total_fat        REAL    NOT NULL,
        carbohydrates    REAL    NOT NULL,
        dietary_fiber    REAL    NOT NULL,
        sugars           REAL    NOT NULL,

        -- Macronutrients (optional)
        saturated_fat    REAL,
        trans_fat        REAL,

        -- Vitamins
        vitamin_a          REAL,
        vitamin_c          REAL,
        vitamin_d          REAL,
        vitamin_e          REAL,
        vitamin_k          REAL,
        thiamin_b1         REAL,
        riboflavin_b2      REAL,
        niacin_b3          REAL,
        vitamin_b6         REAL,
        folate_b9          REAL,
        vitamin_b12        REAL,
        pantothenic_acid_b5 REAL,
        biotin_b7          REAL,

        -- Minerals
        calcium    REAL,
        iron       REAL,
        magnesium  REAL,
        phosphorus REAL,
        potassium  REAL,
        sodium     REAL,
        zinc       REAL,
        copper     REAL,
        manganese  REAL,
        selenium   REAL,

        -- Extras
        cholesterol REAL,
        water       REAL
      )
    ''');
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS meal_entries');
  }
}
```

### 5c. Migration runner (AppDatabase)

```dart
// lib/core/database/app_database.dart

class AppDatabase {
  static const _dbName = 'food_app.db';
  static const _currentVersion = 1;

  // ▸ Register every migration here in ascending version order.
  static final List<AppMigration> _migrations = [
    V1CreateMealEntries(),
    // V2AddIndexOnDate(),   ← future migrations appended here
  ];

  Future<Database> open() {
    return openDatabase(
      join(await getDatabasesPath(), _dbName),
      version: _currentVersion,

      onCreate: (db, version) async {
        for (final m in _migrations) await m.up(db);
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        final pending = _migrations
            .where((m) => m.toVersion > oldVersion && m.toVersion <= newVersion)
            .toList()..sort((a, b) => a.toVersion.compareTo(b.toVersion));
        for (final m in pending) await m.up(db);
      },

      onDowngrade: (db, oldVersion, newVersion) async {
        final toRollback = _migrations
            .where((m) => m.toVersion <= oldVersion && m.toVersion > newVersion)
            .toList()..sort((a, b) => b.toVersion.compareTo(a.toVersion));
        for (final m in toRollback) await m.down(db);
      },
    );
  }
}
```

### 5d. How to add a future migration

1. Create `lib/core/database/migrations/v2_<description>.dart` extending `AppMigration`.
2. Implement `up()` (and optionally `down()`).
3. Append the instance to `_migrations` in `AppDatabase`.
4. Bump `_currentVersion` to `2`.

The runner will automatically apply only the migrations between the user's current on-disk version
and the new version.

---

## 6. Navigation Flow

```
App Start
  └─► MealListScreen  (root / "/")
        ├─ [FAB "+"]          ──────────────────────────► MealEntryEditScreen
        │                                                  route: /meal/new
        │
        └─ [DaySummaryTile → "Edit" button]  ──────────► DayDetailScreen
                                                          route: /day/:dateISO
              ├─ [FAB "+"]    ──────────────────────────► MealEntryEditScreen
              │                                           route: /meal/new?date=:dateISO
              │
              └─ [MealEntryTile tap]  ─────────────────► MealEntryEditScreen
                                                          route: /meal/:id
```

### GoRouter route table

| Name | Path | Parameters |
|---|---|---|
| `mealList` | `/` | — |
| `dayDetail` | `/day/:date` | `date` — ISO 8601 date string |
| `mealNew` | `/meal/new` | optional query param `date` |
| `mealEdit` | `/meal/:id` | `id` — integer entry id |

`MealEntryEditScreen` receives either a loaded `MealEntry` (edit) or `null` (new). The screen title
and save behaviour differ accordingly.

---

## 7. Screen Specifications

### Screen 1 — MealListScreen (`/`)

**Purpose:** Entry point. Shows one row per calendar day that has at least one meal entry,
summarising macronutrients.

| Zone | Widget | Detail |
|---|---|---|
| AppBar | `AppBar` | Title: "Food Tracker". No leading. |
| Body — empty | `Center` + `Column` | Fork icon + "No meals recorded yet.\nTap + to add your first entry." |
| Body — populated | `ListView.builder` | One `DaySummaryTile` per day, sorted descending (newest first). |
| FAB | `FloatingActionButton` | "+" icon. Navigates to `/meal/new`. |

**DaySummaryTile layout:**

```
┌──────────────────────────────────────────────────────────────────┐
│  Mon          🔥 2,100 kcal   🥩 85 g protein                   │
│  23 Feb       🥑 70 g fat     🌾 250 g carbs    [ Edit ]         │
│  3 entries                                                       │
└──────────────────────────────────────────────────────────────────┘
```

- Left column: large day-of-week + "DD MMM" date; small entry count subtitle.
- Centre block: 2 × 2 macro grid with icons and formatted values.
- Right: `OutlinedButton("Edit")` → navigates to `/day/:date`.

---

### Screen 2 — DayDetailScreen (`/day/:date`)

**Purpose:** Shows all individual `MealEntry` records for a given day, with a summary card at the
top, and allows navigation to edit any individual entry.

| Zone | Widget | Detail |
|---|---|---|
| AppBar | `AppBar` | Title: full date (e.g., "Monday, 23 February 2026"). Back button. |
| Top card | `Card` | Same 4-macro summary as the list tile, for the selected day. |
| Body | `ListView.builder` | One `MealEntryTile` per entry. |
| FAB | `FloatingActionButton` | "+" → `/meal/new?date=:dateISO` |

**MealEntryTile layout:**

```
┌──────────────────────────────────────────────────────────────────┐
│  #1  Chicken breast with brown rice and steamed broccoli     ›  │
│      Cal: 450   Pro: 38 g   Fat: 9 g   Carbs: 52 g              │
└──────────────────────────────────────────────────────────────────┘
```

- `ListTile` with index or food icon as leading.
- Title: `entry.text` (truncated to 2 lines).
- Subtitle: inline macro summary.
- Trailing: chevron. `onTap` → `/meal/:id`.
- Long-press: shows `AlertDialog` confirming deletion.

---

### Screen 3 — MealEntryEditScreen (`/meal/new` or `/meal/:id`)

**Purpose:** Create a new meal entry or edit an existing one.

| Zone | Widget | Detail |
|---|---|---|
| AppBar | `AppBar` | Title: "New Meal" or "Edit Meal". Leading: ✕ (discard with confirmation if dirty). Trailing: ✓ Save. |
| Body | `SingleChildScrollView` > `Form` | All input sections below. |

**Form sections (in order):**

#### Section A — Basic Info (always visible)

| Field | Widget | Validation |
|---|---|---|
| Date | `TextFormField` (read-only) + `showDatePicker` | Required |
| Description | `TextFormField`, multiline, max 3 lines | Required, min 1 char |

#### Section B — Macronutrients (always visible)

Rendered as a non-collapsible titled `Card`.

| Field | Suffix | Required? |
|---|---|---|
| Calories | kcal | ✅ |
| Protein | g | ✅ |
| Total Fat | g | ✅ |
| Carbohydrates | g | ✅ |
| Dietary Fiber | g | ✅ |
| Sugars | g | ✅ |
| Saturated Fat | g | ➖ |
| Trans Fat | g | ➖ |

#### Section C — Vitamins (collapsible `ExpansionTile`, **placeholder**)

> **Note:** This section is a UI placeholder for future population (e.g., via nutrition API or
> barcode scanner). All 13 vitamin fields are present but may be left blank.

Vitamin A (µg RAE), Vitamin C (mg), Vitamin D (µg), Vitamin E (mg), Vitamin K (µg),
Thiamin B1 (mg), Riboflavin B2 (mg), Niacin B3 (mg), Vitamin B6 (mg), Folate B9 (µg DFE),
Vitamin B12 (µg), Pantothenic Acid B5 (mg), Biotin B7 (µg).

#### Section D — Minerals (collapsible `ExpansionTile`, **placeholder**)

> Same placeholder note as vitamins.

Calcium (mg), Iron (mg), Magnesium (mg), Phosphorus (mg), Potassium (mg), Sodium (mg),
Zinc (mg), Copper (mg), Manganese (mg), Selenium (µg).

#### Section E — Other (collapsible `ExpansionTile`)

Cholesterol (mg), Water (g).

**NutrientField shared widget:**

```dart
// lib/presentation/screens/meal_entry_edit/widgets/nutrient_field.dart

class NutrientField extends StatelessWidget {
  final String label;
  final String suffix;        // unit abbreviation
  final bool required;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  // ...
}
```

Each field uses `TextInputType.numberWithOptions(decimal: true)`. Optional fields show a
`TextStyle` hint "optional" in the suffix. Required fields add a red `*` to the label.

---

## 8. State Management Design

### Provider tree

```
ProviderScope
  └─ databaseProvider        (FutureProvider<Database>)
       └─ repositoryProvider (Provider<MealEntryRepository>)
            ├─ mealListProvider        (AsyncNotifierProvider<..., List<DaySummary>>)
            ├─ dayDetailProvider(date) (AsyncNotifierProvider.family<..., List<MealEntry>, DateTime>)
            └─ mealEntryEditProvider   (NotifierProvider<..., MealEntryEditState>)
```

### MealEntryEditState

```dart
class MealEntryEditState {
  final MealEntry draft;   // current form values — updated on every field change
  final bool isDirty;      // true once user has changed any field
  final bool isSaving;     // true while the DB write is in progress
  final String? error;     // non-null if last save failed
}
```

The edit screen calls `ref.read(mealEntryEditProvider.notifier).updateField(...)` on each
`TextEditingController` change listener. `save()` calls the repository, pops the route on success,
and sets `error` on failure.

### Refresh strategy

After a successful save or delete, the notifier calls:

```dart
ref.invalidate(mealListProvider);
ref.invalidate(dayDetailProvider(date));
```

This triggers an automatic async refresh of both the list and detail screens.

---

## 9. Repository Layer

### Abstract interface

```dart
// lib/data/repositories/meal_entry_repository.dart

abstract class MealEntryRepository {
  /// Returns all entries grouped by day, newest day first.
  Future<List<DaySummary>> getDaySummaries();

  /// Returns all entries for a specific calendar day.
  Future<List<MealEntry>> getEntriesForDate(DateTime date);

  /// Inserts a new entry. Returns the entry with its assigned [id].
  Future<MealEntry> insert(MealEntry entry);

  /// Updates an existing entry (matched by [entry.id]).
  Future<void> update(MealEntry entry);

  /// Deletes the entry with the given [id].
  Future<void> delete(int id);
}
```

### SQLite implementation notes

- `getDaySummaries()` runs a single SQL query using `GROUP BY date(date)` and `SUM(...)` aggregates,
  then maps each row to a `DaySummary`.
- `getEntriesForDate()` uses `WHERE date(date) = date(?)` to match calendar-day regardless of time
  component.
- All mutations run inside `db.transaction(...)` to guarantee atomicity.
- `getDatabasesPath()` from `sqflite` automatically resolves the correct app-documents directory
  on every platform.

---

## 10. Implementation Sequencing

Implement in this order to always have a runnable app at each step:

| Step | Deliverable | Validates |
|---|---|---|
| 1 | `pubspec.yaml` dependency additions | `flutter pub get` succeeds |
| 2 | `AppMigration` + `V1CreateMealEntries` + `AppDatabase` | DB opens and table is created |
| 3 | `MealEntry` model (`fromMap` / `toMap` / `copyWith`) | Unit tests for round-trip serialisation |
| 4 | `SqliteMealEntryRepository` (all 5 methods) | Integration tests with in-memory DB |
| 5 | Riverpod providers (`database`, `repository`) | Providers resolve without error |
| 6 | `MealListScreen` (read-only, no navigation yet) | App shows day summary list |
| 7 | `DayDetailScreen` + navigation from list | Drill-down works |
| 8 | `MealEntryEditScreen` — Basic Info + Macros only | Create/edit/save works end-to-end |
| 9 | `MealEntryEditScreen` — Vitamins + Minerals sections | Placeholder UI complete |
| 10 | Delete entry from `DayDetailScreen` | Full CRUD complete |
| 11 | Empty-state handling, error banners, loading indicators | Polish |

---

*End of Functional Specification*


