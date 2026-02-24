# FoodApp

A Flutter-based food tracking application that allows users to log meals, track nutritional information (macros, vitamins, minerals), and use AI-powered macro estimation via OpenAI.

## Technologies Used

- **Flutter** – Cross-platform UI framework
- **Dart SDK** ^3.11.0
- **SQLite** – Local database (sqflite, sqflite_common_ffi)
- **Riverpod** – State management
- **GoRouter** – Declarative navigation
- **OpenAI API** (gpt-4o-mini) – AI-powered nutritional estimation
- **Other packages**: intl, equatable, http, flutter_dotenv

## Prerequisites

- Flutter SDK installed ([installation guide](https://docs.flutter.dev/get-started/install))
- An OpenAI API key (required for AI-Fill functionality)

## Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/PeterOzbot/food_app.git
   cd food_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**

   Create a `.env` file in the project root:
   ```bash
   OPENAI_API_KEY=sk-your-key-here
   ```

   > ⚠️ The `.env` file is gitignored and should never be committed.

## Running the App

```bash
flutter run
```

To target a specific platform:
```bash
flutter run -d windows
flutter run -d macos
flutter run -d linux
flutter run -d chrome
```

**Supported platforms**: Android, iOS, Windows, macOS, Linux

## Running Tests

```bash
flutter test
```