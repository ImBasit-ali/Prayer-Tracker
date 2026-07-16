# 🕌 Muslim Prayer Tracker

<p align="center">
  <img src="assets/images/app_logo.png" width="120" alt="Muslim Prayer Tracker Logo" />
</p>

A beautiful, premium Islamic Prayer Tracker & Digital Tasbeeh application built with Flutter. It follows Clean Architecture principles, uses Signals for reactive state management, and stores data locally using Isar database for a fast, offline-first experience.

[![Download APK](https://img.shields.io/badge/Download-APK-green?style=for-the-badge&logo=android)](https://raw.githubusercontent.com/ImBasit-ali/Prayer-Tracker/main/assets/Qibla.apk)---

## ✨ Features

### 🕌 Prayer Tracking & Times
- **Automatic Prayer Calculation**: Computes exact local prayer times (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha) using the `adhan` library based on your GPS coordinates.
- **Graceful GPS Fallback**: Automatically falls back to Makkah coordinates if location services or permissions are disabled, ensuring calculations never fail.
- **Smart Notification Reminders**: Exact reminders scheduled before/at prayer times using `flutter_local_notifications`. Fully compatible with Android 13+ permissions and boot-rescheduling.
- **Daily Prayer Cards**: Interactive checklists on the main dashboard to check/uncheck prayers with instant progress tracking.

### 📅 Prayer History & Analytics
- **Monthly Calendar view**: Full monthly calendar grid highlighting dates based on prayer completion status:
  - 🟢 **Green**: All 5 prayers completed
  - 🟡 **Orange**: Partially completed (1-4 prayers)
  - 🔴 **Red**: No prayers marked
  - ⚪ **White**: Untracked past dates
- **Past Date Tracking**: Tap on any previous date (even those prior to app installation) to open a dedicated tracker screen and record past prayers.
- **Yearly Tab Statistics**: Overview of all 12 months with completed days stats. Tapping on a month automatically switches to the Monthly tab. If no data exists for a tapped month, a SnackBar displays `"No prayer data available for [Month]"`.

### 📿 Digital Tasbeeh Counter
- **Tapping Counter**: A large tapping button with haptic feedback to count dhikrs.
- **Count History**: Keeps track of daily count stats with a scrollable list view detailing dates, days of the week, times, and count values (e.g. `33 times`).

---

## 🛠️ Tech Stack & Architecture

- **Framework**: Flutter (Dart SDK `^3.10.7`)
- **Database**: Isar NoSQL Database (fast, type-safe, local storage)
- **State Management**: `signals_flutter` (reactive signals) & `flutter_hooks` (declarative hooks)
- **Theming**: FlexColorScheme (modern light/dark themes with Material 3)
- **Timezone & Alarm**: `timezone`, `flutter_timezone`
- **Logger**: Talker logging framework

---

## 📂 Project Structure

```
lib/
├── core/
│   ├── constants/          # App-wide constants (e.g., prayer names)
│   ├── database/           # Isar database initialization & service configurations
│   ├── logging/            # Talker logger configuration
│   ├── services/           # Platform services (local notifications, Adhan calculation)
│   └── theme/              # FlexColorScheme configurations
├── data/
│   ├── models/             # Isar database entities (PrayerDayEntity, TasbeehEntity)
│   └── repositories/       # Repository implementations querying local Isar database
├── domain/
│   ├── models/             # Clean domain models (PrayerDay, PrayerStatistics, Tasbeeh)
│   └── repositories/       # Clean repository abstract interfaces
├── presentation/
│   ├── providers/          # Signals-based providers (PrayerProvider, TasbeehProvider, etc.)
│   ├── screens/            # UI Screens (Splash, Home, Prayer, History, settings)
│   └── widgets/            # Reusable UI widgets (Calendar, StatisticsCard, PrayerCard)
└── main.dart               # App initialization and startup
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.10.7`
- Android SDK (API 21+) / iOS SDK (iOS 11+)
- Command-line tool `flutter` in your system `PATH`

### Run locally

1. **Get dependencies**
   ```bash
   flutter pub get
   ```

2. **Generate Database Adapters**
   Generate generated code for Isar database schemas:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. **Run Application**
   ```bash
   flutter run
   ```

4. **Build APK**
   To build a release installer APK for Android:
   ```bash
   flutter build apk --release
   ```
   *The generated file will be saved at `build/app/outputs/flutter-apk/app-release.apk`.*
