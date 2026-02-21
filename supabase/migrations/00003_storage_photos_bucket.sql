-- Create a public storage bucket for user-uploaded photos.
INSERT INTO storage.buckets (id, name, public)
VALUES ('photos', 'photos', true);

-- Anyone can view photos (public bucket).
CREATE POLICY "Anyone can view photos"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'photos');

-- Authenticated users can upload photos.
CREATE POLICY "Authenticated users can upload photos"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'photos' AND auth.role() = 'authenticated');

-- Users can update their own uploads (path starts with their uid).
CREATE POLICY "Users can update own photos"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'photos' AND (storage.foldername(name))[1] = auth.uid()::text)
  WITH CHECK (bucket_id = 'photos' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Users can delete their own uploads.
CREATE POLICY "Users can delete own photos"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'photos' AND (storage.foldername(name))[1] = auth.uid()::text);
