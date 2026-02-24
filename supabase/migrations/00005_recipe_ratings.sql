-- ---------------------------------------------------------------------------
-- recipe_ratings — users can rate recipes 0.5–5.0 stars
-- ---------------------------------------------------------------------------

create table public.recipe_ratings (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  recipe_id  uuid not null references public.recipes (id) on delete cascade,
  rating     numeric(2,1) not null check (rating >= 0.5 and rating <= 5.0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, recipe_id)
);

create index idx_recipe_ratings_user_id   on public.recipe_ratings (user_id);
create index idx_recipe_ratings_recipe_id on public.recipe_ratings (recipe_id);

alter table public.recipe_ratings enable row level security;

create policy "Recipe ratings are viewable by everyone"
  on public.recipe_ratings for select
  using (true);

create policy "Users can insert own ratings"
  on public.recipe_ratings for insert
  with check (auth.uid() = user_id);

create policy "Users can update own ratings"
  on public.recipe_ratings for update
  using (auth.uid() = user_id);

create policy "Users can delete own ratings"
  on public.recipe_ratings for delete
  using (auth.uid() = user_id);

create trigger set_recipe_ratings_updated_at
  before update on public.recipe_ratings
  for each row execute function public.handle_updated_at();

-- ---------------------------------------------------------------------------
-- RPC: recalculate recipes.avg_rating from the ratings table
-- ---------------------------------------------------------------------------

create or replace function public.update_recipe_avg_rating(rid uuid)
returns void
language plpgsql
security definer
as $$
begin
  update public.recipes
  set avg_rating = (
    select round(avg(rating)::numeric, 1)
    from public.recipe_ratings
    where recipe_id = rid
  )
  where id = rid;
end;
$$;
