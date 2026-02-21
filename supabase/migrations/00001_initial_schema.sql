-- =============================================================================
-- brew-assist: Initial Schema Migration
-- =============================================================================
-- Creates all tables, indexes, RLS policies, and triggers for the brew-assist
-- coffee social platform.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 0. Extensions
-- ---------------------------------------------------------------------------
create extension if not exists "uuid-ossp" with schema extensions;

-- ---------------------------------------------------------------------------
-- 1. Helper: updated_at trigger function
-- ---------------------------------------------------------------------------
create or replace function public.handle_updated_at()
returns trigger
language plpgsql
security definer
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- 2. profiles
-- ---------------------------------------------------------------------------
create table public.profiles (
  id           uuid primary key references auth.users on delete cascade,
  username     text unique not null,
  display_name text,
  avatar_url   text,
  bio          text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index idx_profiles_username on public.profiles (username);

alter table public.profiles enable row level security;

-- Anyone can read profiles
create policy "Profiles are viewable by everyone"
  on public.profiles for select
  using (true);

-- Users can insert their own profile
create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Users can update their own profile
create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute function public.handle_updated_at();

-- ---------------------------------------------------------------------------
-- 3. Auto-create profile on signup
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, username, display_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'username', 'user_' || substr(new.id::text, 1, 8)),
    coalesce(new.raw_user_meta_data ->> 'display_name', new.raw_user_meta_data ->> 'full_name'),
    new.raw_user_meta_data ->> 'avatar_url'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- 4. roasters
-- ---------------------------------------------------------------------------
create table public.roasters (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  location   text,
  website    text,
  logo_url   text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_roasters_name on public.roasters (name);

alter table public.roasters enable row level security;

create policy "Roasters are viewable by everyone"
  on public.roasters for select
  using (true);

create policy "Authenticated users can insert roasters"
  on public.roasters for insert
  with check (auth.role() = 'authenticated');

create policy "Authenticated users can update roasters"
  on public.roasters for update
  using (auth.role() = 'authenticated');

create trigger set_roasters_updated_at
  before update on public.roasters
  for each row execute function public.handle_updated_at();

-- ---------------------------------------------------------------------------
-- 5. coffees
-- ---------------------------------------------------------------------------
create table public.coffees (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  roaster_id     uuid references public.roasters (id) on delete set null,
  origin         text,
  process        text,
  variety        text,
  description    text,
  avg_rating     numeric(3,2) default 0,
  check_in_count integer not null default 0,
  created_by     uuid references public.profiles (id) on delete set null,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create index idx_coffees_roaster_id  on public.coffees (roaster_id);
create index idx_coffees_created_by  on public.coffees (created_by);
create index idx_coffees_name        on public.coffees (name);
create index idx_coffees_origin      on public.coffees (origin);
create index idx_coffees_avg_rating  on public.coffees (avg_rating desc);

alter table public.coffees enable row level security;

create policy "Coffees are viewable by everyone"
  on public.coffees for select
  using (true);

create policy "Authenticated users can insert coffees"
  on public.coffees for insert
  with check (auth.uid() = created_by);

create policy "Creator can update own coffees"
  on public.coffees for update
  using (auth.uid() = created_by)
  with check (auth.uid() = created_by);

create trigger set_coffees_updated_at
  before update on public.coffees
  for each row execute function public.handle_updated_at();

-- ---------------------------------------------------------------------------
-- 6. equipment_catalog
-- ---------------------------------------------------------------------------
create table public.equipment_catalog (
  id              uuid primary key default gen_random_uuid(),
  type            text not null check (type in ('grinder', 'kettle', 'scale', 'brewer')),
  brand           text not null,
  model           text not null,
  customizations  text,
  image_url       text,
  grind_range_min integer,
  grind_range_max integer,
  grind_settings  jsonb,
  created_by      uuid references public.profiles (id) on delete set null,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index idx_equipment_catalog_type       on public.equipment_catalog (type);
create index idx_equipment_catalog_brand      on public.equipment_catalog (brand);
create index idx_equipment_catalog_created_by on public.equipment_catalog (created_by);

alter table public.equipment_catalog enable row level security;

create policy "Equipment catalog is viewable by everyone"
  on public.equipment_catalog for select
  using (true);

create policy "Authenticated users can insert equipment"
  on public.equipment_catalog for insert
  with check (auth.uid() = created_by);

create policy "Creator can update own equipment entries"
  on public.equipment_catalog for update
  using (auth.uid() = created_by)
  with check (auth.uid() = created_by);

create trigger set_equipment_catalog_updated_at
  before update on public.equipment_catalog
  for each row execute function public.handle_updated_at();

-- ---------------------------------------------------------------------------
-- 7. user_equipment
-- ---------------------------------------------------------------------------
create table public.user_equipment (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles (id) on delete cascade,
  equipment_id uuid not null references public.equipment_catalog (id) on delete cascade,
  nickname     text,
  is_primary   boolean not null default false,
  rating       real check (rating >= 0 and rating <= 5.0),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index idx_user_equipment_user_id      on public.user_equipment (user_id);
create index idx_user_equipment_equipment_id on public.user_equipment (equipment_id);

alter table public.user_equipment enable row level security;

create policy "User equipment is viewable by everyone"
  on public.user_equipment for select
  using (true);

create policy "Users can insert own equipment links"
  on public.user_equipment for insert
  with check (auth.uid() = user_id);

create policy "Users can update own equipment links"
  on public.user_equipment for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own equipment links"
  on public.user_equipment for delete
  using (auth.uid() = user_id);

create trigger set_user_equipment_updated_at
  before update on public.user_equipment
  for each row execute function public.handle_updated_at();

-- ---------------------------------------------------------------------------
-- 8. venues
-- ---------------------------------------------------------------------------
create table public.venues (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  address    text,
  lat        numeric(10,7),
  lng        numeric(10,7),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_venues_name on public.venues (name);

alter table public.venues enable row level security;

create policy "Venues are viewable by everyone"
  on public.venues for select
  using (true);

create policy "Authenticated users can insert venues"
  on public.venues for insert
  with check (auth.role() = 'authenticated');

create policy "Authenticated users can update venues"
  on public.venues for update
  using (auth.role() = 'authenticated');

create trigger set_venues_updated_at
  before update on public.venues
  for each row execute function public.handle_updated_at();

-- ---------------------------------------------------------------------------
-- 9. check_ins
-- ---------------------------------------------------------------------------
create table public.check_ins (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references public.profiles (id) on delete cascade,
  coffee_id       uuid not null references public.coffees (id) on delete cascade,
  rating          numeric(2,1) not null check (rating >= 0.5 and rating <= 5.0),
  notes           text,
  flavor_tags     text[],
  brew_method     text,
  serving_style   text,
  photo_url       text,
  venue_id        uuid references public.venues (id) on delete set null,
  grinder_id      uuid references public.equipment_catalog (id) on delete set null,
  grinder_setting text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index idx_check_ins_user_id    on public.check_ins (user_id);
create index idx_check_ins_coffee_id  on public.check_ins (coffee_id);
create index idx_check_ins_venue_id   on public.check_ins (venue_id);
create index idx_check_ins_grinder_id on public.check_ins (grinder_id);
create index idx_check_ins_created_at on public.check_ins (created_at desc);
create index idx_check_ins_brew_method on public.check_ins (brew_method);

alter table public.check_ins enable row level security;

create policy "Check-ins are viewable by everyone"
  on public.check_ins for select
  using (true);

create policy "Users can insert own check-ins"
  on public.check_ins for insert
  with check (auth.uid() = user_id);

create policy "Users can update own check-ins"
  on public.check_ins for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own check-ins"
  on public.check_ins for delete
  using (auth.uid() = user_id);

create trigger set_check_ins_updated_at
  before update on public.check_ins
  for each row execute function public.handle_updated_at();

-- ---------------------------------------------------------------------------
-- 10. recipes
-- ---------------------------------------------------------------------------
create table public.recipes (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null references public.profiles (id) on delete cascade,
  title              text not null,
  brew_method        text not null,
  coffee_id          uuid references public.coffees (id) on delete set null,
  dose_grams         numeric(6,2),
  water_ml           numeric(7,2),
  yield_grams        numeric(6,2),
  ratio              text,
  grinder_id         uuid references public.equipment_catalog (id) on delete set null,
  grinder_setting    text,
  grind_microns_low  integer,
  grind_microns_high integer,
  grind_label        text,
  water_temp_c       numeric(4,1),
  brew_time_sec      integer,
  steps              jsonb,
  description        text,
  forked_from        uuid references public.recipes (id) on delete set null,
  avg_rating         numeric(3,2) default 0,
  save_count         integer not null default 0,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

create index idx_recipes_user_id     on public.recipes (user_id);
create index idx_recipes_coffee_id   on public.recipes (coffee_id);
create index idx_recipes_grinder_id  on public.recipes (grinder_id);
create index idx_recipes_forked_from on public.recipes (forked_from);
create index idx_recipes_brew_method on public.recipes (brew_method);
create index idx_recipes_created_at  on public.recipes (created_at desc);
create index idx_recipes_avg_rating  on public.recipes (avg_rating desc);

alter table public.recipes enable row level security;

create policy "Recipes are viewable by everyone"
  on public.recipes for select
  using (true);

create policy "Users can insert own recipes"
  on public.recipes for insert
  with check (auth.uid() = user_id);

create policy "Users can update own recipes"
  on public.recipes for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own recipes"
  on public.recipes for delete
  using (auth.uid() = user_id);

create trigger set_recipes_updated_at
  before update on public.recipes
  for each row execute function public.handle_updated_at();

-- ---------------------------------------------------------------------------
-- 11. follows
-- ---------------------------------------------------------------------------
create table public.follows (
  follower_id  uuid not null references public.profiles (id) on delete cascade,
  following_id uuid not null references public.profiles (id) on delete cascade,
  created_at   timestamptz not null default now(),
  primary key (follower_id, following_id),
  constraint no_self_follow check (follower_id <> following_id)
);

create index idx_follows_follower_id  on public.follows (follower_id);
create index idx_follows_following_id on public.follows (following_id);

alter table public.follows enable row level security;

create policy "Follows are viewable by everyone"
  on public.follows for select
  using (true);

create policy "Users can insert own follows"
  on public.follows for insert
  with check (auth.uid() = follower_id);

create policy "Users can delete own follows"
  on public.follows for delete
  using (auth.uid() = follower_id);

-- ---------------------------------------------------------------------------
-- 12. likes
-- ---------------------------------------------------------------------------
create table public.likes (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  target_type text not null check (target_type in ('check_in', 'recipe')),
  target_id   uuid not null,
  created_at  timestamptz not null default now(),
  constraint unique_like unique (user_id, target_type, target_id)
);

create index idx_likes_user_id                on public.likes (user_id);
create index idx_likes_target_type_target_id  on public.likes (target_type, target_id);

alter table public.likes enable row level security;

create policy "Likes are viewable by everyone"
  on public.likes for select
  using (true);

create policy "Users can insert own likes"
  on public.likes for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own likes"
  on public.likes for delete
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- 13. comments
-- ---------------------------------------------------------------------------
create table public.comments (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  target_type text not null check (target_type in ('check_in', 'recipe')),
  target_id   uuid not null,
  body        text not null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index idx_comments_user_id               on public.comments (user_id);
create index idx_comments_target_type_target_id on public.comments (target_type, target_id);
create index idx_comments_created_at            on public.comments (created_at desc);

alter table public.comments enable row level security;

create policy "Comments are viewable by everyone"
  on public.comments for select
  using (true);

create policy "Users can insert own comments"
  on public.comments for insert
  with check (auth.uid() = user_id);

create policy "Users can update own comments"
  on public.comments for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own comments"
  on public.comments for delete
  using (auth.uid() = user_id);

create trigger set_comments_updated_at
  before update on public.comments
  for each row execute function public.handle_updated_at();

-- ---------------------------------------------------------------------------
-- 14. saved_recipes
-- ---------------------------------------------------------------------------
create table public.saved_recipes (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  recipe_id  uuid not null references public.recipes (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, recipe_id)
);

create index idx_saved_recipes_user_id   on public.saved_recipes (user_id);
create index idx_saved_recipes_recipe_id on public.saved_recipes (recipe_id);

alter table public.saved_recipes enable row level security;

create policy "Saved recipes are viewable by the owner"
  on public.saved_recipes for select
  using (auth.uid() = user_id);

create policy "Users can insert own saved recipes"
  on public.saved_recipes for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own saved recipes"
  on public.saved_recipes for delete
  using (auth.uid() = user_id);

-- =============================================================================
-- Done. All tables, indexes, RLS policies, and triggers created.
-- =============================================================================
