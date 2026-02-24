# brew-assist — Project Instructions

## Design System

All screens must conform to the visual direction defined in `PLAN.md` § Design & UI Philosophy. The design system is implemented in `lib/core/theme/` and enforced via `AppTheme.light` in `ThemeData`. Follow these rules when building UI:

### Use the Theme — Don't Override It

- **Never hardcode** colors, text styles, radii, or shadows inline. Use `AppColors`, `AppTextStyles`, and standard Material widgets that inherit from the theme.
- If a widget looks wrong, fix the theme — don't add a one-off override in the screen.

### Cards

- Use `Card` widget (picks up theme: 16px radius, subtle border, no elevation).
- For **hand-built card containers** (e.g. selected-state cards in forms), use `AppColors.cardDecoration` instead of ad-hoc `BoxDecoration`:
  ```dart
  Container(decoration: AppColors.cardDecoration, ...)
  ```
- Shadow spec: `color: shadow @ 0.04 alpha`, `blurRadius: 12`, `offset: (0, 4)`.

### Text Fields

- Filled surface (`#F5F5F5`), **borderless by default**, 16px radius.
- Primary-colored border appears **only on focus**.
- All handled by `InputDecorationTheme` — just use `TextField` / `TextFormField`.

### Buttons

- Standard actions: use `ElevatedButton`, `OutlinedButton`, `TextButton` (16px radius via theme).
- **Primary CTA** (main submit button on a screen): use `GradientButton` widget (`lib/widgets/gradient_button.dart`) — accent gradient + glowing shadow.
- Disabled buttons use `AppColors.disabled` automatically.

### Chips & Tags

- Pill-shaped, 24px radius (via `ChipThemeData`).
- Use `ChoiceChip` for single-select, `FilterChip` for multi-select.
- No extra styling needed — theme handles selected/unselected states.

### Typography

- Use `AppTextStyles.*` constants. Key styles:
  - `titleLarge` — screen headers
  - `titleMedium` — section headers inside forms
  - `titleSmall` — card titles, list item titles
  - `bodyMedium` — default body text
  - `bodySmall` — secondary / supporting text
  - `kicker` — uppercase category labels inside cards (use with `.toUpperCase()`)
  - `ratingLarge` / `ratingSmall` — numeric rating display
- **Kicker labels**: small all-caps text with wide letter spacing, used to label data types inside cards (e.g. "ROASTER", "ORIGIN").

### Iconography

- Key icons inside cards go in a **soft rounded-square container**:
  ```dart
  Container(
    width: 44, height: 44,
    decoration: BoxDecoration(
      color: AppColors.primaryLight.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(Icons.coffee, color: AppColors.primary, size: 24),
  )
  ```

### App Bars

- Flat, borderless. `elevation: 0`, `scrolledUnderElevation: 0`. Handled by theme.

### Transitions

- Use `kTransitionDuration` (200ms) and `kTransitionCurve` (easeInOut) from `app_colors.dart`.
- `AnimatedSize` for revealing/hiding form sections.
- `AnimatedContainer` for state changes on cards.

---

## Architecture Patterns

### State Management

- **Riverpod** (`flutter_riverpod`). No Bloc, no Provider.
- Read providers: `FutureProvider` / `FutureProvider.family` for fetching data.
- Mutations: `StateNotifier<SubmissionState>` + `StateNotifierProvider` pattern (see `check_in_provider.dart`).

### Form Screens

- `ConsumerStatefulWidget` with **local `setState`** for all form fields.
- Only call the notifier at submit time.
- Follow the pattern in `check_in_screen.dart`.

### Routing

- `go_router` with `StatefulShellRoute.indexedStack` for tabs.
- Detail routes use `parentNavigatorKey: _rootNavigatorKey` for full-screen push.
- Parameterized routes: `/recipe/:id`, query params: `?coffeeId=...`.

### Models

- `json_serializable` + `json_annotation` for all data models.
- Run `dart run build_runner build` after editing model files.
- `@JsonKey(name: 'snake_case')` for all DB column mappings.

### Supabase

- Client accessed via `supabase` global from `supabase_config.dart`.
- Joins: `.select('*, related_table(*)')`.
- Auth user: `ref.read(authProvider).user?.id`.

---

## Commands

```
flutter pub get                                         # Install deps
flutter run -d macos --dart-define-from-file=.env.json  # Run on macOS
flutter analyze                                         # Static analysis
flutter test                                            # Run tests
dart run build_runner build                             # Regenerate .g.dart
```
