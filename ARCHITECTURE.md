# Not To Do - Architecture Document

This document serves as the single source of truth for the architectural patterns, state management, and behavioral domains of the **Not To Do** Flutter application. It is structured for rapid comprehension by future engineers and AI agents.

## 1. State Management (Riverpod 2.x)

We exclusively use **Riverpod 2.x** with the Code Generation approach (`@riverpod`). 

- **Providers**: Located in `lib/core/providers/`.
- **Notifier Classes**: We use `Notifier` and `AsyncNotifier` for complex state mutations.
- **ProviderScope**: Encapsulates the root of the app.
- **No StatefulWidgets**: For global state. UI components rely on `ConsumerWidget` or `ConsumerStatefulWidget` (when local animation controllers are strictly required).
- **Domain Interdependence**: Providers like `filteredTimelineProvider` reactively compute state based on settings overrides and the core `timelineNotifierProvider`.

## 2. Local Database (Hive)

We use **Hive** for ultra-fast, strictly typed local storage. We do not use SQLite or remote databases for primary local interactions to guarantee offline functionality and zero latency.

- **Initialization**: Bootstrapped in `main.dart` via `Hive.initFlutter()`.
- **Boxes**:
  - `settings_box`: Primitive key-value pairs (`curfewEnabled`, `breathingCycleSeconds`, `maxDailyEnergy`, etc.). Does not require a TypeAdapter.
  - `timeline_blocks_box`: Stores `TimelineBlock` (Type ID 1).
  - `habits_box`: Stores `AntiHabit` (Type ID 2).
  - `academic_events_box`: Stores `AcademicEvent` (Type ID 0).
- **Adapters**: Must be generated via `flutter pub run build_runner build --delete-conflicting-outputs` when domain models change. Do **not** reorder or delete existing `@HiveField` IDs. New fields must always append to the end.

## 3. Design System (Cosmic Obsidian & Matcha Oat)

Our UI strictly follows a unified tokenized design system powered by Riverpod. We eschew standard Material defaults.

- **AppCustomColors**: Defined in `lib/core/theme/app_colors.dart`. Extended via `ThemeExtension`. Always accessed via `AppColors.of(context).<token>`.
- **Primary Palette**: Cosmic Obsidian (Dark Mode) and Matcha Oat Latte (Light Mode).
- **Core Widgets**:
  - `BentoCard`: A standard glassmorphic/1px bordered container serving as the base for most UI.
  - `BentoEmptyState`: Reusable empty states adhering to the visual language.
  - `SpringBounce`: Wraps interactive elements, replacing standard `InkWell` ripples with scaling physics-based haptics.
- **Bento Floating Dock**: Replaces the standard Material `BottomNavigationBar`. Positioned via `Stack` in `MainScaffold`.

## 4. Behavioral Defense Layers

The app utilizes specialized domain logic to enforce friction and protect user focus.

- **Bedtime Curfew Sentry**: A full-screen `CurfewSentryOverlay` wrapping the main scaffold. Dynamically locks out content across midnight bounds and same-day bounds based on Hive settings.
- **Breathing Shield**: A cognitive friction layer implemented in `BreathingShieldDialog`. Forces a haptic-driven, un-skippable timed delay (default 4 seconds) before critical destructive actions (e.g., breaking a habit).
- **Energy Budget System**: A dynamic mathematical layer tracking cumulative cognitive drain. `TimelineBlock` instances possess an `energyCost`. The `DailyEnergyGauge` visually represents the threshold against dynamic `maxDailyEnergy` and `burnoutThreshold` values sourced from Hive.

## 5. Directory Structure

```text
lib/
 â”œâ”€â”€ core/
 â”‚   â”œâ”€â”€ constants/     # API keys, global statics
 â”‚   â”œâ”€â”€ models/        # Hive objects
 â”‚   â”œâ”€â”€ providers/     # Global Riverpod state
 â”‚   â”œâ”€â”€ repositories/  # Hive Box abstractions
 â”‚   â”œâ”€â”€ services/      # Gemini parsers, sync logic
 â”‚   â”œâ”€â”€ theme/         # AppCustomColors, AppTheme
 â”‚   â””â”€â”€ widgets/       # Global reusable widgets (BentoCard, SpringBounce)
 â””â”€â”€ features/
     â”œâ”€â”€ dashboard/     # Student Life OS
     â”œâ”€â”€ defense/       # Curfew Sentry, Breathing Shield
     â”œâ”€â”€ habits/        # Anti-Habits Vault
     â”œâ”€â”€ navigation/    # MainScaffold & Floating Dock
     â”œâ”€â”€ onboarding/    # 90-Second Commitment Flow
     â”œâ”€â”€ settings/      # Settings Sheet & API config
     â””â”€â”€ today/         # Timeline & Energy Gauge
```

## 6. Development Rules & Guardrails
- **Zero Hardcoding**: All behavioral thresholds (colors, timings, drain limits) must be backed by a Hive settings configuration.
- **Null Safety**: Strict enforcement. Use `const` meticulously.
- **E2E Testing Rules**: UI modifications must be vetted for layout overflows on 390x844 viewports.
- **AI Tooling Guardrails**: No LLM should leave `// TODO` stubs. All edits must be syntactically complete.
