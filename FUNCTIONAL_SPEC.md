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
11. [AI Macro Calculation](#11-ai-macro-calculation)

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
| `http` | `^1.2` | HTTP client for OpenAI REST API calls |
| `flutter_dotenv` | `^5.2` | Load `.env` file at startup for secure API key storage |

### Why Riverpod over BLoC or Provider?

Riverpod 3.x `AsyncNotifier` maps directly onto the "load from DB → display → mutate → reload"
cycle without extra boilerplate. It is context-independent, compile-safe, and pairs naturally with
the repository pattern. BLoC is equally valid but adds ceremony that is disproportionate for a
data-CRUD app of this size.

> **Riverpod 3.x breaking change:** `FamilyAsyncNotifier` is removed. Family notifiers are now
> plain `AsyncNotifier` subclasses that receive their argument via a constructor parameter. The
> provider is declared with `AsyncNotifierProvider.family` and the argument is passed in
> `build()` and stored on the notifier instance.

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
│   ├── router/
│   │   └── app_router.dart               ← GoRouter route definitions
│   └── services/
│       └── openai_service.dart           ← wraps the OpenAI chat/completions endpoint
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
    │   ├── meal_entry_edit_provider.dart  ← Notifier<MealEntryEditState>
    │   └── ai_macro_provider.dart        ← AsyncNotifier driving the AI-Fill call
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

### 4d. AiLog entity

Tracks every OpenAI API interaction for audit, debugging, and future analytics.

```dart
// lib/data/models/ai_log_model.dart

class AiLog extends Equatable {
  final int?     id;           // null before first persist
  final DateTime timestamp;    // when the request was sent
  final String   request;      // meal description submitted to the API
  final String   response;     // raw JSON string returned by the API (empty on failure)
  final bool     success;      // true if HTTP 200 and valid JSON received
  final String?  errorMessage; // populated only when success == false

  const AiLog({
    this.id,
    required this.timestamp,
    required this.request,
    required this.response,
    required this.success,
    this.errorMessage,
  });

  factory AiLog.fromMap(Map<String, dynamic> m) => AiLog(
    id:           m['id'] as int?,
    timestamp:    DateTime.parse(m['timestamp'] as String),
    request:      m['request'] as String,
    response:     m['response'] as String,
    success:      (m['success'] as int) == 1,
    errorMessage: m['error_message'] as String?,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'timestamp':     timestamp.toIso8601String(),
    'request':       request,
    'response':      response,
    'success':       success ? 1 : 0,
    'error_message': errorMessage,
  };

  AiLog copyWith({
    int? id,
    DateTime? timestamp,
    String? request,
    String? response,
    bool? success,
    String? errorMessage,
  }) => AiLog(
    id:           id           ?? this.id,
    timestamp:    timestamp    ?? this.timestamp,
    request:      request      ?? this.request,
    response:     response     ?? this.response,
    success:      success      ?? this.success,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [id, timestamp, request, response, success, errorMessage];
}
```

### 4e. AiLog SQLite type mapping

| Dart field | SQLite column | Type | Notes |
|---|---|---|---|
| `int? id` | `id` | `INTEGER PRIMARY KEY AUTOINCREMENT` | `null` before insert |
| `DateTime timestamp` | `timestamp` | `TEXT NOT NULL` | ISO 8601: `"2024-02-23T14:05:00.000"` |
| `String request` | `request` | `TEXT NOT NULL` | Meal description sent to OpenAI |
| `String response` | `response` | `TEXT NOT NULL` | Raw JSON content from API; empty string on failure |
| `bool success` | `success` | `INTEGER NOT NULL` | `1` = true, `0` = false |
| `String? errorMessage` | `error_message` | `TEXT` | SQL `NULL` when call succeeded |

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

### 5c. Version 2 — ai_logs table

```dart
// lib/core/database/migrations/v2_create_ai_logs.dart

class V2CreateAiLogs extends AppMigration {
  @override int get toVersion => 2;
  @override String get description => 'Create ai_logs table';

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE ai_logs (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp     TEXT    NOT NULL,
        request       TEXT    NOT NULL,
        response      TEXT    NOT NULL,
        success       INTEGER NOT NULL,
        error_message TEXT
      )
    ''');
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS ai_logs');
  }
}
```

### 5d. Migration runner (AppDatabase)

```dart
// lib/core/database/app_database.dart

class AppDatabase {
  static const _dbName = 'food_app.db';
  static const _currentVersion = 2;

  // ▸ Register every migration here in ascending version order.
  static final List<AppMigration> _migrations = [
    V1CreateMealEntries(),
    V2CreateAiLogs(),
    // V3SomeChange(),   ← future migrations appended here
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

### 5e. How to add a future migration

1. Create `lib/core/database/migrations/v3_<description>.dart` extending `AppMigration`.
2. Implement `up()` (and optionally `down()`).
3. Append the instance to `_migrations` in `AppDatabase`.
4. Bump `_currentVersion` to `3`.

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

For the edit route (`/meal/:id`), the full `MealEntry` object is passed via GoRouter's `extra`
parameter so the edit screen pre-fills immediately without an extra DB round-trip:

```dart
context.push('/meal/${entry.id}', extra: entry);
```

The router unwraps it as: `state.extra is MealEntry ? state.extra as MealEntry : null`.

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

> **Read-only display rule:** All nutrient fields (Sections B, C, D) are **display-only**. They
> render the stored value but reject keyboard input — the `readOnly: true` flag is set on every
> `NutrientField`. Only **Date** and **Description** are interactive.

#### Section A — Basic Info (always visible, editable)

| Field | Widget | Validation |
|---|---|---|
| Date | `InkWell` wrapping `InputDecorator` + `showDatePicker` | Required |
| Description | `TextFormField`, multiline, max 3 lines | Required, min 1 char |
| **AI-Fill** button | `FilledButton.icon` with spinner | **New entry only** |

The Date field is an `InkWell` wrapping an `InputDecorator` (not a `TextFormField`) so tapping
anywhere on the decorated box opens the system date picker while the displayed value stays
formatted via `DateFormat('d MMMM yyyy')`.

**AI-Fill button** (visible only when `state.isNew == true`):

- Rendered as a `FilledButton.icon` immediately below the Description field.
- Disabled when the Description field is empty or when an AI call is already in progress.
- When pressed, calls `ref.read(aiMacroProvider.notifier).estimate(description)`.
- While loading, the button icon is replaced by a `CircularProgressIndicator` (size 16).
- On success, shows the **AI-Fill Result bottom sheet** (see below) before writing the
  estimated values to the form. Nutrient fields are populated only after the user dismisses
  the sheet.
- On error, shows a `SnackBar` with the error message; nutrient fields remain at their
  previous values.

#### AI-Fill Result bottom sheet

Displayed via `showModalBottomSheet(...)` immediately after a successful AI response,
before any form fields are updated. The sheet is **not dismissible by dragging** — the
user must tap the button to confirm.

| Element | Details |
|---|---|
| Title | "AI Estimation Result" |
| Confidence row | Label **"Confidence:"** followed by the value of `aiJson['confidence']` (`"high"`, `"medium"`, or `"low"`), styled with a colour badge: green for high, amber for medium, red for low |
| Notes row | Label **"Notes:"** followed by the value of `aiJson['note']` (the AI's assumptions). If the note is empty or null, this row is omitted. |
| Action button | `FilledButton` labelled **"Apply"**; tapping it closes the sheet, then calls `ref.read(mealEntryEditProvider.notifier).update(filledEntry)` to populate all nutrient fields and resets `aiMacroProvider` to idle. |

#### Section B — Macronutrients (collapsible `NutrientSection`, initially expanded, **read-only**)

Rendered with `NutrientSection` (`ExpansionTile` inside a `Card`), set `initiallyExpanded: true`.

| Field | Suffix | Notes |
|---|---|---|
| Calories | kcal | required macro |
| Protein | g | required macro |
| Total Fat | g | required macro |
| Carbohydrates | g | required macro |
| Dietary Fiber | g | required macro |
| Sugars | g | required macro |
| Saturated Fat | g | optional |
| Trans Fat | g | optional |
| Cholesterol | mg | optional |
| Water | ml | optional |

#### Section C — Vitamins (collapsible `NutrientSection`, **read-only placeholder**)

> **Note:** This section is a UI placeholder for future population (e.g., via nutrition API or
> barcode scanner). All 13 vitamin fields are present but may be left blank.

Vitamin A (µg RAE), Vitamin C (mg), Vitamin D (µg), Vitamin E (mg), Vitamin K (µg),
Thiamin B1 (mg), Riboflavin B2 (mg), Niacin B3 (mg), Vitamin B6 (mg), Folate B9 (µg DFE),
Vitamin B12 (µg), Pantothenic Acid B5 (mg), Biotin B7 (µg).

#### Section D — Minerals (collapsible `NutrientSection`, **read-only placeholder**)

> Same placeholder note as vitamins.

Calcium (mg), Iron (mg), Magnesium (mg), Phosphorus (mg), Potassium (mg), Sodium (mg),
Zinc (mg), Copper (mg), Manganese (mg), Selenium (µg).

**NutrientField shared widget:**

```dart
// lib/presentation/screens/meal_entry_edit/widgets/nutrient_field.dart

class NutrientField extends StatelessWidget {
  const NutrientField({
    required this.label,
    required this.unit,        // suffix text, e.g. "g", "mg", "kcal"
    required this.initialValue,
    required this.onChanged,
    this.required = false,
    this.readOnly = false,     // when true: filled tint, no keyboard, no validator
  });

  final String label;
  final String unit;
  final double? initialValue;
  final ValueChanged<double?> onChanged;
  final bool required;
  final bool readOnly;
}
```

When `readOnly` is `true`:
- `TextFormField.readOnly` is set, suppressing the keyboard.
- The field background is tinted with `colorScheme.surfaceContainerHighest`.
- `inputFormatters` is set to `[]` and `validator` is `null`.
- `onChanged` is `null` (Flutter ignores the no-op closure).

When `readOnly` is `false`, the field uses `TextInputType.numberWithOptions(decimal: true)` and
`FilteringTextInputFormatter` to allow only digits and `.`.

**NutrientSection shared widget:**

```dart
// lib/presentation/screens/meal_entry_edit/widgets/nutrient_section.dart

class NutrientSection extends StatelessWidget {
  // Wraps children in an ExpansionTile inside a Card.
  // padding: EdgeInsets.fromLTRB(16, 8, 16, 16)  ← top=8 prevents floating
  //                                                  label from being clipped
  // clipBehavior is NOT set (default Clip.none) for the same reason.
}
```

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
  final MealEntry? original; // null when creating a new entry
  final MealEntry entry;     // current form values
  final bool isSaving;       // true while the DB write is in progress
  final String? saveError;   // non-null if last save failed

  // Computed getters
  bool get isDirty => entry != original;  // uses Equatable equality
  bool get isNew   => original == null;
}
```

The edit screen calls `ref.read(mealEntryEditProvider.notifier).update(updatedEntry)` whenever
date or description changes. `save()` calls the repository, returns `true` on success (the screen
then pops and invalidates the list/detail providers), or sets `saveError` on failure.

### Provider initialisation pattern

Riverpod forbids mutating a provider while the widget tree is building. The edit screen
initialises the provider in `initState()` deferred by one frame:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    ref.read(mealEntryEditProvider.notifier).init(
      existing: widget.existingEntry,
      date: widget.initialDate,
    );
  });
}
```

Do **not** call `ref.read(...).init()` directly inside `didChangeDependencies()` — that runs
during the build phase and triggers a "Tried to modify a provider while the widget tree was
building" error.

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
| 12 | `OpenAiService` + `aiMacroProvider` + AI-Fill button | AI-Fill populates nutrients end-to-end |

---

## 11. AI Macro Calculation

### Overview

When creating a **new** meal entry, the user can type a meal description (e.g. "200 g grilled chicken breast with 150 g boiled rice") and press **AI-Fill**. The app sends the description to the OpenAI chat completions endpoint using the `gpt-4o-mini` model and receives a JSON object containing estimated values for every nutritional field defined in `MealEntry`. The parsed values are written back into the form via the `mealEntryEditProvider`.

### Package additions

| Package | Version | Purpose |
|---|---|---|
| `http` | `^1.2` | HTTP client for the OpenAI REST call |
| `flutter_dotenv` | `^5.2` | Load `.env` at startup; exposes `dotenv.env['OPENAI_API_KEY']` |

Run:
```
flutter pub add http flutter_dotenv
```

Create `.env` in the project root (add to `.gitignore`):
```
OPENAI_API_KEY=sk-...
```

Load it in `main.dart` before `runApp`:
```dart
await dotenv.load(fileName: '.env');
```

> **Security:** Never hardcode the API key. For production, route requests through a backend
> proxy so the raw key is never shipped inside the client binary. As an alternative to `.env`,
> the key can be injected at build time via `--dart-define=OPENAI_API_KEY=sk-...` and read
> with `const String.fromEnvironment('OPENAI_API_KEY')`.

### OpenAI API configuration

| Parameter | Value |
|---|---|
| Endpoint | `https://api.openai.com/v1/chat/completions` |
| Model | `gpt-4o-mini` |
| `response_format` | `{ "type": "json_object" }` |
| `temperature` | `0.2` (low for deterministic nutritional estimates) |
| `max_tokens` | `1500` |

### Prompt template

**System message** (sent once per API call — contains role, steps, and JSON schema):
```
You are a precise nutritionist and expert in food nutritional values. Your task is to analyze the meal description and calculate the total nutritional values.

Follow these steps exactly:

1. Break down the description into individual ingredients and their quantities in grams. If a quantity is not specified, use a realistic average portion (and note this in the "note" field).

2. For each ingredient, look up the standard nutritional values per 100 g (use reliable average values from USDA, EU data, or generally accepted databases).

3. Calculate the scaled values for the actual quantity in grams.

4. Sum everything up for the entire meal.

5. Return ONLY a valid JSON object, with no additional text, no introduction, no explanation outside the JSON. The JSON must follow this exact structure:

{
  "meal_description": "original description for reference",
  "note": "any assumptions made",
  "confidence": "high / medium / low",

  "calories": number,
  "protein": number,
  "totalFat": number,
  "carbohydrates": number,
  "dietaryFiber": number,
  "sugars": number,

  "saturatedFat": number | null,
  "transFat": number | null,

  "vitaminA": number | null,
  "vitaminC": number | null,
  "vitaminD": number | null,
  "vitaminE": number | null,
  "vitaminK": number | null,
  "thiaminB1": number | null,
  "riboflavinB2": number | null,
  "niacinB3": number | null,
  "vitaminB6": number | null,
  "folateB9": number | null,
  "vitaminB12": number | null,
  "pantothenicAcidB5": number | null,
  "biotinB7": number | null,

  "calcium": number | null,
  "iron": number | null,
  "magnesium": number | null,
  "phosphorus": number | null,
  "potassium": number | null,
  "sodium": number | null,
  "zinc": number | null,
  "copper": number | null,
  "manganese": number | null,
  "selenium": number | null,

  "cholesterol": number | null,
  "water": number | null
}

Be very accurate with the numbers (round to 1 decimal place where appropriate). If any value is unknown, use 0 and add a note.
Start immediately with the JSON object.
```

**User message** (one per call — contains only the meal description):
```
Meal description: """<description text from the form>"""
```

`confidence` is logged for debugging but not persisted to the DB.

### JSON response schema → MealEntry mapping

The JSON keys are camelCase and match the Dart field names exactly, so `MealEntry.fromAiJson()` reads them directly with no translation.

| JSON key | `MealEntry` field | Type | Unit | Required? |
|---|---|---|---|---|
| `calories` | `calories` | `double` | kcal | ✓ |
| `protein` | `protein` | `double` | g | ✓ |
| `totalFat` | `totalFat` | `double` | g | ✓ |
| `carbohydrates` | `carbohydrates` | `double` | g | ✓ |
| `dietaryFiber` | `dietaryFiber` | `double` | g | ✓ |
| `sugars` | `sugars` | `double` | g | ✓ |
| `saturatedFat` | `saturatedFat` | `double?` | g | optional |
| `transFat` | `transFat` | `double?` | g | optional |
| `vitaminA` | `vitaminA` | `double?` | µg | optional |
| `vitaminC` | `vitaminC` | `double?` | mg | optional |
| `vitaminD` | `vitaminD` | `double?` | µg | optional |
| `vitaminE` | `vitaminE` | `double?` | mg | optional |
| `vitaminK` | `vitaminK` | `double?` | µg | optional |
| `thiaminB1` | `thiaminB1` | `double?` | mg | optional |
| `riboflavinB2` | `riboflavinB2` | `double?` | mg | optional |
| `niacinB3` | `niacinB3` | `double?` | mg | optional |
| `vitaminB6` | `vitaminB6` | `double?` | mg | optional |
| `folateB9` | `folateB9` | `double?` | µg | optional |
| `vitaminB12` | `vitaminB12` | `double?` | µg | optional |
| `pantothenicAcidB5` | `pantothenicAcidB5` | `double?` | mg | optional |
| `biotinB7` | `biotinB7` | `double?` | µg | optional |
| `calcium` | `calcium` | `double?` | mg | optional |
| `iron` | `iron` | `double?` | mg | optional |
| `magnesium` | `magnesium` | `double?` | mg | optional |
| `phosphorus` | `phosphorus` | `double?` | mg | optional |
| `potassium` | `potassium` | `double?` | mg | optional |
| `sodium` | `sodium` | `double?` | mg | optional |
| `zinc` | `zinc` | `double?` | mg | optional |
| `copper` | `copper` | `double?` | mg | optional |
| `manganese` | `manganese` | `double?` | mg | optional |
| `selenium` | `selenium` | `double?` | µg | optional |
| `cholesterol` | `cholesterol` | `double?` | mg | optional |
| `water` | `water` | `double?` | ml | optional |
| `meal_description` | *(not mapped)* | `String` | — | logged only |
| `note` | *(not mapped)* | `String` | — | logged only |
| `confidence` | *(not mapped)* | `String` | — | logged only |

### `OpenAiService` — `lib/core/services/openai_service.dart`

```dart
class OpenAiService {
  static const _endpoint =
      'https://api.openai.com/v1/chat/completions';
  static const _model = 'gpt-4o-mini';

  final String _apiKey;
  OpenAiService(this._apiKey);

  /// Returns a [MealEntry] stub with all nutritional fields populated.
  /// Throws [OpenAiException] on network error, non-200 status, or bad JSON.
  Future<MealEntry> estimateMacros(String description) async { ... }
}
```

The method:
1. POSTs the system + user messages to `_endpoint`.
2. Parses `response.choices[0].message.content` as JSON.
3. Calls `MealEntry.fromMap(json)` (or a dedicated `MealEntry.fromAiJson(json)`) to build
   a stub entry (no `id`, no `date`, no `description` — those come from the form).
4. Returns the stub; the caller merges it into the current `MealEntryEditState.entry` via
   `entry.copyWith(...)`.

### `aiMacroProvider` — `lib/presentation/providers/ai_macro_provider.dart`

```dart
// State: AsyncValue<MealEntry?> — null = idle, data = result, error = failure
final aiMacroProvider =
    AsyncNotifierProvider<AiMacroNotifier, MealEntry?>(() => AiMacroNotifier());

class AiMacroNotifier extends AsyncNotifier<MealEntry?> {
  @override
  FutureOr<MealEntry?> build() => null; // idle

  Future<void> estimate(String description) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(openAiServiceProvider).estimateMacros(description),
    );
  }
}
```

The edit screen watches `aiMacroProvider` with `ref.listen(...)` to react to state changes:
- `AsyncLoading` → disable AI-Fill button, show spinner.
- `AsyncData(entry)` → call `showModalBottomSheet(...)` to present the **AI-Fill Result
  bottom sheet** (confidence level + notes). Only after the user taps **Apply** does the
  sheet close and call `mealEntryEditProvider.notifier.update(mergedEntry)` followed by
  `aiMacroProvider` reset to idle.
- `AsyncError` → show error `SnackBar`, reset `aiMacroProvider` to idle.

### Error handling

| Scenario | Behaviour |
|---|---|
| Network unreachable | `AsyncError` with connection error message |
| HTTP 4xx / 5xx | `AsyncError` with status code in message |
| Response is not valid JSON | `AsyncError` — `FormatException` surfaced |
| Required macro field missing | Defaults to `0` (matches `MealEntry` constructor) |
| API rate limit (HTTP 429) | `AsyncError` with "Rate limit exceeded — retry later" |

---

*End of Functional Specification*


