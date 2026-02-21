# brew-assist

A social coffee app for enthusiasts to log brews, share recipes, discover new coffees, and connect with fellow coffee lovers. Think Untappd, but for coffee.

Built with Flutter + Supabase.

## Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (3.32.0+)
- [Xcode](https://apps.apple.com/us/app/xcode/id497799835) (for iOS/macOS builds)
- A [Supabase](https://supabase.com) project

## Getting Started

### 1. Clone the repo

```bash
git clone https://github.com/landanqrew/brew-assist.git
cd brew-assist
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Set up Supabase

Create a Supabase project at [supabase.com](https://supabase.com), then run the initial migration by pasting the contents of `supabase/migrations/00001_initial_schema.sql` into the SQL Editor in your Supabase dashboard.

### 4. Configure environment

Copy the example env file and fill in your Supabase credentials:

```bash
cp .env.example.json .env.json
```

Edit `.env.json` with your project URL and anon key (found in Supabase → Settings → API):

```json
{
  "SUPABASE_URL": "https://your-project-id.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key-here"
}
```

> **Note:** `.env.json` is gitignored and will never be committed.

### 5. Run the app

```bash
# macOS
flutter run -d macos --dart-define-from-file=.env.json

# iOS simulator
flutter run -d iPhone --dart-define-from-file=.env.json

# Android emulator
flutter run -d android --dart-define-from-file=.env.json
```

## Testing

```bash
# Static analysis
flutter analyze

# Run tests
flutter test
```

## Project Structure

```
lib/
  core/
    router.dart              # GoRouter configuration
    supabase/                # Supabase client setup
    theme/                   # Design system (colors, typography, theme)
  models/                    # Data models with json_serializable
  providers/                 # Riverpod state management
  screens/
    auth/                    # Login, signup
    check_in/                # Check-in flow
    coffee/                  # Add coffee
    coffee_detail/           # Coffee detail view
    feed/                    # Activity feed
    profile/                 # Profile, edit profile
    recipes/                 # Recipes (Phase 3)
    search/                  # Coffee search & discovery
    settings/                # App settings
  widgets/                   # Shared widgets (check-in card, nav bar)
supabase/
  migrations/                # SQL migration files
```

## Tech Stack

| Layer         | Technology                                    |
| ------------- | --------------------------------------------- |
| Framework     | Flutter (iOS, Android, macOS)                 |
| Backend       | Supabase (Postgres, Auth, Storage)            |
| State Mgmt    | Riverpod                                      |
| Routing       | go_router                                     |
| Design        | Material 3, Plus Jakarta Sans, forest green accent |
