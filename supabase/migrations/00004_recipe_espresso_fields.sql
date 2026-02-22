-- Add espresso-specific columns and brewer FK to recipes.
-- All nullable — only populated for espresso recipes.

alter table public.recipes
  add column brewer_id            uuid references public.equipment_catalog (id) on delete set null,
  add column distribution_method  text,
  add column tamp_pressure_kg     real,
  add column pre_infusion_sec     integer,
  add column max_pressure_bar     real,
  add column milk_notes           text;

create index idx_recipes_brewer_id on public.recipes (brewer_id);
