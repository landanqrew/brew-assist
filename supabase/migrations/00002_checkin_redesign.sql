-- Coffees: add tasting_notes and image_url
ALTER TABLE public.coffees ADD COLUMN tasting_notes text;
ALTER TABLE public.coffees ADD COLUMN image_url text;

-- Check-ins: add venue_type and specialty_drink
ALTER TABLE public.check_ins ADD COLUMN venue_type text
  CHECK (venue_type IN ('home', 'cafe', 'other'));
ALTER TABLE public.check_ins ADD COLUMN specialty_drink text;

CREATE INDEX idx_check_ins_venue_type ON public.check_ins (venue_type);
