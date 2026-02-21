# brew-assist — Project Plan

> A social coffee app for enthusiasts to log brews, share recipes, discover new coffees, and connect with fellow coffee lovers. Think Untappd, but for coffee.

---

## Table of Contents

- [Vision](#vision)
- [Core Features](#core-features)
- [Design & UI Philosophy](#design--ui-philosophy)
- [Tech Stack](#tech-stack)
- [Data Models](#data-models)
- [App Structure & Navigation](#app-structure--navigation)
- [Milestones](#milestones)
- [Infrastructure & Deployment](#infrastructure--deployment)

---

## Vision

brew-assist is a mobile-first social platform where coffee drinkers can:

- **Check in** coffees they're drinking — rate, review, and share the moment
- **Create and discover brew recipes** — pour-over ratios, espresso pulls, cold brew timers, etc.
- **Connect with others** — follow friends, see their activity, like and comment
- **Explore** — find new coffees, roasters, and cafes based on community ratings

The app should feel personal (your coffee journal) and social (what your friends are brewing) at the same time.

---

## Core Features

### 1. Coffee Check-ins

The heart of the app. A check-in captures a single coffee experience.

- **Coffee selection** — search or add a coffee (name, roaster, origin, process)
- **Rating** — 0.5–5.0 scale (half-star increments)
- **Tasting notes** — free text + selectable flavor tags (e.g., chocolate, citrus, floral, nutty)
- **Brew method** — how it was prepared (espresso, pour-over, French press, AeroPress, etc.)
- **Photo** — optional image of the cup/setup
- **Location** — optional venue/cafe tag
- **Serving style** — black, with milk, iced, etc.

### 2. Brew Recipes

Structured brewing guides that users can create, share, and save.

- **Brew method** — the category (pour-over, espresso, cold brew, etc.)
- **Parameters** — dose, water amount, ratio, grind size, water temp, brew time
- **Steps** — ordered instructions with optional timers
- **Coffee pairing** — optionally link to a specific coffee/roaster
- **Ratings & saves** — community can rate and bookmark recipes
- **Forking** — copy someone's recipe as a starting point for your own

### 3. Equipment

Users can build a gear profile and reference their equipment in check-ins and recipes.

- **Equipment catalog** — shared database of grinders, kettles, scales, brewers (brand + model)
- **My gear** — users add equipment to their profile, optionally marking a primary for each type
- **Grinder-aware grind size** — when creating a recipe or check-in, select your grinder and enter the dial setting. If micron data exists for that grinder model, it's shown automatically.
- **Community-sourced micron maps** — over time, setting→micron mappings improve as users contribute data points
- **Equipment in check-ins** — optionally tag which grinder/brewer/kettle was used

### 4. Social Features

- **User profiles** — avatar, bio, stats (total check-ins, unique coffees, top brew methods)
- **Follow system** — follow/unfollow other users
- **Activity feed** — chronological feed of check-ins and recipes from people you follow
- **Likes & comments** — interact with check-ins and recipes
- **Toasts** — (like Untappd's "toast") a quick appreciation gesture on check-ins

### 5. Discovery & Search

- **Coffee database** — searchable catalog of coffees with aggregate ratings
- **Roaster pages** — browse coffees by roaster, see ratings, info
- **Cafe/venue pages** — see what people are drinking at a location
- **Trending** — popular coffees, recipes, and active users
- **Search** — unified search across coffees, roasters, recipes, and users

---

## Design & UI Philosophy

### Guiding Principles

- **Clean & minimal** — Generous whitespace, clear hierarchy, nothing unnecessary. The UI should feel calm and focused, not cluttered or gamified.
- **Data is the hero** — Ratings, tasting notes, brew parameters, and stats are front and center. Photos support the experience but don't dominate it.
- **Vivino-inspired** — Card-based layouts with strong rating displays, clean detail pages, and a good balance between social and utility. Functional first, social second.
- **Consistent and predictable** — Standard platform patterns (bottom tabs, pull-to-refresh, familiar gestures). No clever tricks — just a well-made app.

### Visual Direction

- **Color palette:**
  - **Base** — White (`#FFFFFF`) backgrounds, cool grays (`#F5F5F5` surface, `#9E9E9E` secondary text, `#2C2C2C` primary text)
  - **Accent** — Muted forest green (`#5B7F5E`) as the primary brand/action color. Used for buttons, active nav icons, selected tags, rating highlights, and gradient cards.
  - **Accent gradient** — Soft gradient (forest green → sage) for feature cards (taste profile, points badges) — similar to the coral gradient blocks in the Vivino reference.
  - **Star ratings** — Accent green for filled stars, light gray for empty.
  - **Error/destructive** — Muted red for warnings and destructive actions only.
- **Typography** — Custom modern sans-serif (Inter, Plus Jakarta Sans, or similar) for a distinct but highly readable identity across both platforms.
- **Theme** — Light mode only for initial release. Design with enough token separation to add dark mode later without a rewrite.
- **Corners & elevation** — Rounded corners on cards and buttons (12–16px radius). Subtle drop shadows for card elevation, no harsh borders.

### Layout & Content Density

- **Card-based feed** — Each check-in or recipe is a self-contained card: coffee name, roaster, rating, brief notes, brew method, and an optional thumbnail. One to two cards visible per screen — easy to scan, not overwhelming.
- **Rating display** — Numeric score (e.g., **4.2**/5) shown prominently, with small star icons as a secondary visual accent. The number is the primary signal.
- **Detail pages** — Clean, scrollable layouts. Key info (rating, method, origin) at the top, then tasting notes, then social interactions (comments, likes) below.

### Imagery & Photography

- **Supporting role** — Photos are optional and displayed as modest thumbnails on cards, expandable on tap. The layout works perfectly without any photos present.
- **No empty states that feel broken** — When there's no photo, the card should still look complete and intentional, not like something is missing.

### Interaction & Motion

- **Subtle and purposeful** — Light transitions between screens, gentle feedback on taps (ripple/highlight). No flashy animations or bouncy effects.
- **Toast gesture** — The "toast" (like/appreciation) should have a small satisfying micro-interaction — this is the one place to add a touch of delight.

### Key UI Patterns (from Vivino reference)

- **Profile screen** — Avatar + name up top, stats row (Check-ins / Following / Followers) as bold numbers with labels, then list-style sections below (wishlist, history, taste profile)
- **Taste profile card** — Gradient accent block showing user's flavor preference summary with a points/level badge
- **Bottom nav** — 5 icons: Feed, Search, + (check-in), Recipes, Profile. Center icon uses accent color to draw the eye.
- **Item cards** — White rounded cards with: name, origin/roaster as subtitle, star row + numeric rating, review count in parentheses
- **Tag chips** — Rounded pill buttons for flavor tags and categories, accent-colored when selected, light gray when unselected
- **Preference sliders** — For taste profile setup (Light↔Bold, Bright↔Deep, Fruity↔Earthy, etc.)
- **Settings** — Simple list rows with chevron disclosure indicators

### Design Reference

| Attribute       | Inspiration                                      |
| --------------- | ------------------------------------------------ |
| Overall layout  | Vivino (profile, cards, nav, ratings)            |
| Card layout     | Vivino check-in feed                             |
| Rating display  | Vivino (numeric + stars)                         |
| Detail pages    | Vivino wine detail / Letterboxd film detail      |
| Accent color    | Forest green `#5B7F5E` (replacing Vivino's coral)|
| Typography      | Inter / Plus Jakarta Sans family                 |
| Overall feel    | Clean utility app — closer to Vivino than Instagram |

---

## Tech Stack

| Layer          | Technology                          |
| -------------- | ----------------------------------- |
| Framework      | Flutter (iOS + Android)             |
| Language       | Dart                                |
| Backend        | Supabase (Postgres, Auth, Storage)  |
| Auth           | Supabase Auth (email, Google, Apple)|
| Database       | Supabase Postgres + Row Level Security |
| File Storage   | Supabase Storage (photos)           |
| State Mgmt     | Riverpod (flutter_riverpod + riverpod_generator) |
| Routing        | go_router                           |

---

## Data Models

### profiles
| Column         | Type      | Notes                       |
| -------------- | --------- | --------------------------- |
| id             | uuid (PK) | References auth.users       |
| username       | text      | Unique                      |
| display_name   | text      |                             |
| avatar_url     | text      | Supabase Storage path       |
| bio            | text      |                             |
| created_at     | timestamp |                             |

### coffees
| Column         | Type      | Notes                       |
| -------------- | --------- | --------------------------- |
| id             | uuid (PK) |                             |
| name           | text      |                             |
| roaster_id     | uuid (FK) | References roasters         |
| origin         | text      | Country/region              |
| process        | text      | Washed, natural, honey, etc.|
| variety        | text      | Bourbon, Gesha, etc.        |
| description    | text      |                             |
| avg_rating     | numeric   | Computed/cached             |
| check_in_count | integer   | Computed/cached             |
| created_by     | uuid (FK) | User who added it           |
| created_at     | timestamp |                             |

### roasters
| Column         | Type      | Notes                       |
| -------------- | --------- | --------------------------- |
| id             | uuid (PK) |                             |
| name           | text      |                             |
| location       | text      | City, state/country         |
| website        | text      |                             |
| logo_url       | text      |                             |
| created_at     | timestamp |                             |

### check_ins
| Column         | Type      | Notes                       |
| -------------- | --------- | --------------------------- |
| id             | uuid (PK) |                             |
| user_id        | uuid (FK) | References profiles         |
| coffee_id      | uuid (FK) | References coffees          |
| rating         | numeric   | 0.5–5.0                     |
| notes          | text      | Free-text tasting notes     |
| flavor_tags    | text[]    | Array of tag strings        |
| brew_method    | text      |                             |
| serving_style  | text      |                             |
| photo_url      | text      |                                |
| venue_id       | uuid (FK) | Optional, references venues    |
| grinder_id     | uuid (FK) | Optional, references equipment_catalog |
| grinder_setting| text      | Dial value, e.g. "4.3"        |
| created_at     | timestamp |                                |

### recipes
| Column            | Type      | Notes                                              |
| ----------------- | --------- | -------------------------------------------------- |
| id                | uuid (PK) |                                                    |
| user_id           | uuid (FK) | Author                                             |
| title             | text      |                                                    |
| brew_method       | text      |                                                    |
| coffee_id         | uuid (FK) | Optional pairing                                   |
| dose_grams        | numeric   |                                                    |
| water_ml          | numeric   | Water input — primarily for pour-over/immersion     |
| yield_grams       | numeric   | Liquid output — primarily for espresso              |
| ratio             | text      | "1:16" for pour-over, "1:2" for espresso            |
| grinder_id        | uuid (FK) | Optional — references equipment_catalog             |
| grinder_setting   | text      | Dial/click value on that grinder, e.g. "4.3"       |
| grind_microns_low | integer   | Optional — micron range lower bound                 |
| grind_microns_high| integer   | Optional — micron range upper bound                 |
| grind_label       | text      | Fallback display: "Medium-fine", "Fine", etc.       |
| water_temp_c      | numeric   |                                                    |
| brew_time_sec     | integer   |                                                    |
| steps             | jsonb     | Ordered list of instructions                       |
| description       | text      |                                                    |
| forked_from       | uuid (FK) | Optional, references recipes                       |
| avg_rating        | numeric   | Computed/cached                                    |
| save_count        | integer   | Computed/cached                                    |
| created_at        | timestamp |                                                    |

**Steps jsonb schema** — flexible per brew method:
```json
// Espresso example
[
  { "type": "prep", "label": "WDT distribute" },
  { "type": "prep", "label": "Tamp", "pressure_kg": 14 },
  { "type": "brew", "label": "Pre-infusion", "pressure_bar": 3, "duration_sec": 8 },
  { "type": "brew", "label": "Ramp to peak", "pressure_bar": 9, "duration_sec": 5 },
  { "type": "brew", "label": "Hold", "pressure_bar": 9, "duration_sec": 15 },
  { "type": "brew", "label": "Ramp down", "pressure_bar": 6, "duration_sec": 7 }
]

// Pour-over example
[
  { "type": "brew", "label": "Bloom", "water_ml": 60, "duration_sec": 30 },
  { "type": "brew", "label": "First pour", "water_ml": 150, "duration_sec": 30 },
  { "type": "brew", "label": "Second pour", "water_ml": 200, "duration_sec": 30 },
  { "type": "brew", "label": "Drawdown", "duration_sec": 90 }
]
```
Steps use `type` ("prep" or "brew") and method-specific optional fields (`pressure_bar`, `water_ml`, `pressure_kg`, `duration_sec`). This keeps the schema flexible without needing separate models per brew method.

**Grind size UX strategy:**
- Power users who know their microns can enter a range directly (e.g., 500–650μm)
- Users who own a known grinder can pick it from their equipment and enter the dial setting (e.g., "ODE Gen 2 | 4.3") — if we have a micron map, we auto-fill the range
- Casual users can just pick a label ("Fine", "Medium-fine", "Medium", "Medium-coarse", "Coarse")
- Recipe display normalizes to: **grinder + setting** if available, with micron range or label as subtitle

### equipment_catalog
Shared database of known equipment. Community-contributed, searchable.

| Column           | Type      | Notes                                          |
| ---------------- | --------- | ---------------------------------------------- |
| id               | uuid (PK) |                                                |
| type             | text      | 'grinder', 'kettle', 'scale', 'brewer'         |
| brand            | text      | e.g., Fellow, Baratza, Acaia                   |
| model            | text      | e.g., ODE Gen 2, Stagg EKG, Lunar              |
| customizations   | text      | e.g., SSP Burrs, Custom Flow Controller        |
| image_url        | text      | Product photo                                  |
| grind_range_min  | integer   | Microns — only for grinders                    |
| grind_range_max  | integer   | Microns — only for grinders                    |
| grind_settings   | jsonb     | Optional setting→micron map (see below)        |
| created_by       | uuid (FK) | User who added it                              |
| created_at       | timestamp |                                                |

**grind_settings jsonb example** (for a Fellow ODE Gen 2):
```json
{
  "type": "numeric_range",
  "min": 1.0,
  "max": 11.0,
  "step": 0.1,
  "micron_map": [
    { "setting": 1.0, "microns_low": 200, "microns_high": 300 },
    { "setting": 4.0, "microns_low": 500, "microns_high": 650 },
    { "setting": 8.0, "microns_low": 900, "microns_high": 1050 }
  ]
}
```

This lets us eventually interpolate between known data points to estimate microns from a dial setting — but it's not required. The map gets better over time as users contribute data.

### user_equipment
Links users to the gear they own.

| Column           | Type      | Notes                             |
| ---------------- | --------- | --------------------------------- |
| id               | uuid (PK) |                                   |
| user_id          | uuid (FK) | References profiles               |
| equipment_id     | uuid (FK) | References equipment_catalog      |
| nickname         | text      | Optional — "my office grinder"    |
| is_primary       | boolean   | Default gear for that type        |
| rating           | float     | Optional rating (0-5.0)           |
| created_at       | timestamp |                                   |

### venues
| Column         | Type      | Notes                       |
| -------------- | --------- | --------------------------- |
| id             | uuid (PK) |                             |
| name           | text      |                             |
| address        | text      |                             |
| lat            | numeric   |                             |
| lng            | numeric   |                             |
| created_at     | timestamp |                             |

### follows
| Column         | Type      | Notes                       |
| -------------- | --------- | --------------------------- |
| follower_id    | uuid (FK) | References profiles         |
| following_id   | uuid (FK) | References profiles         |
| created_at     | timestamp |                             |
| PK             |           | (follower_id, following_id) |

### likes
| Column         | Type      | Notes                       |
| -------------- | --------- | --------------------------- |
| id             | uuid (PK) |                             |
| user_id        | uuid (FK) |                             |
| target_type    | text      | 'check_in' or 'recipe'     |
| target_id      | uuid      | Polymorphic FK              |
| created_at     | timestamp |                             |

### comments
| Column         | Type      | Notes                       |
| -------------- | --------- | --------------------------- |
| id             | uuid (PK) |                             |
| user_id        | uuid (FK) |                             |
| target_type    | text      | 'check_in' or 'recipe'     |
| target_id      | uuid      | Polymorphic FK              |
| body           | text      |                             |
| created_at     | timestamp |                             |

### saved_recipes
| Column         | Type      | Notes                       |
| -------------- | --------- | --------------------------- |
| user_id        | uuid (FK) |                             |
| recipe_id      | uuid (FK) |                             |
| created_at     | timestamp |                             |
| PK             |           | (user_id, recipe_id)        |

---

## App Structure & Navigation

Bottom navigation with 4-5 tabs:

```
┌─────────────────────────────────────────────┐
│                  App Shell                   │
├──────┬──────┬──────┬──────┬────────┤
│ Feed │Search│  +   │Recipes│Profile│
└──────┴──────┴──────┴──────┴────────┘
```

### Screens

| Screen              | Description                                    |
| ------------------- | ---------------------------------------------- |
| **Feed**            | Activity feed of check-ins from followed users |
| **Search/Discover** | Search coffees, roasters, users; trending view |
| **New Check-in**    | Multi-step flow: pick coffee → rate → details  |
| **Recipes**         | Browse/search recipes; saved recipes tab       |
| **Profile**         | Your stats, check-in history, followers        |
| Coffee Detail       | Coffee info, aggregate rating, recent check-ins|
| Roaster Detail      | Roaster info, their coffees                    |
| Recipe Detail       | Full recipe view with steps and timer          |
| User Profile        | Another user's profile + follow button         |
| Settings            | Account, preferences, logout                   |

---

## Milestones

### Phase 1 — Foundation (MVP)

Get the core loop working end-to-end.

- [ ] Project setup (Flutter + Supabase integration)
- [ ] Supabase schema: profiles, coffees, roasters, check_ins
- [ ] Auth (email + social login)
- [ ] User profile creation/editing
- [ ] Coffee database: add coffees, search coffees
- [ ] Check-in flow: select coffee → rate → add notes/method → submit
- [ ] Personal check-in history on profile
- [ ] Basic feed (global or following-based)
- [ ] Bottom tab navigation shell

### Phase 2 — Social

Make it feel alive.

- [ ] Follow/unfollow users
- [ ] Activity feed filtered to followed users
- [ ] Likes (toasts) on check-ins
- [ ] Comments on check-ins
- [ ] User search and profile viewing
- [ ] Push notification groundwork

### Phase 3 — Recipes

The second pillar of the app.

- [ ] Recipe creation flow (method, params, steps)
- [ ] Recipe detail view with timer functionality
- [ ] Recipe search and browse
- [ ] Save/bookmark recipes
- [ ] Fork a recipe
- [ ] Rate recipes
- [ ] Link recipes to coffees

### Phase 4 — Discovery & Polish

Help users find great coffee.

- [ ] Roaster pages with coffee listings
- [ ] Venue/cafe pages
- [ ] Trending coffees and recipes
- [ ] Photo uploads on check-ins
- [ ] Flavor tag system with autocomplete
- [ ] Aggregate ratings and stats on coffee detail pages
- [ ] Improved search with filters

### Phase 5 — Future / Nice-to-Have

- [ ] Badges and achievements (e.g., "Tried 10 origins", "Pour-over pro")
- [ ] Coffee wishlist
- [ ] Barista mode (cafe owner tools)
- [ ] Brew timer standalone tool
- [ ] Dark mode
- [ ] Export data (journal/CSV)
- [ ] Web companion app

---

## Infrastructure & Deployment

### Architecture

No custom application server. The Flutter app communicates directly with Supabase's managed APIs:

| Layer              | Hosted by          | Notes                                          |
| ------------------ | ------------------ | ---------------------------------------------- |
| Database (Postgres)| Supabase           | Managed instance, RLS for security              |
| Auth               | Supabase Auth      | Email, Google, Apple sign-in                    |
| File Storage       | Supabase Storage   | Photo uploads, avatars, equipment images        |
| Realtime           | Supabase Realtime  | WebSocket subscriptions for live feed updates   |
| Server-side logic  | Supabase Edge Functions | Serverless Deno functions if needed (e.g., aggregate rating recalculation, moderation hooks) |
| Mobile app         | App Store / Google Play | Flutter compiles to native iOS + Android     |

### Supabase Pricing Tiers

| Tier       | Cost      | Database | Storage | MAUs  | Bandwidth | Use case                    |
| ---------- | --------- | -------- | ------- | ----- | --------- | --------------------------- |
| **Free**   | $0/mo     | 500MB    | 1GB     | 50K   | 5GB       | Development + early launch  |
| **Pro**    | $25/mo    | 8GB      | 100GB   | 100K  | 250GB     | Post-launch growth          |
| **Team**   | $599/mo   | 8GB+     | 100GB+  | 100K+ | 250GB+    | Scaling / compliance needs  |

Overage on Pro: storage $0.021/GB, bandwidth $0.09/GB.

### Other Costs

| Item                       | Cost         |
| -------------------------- | ------------ |
| Apple Developer Program    | $99/year     |
| Google Play Developer      | $25 one-time |
| Custom domain (optional)   | ~$12/year    |

### Cost Trajectory

- **Development + beta**: Free tier ($0) — 500MB Postgres handles text-heavy data easily
- **Launch to ~1K users**: Likely still free tier
- **Growth past free limits**: Pro at $25/mo covers a substantial user base
- **Primary cost driver**: Photo storage — mitigate by compressing/resizing images client-side before upload

### Deployment Workflow

- **Supabase**: Manage schema via migration files (`supabase/migrations/`). Use Supabase CLI for local dev, push migrations to hosted project for staging/production.
- **iOS**: Build via `flutter build ios`, distribute through App Store Connect / TestFlight
- **Android**: Build via `flutter build appbundle`, distribute through Google Play Console / internal testing tracks

---

## Open Questions

- **~~State management~~** — ~~Riverpod, Bloc, or Provider?~~ Decided: **Riverpod**.
- **Coffee data seeding** — Do we seed an initial database of coffees/roasters, or purely user-generated?
- **Offline support** — How important is offline-first? Affects architecture significantly.
- **Moderation** — Any content moderation strategy for user-submitted data?
