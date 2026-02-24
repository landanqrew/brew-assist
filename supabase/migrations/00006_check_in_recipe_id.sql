-- Link a check-in to the recipe used for the brew.
ALTER TABLE public.check_ins
  ADD COLUMN recipe_id uuid REFERENCES public.recipes(id) ON DELETE SET NULL;

CREATE INDEX idx_check_ins_recipe_id ON public.check_ins (recipe_id);
