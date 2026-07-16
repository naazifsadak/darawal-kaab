-- Add image_url column to app_banners table if it doesn't exist
ALTER TABLE public.app_banners ADD COLUMN IF NOT EXISTS image_url text;
