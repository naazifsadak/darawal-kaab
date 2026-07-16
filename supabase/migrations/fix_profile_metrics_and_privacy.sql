-- Backfill counts for existing data
UPDATE public.profiles p
SET 
  posts_count = (SELECT count(*) FROM public.posts WHERE author_id = p.id),
  followers_count = (SELECT count(*) FROM public.follows WHERE following_id = p.id),
  following_count = (SELECT count(*) FROM public.follows WHERE follower_id = p.id);

-- Add hide_followers_following column to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS hide_followers_following boolean DEFAULT false;
