-- 1. Add parent_id to comments for replies
alter table public.comments add column if not exists parent_id bigint references public.comments(id) on delete cascade;

-- 2. Add Update and Delete Policies to Comments
alter table public.comments enable row level security;

drop policy if exists "Authenticated users can update own comments" on comments;
drop policy if exists "Authenticated users can delete own comments" on comments;

create policy "Authenticated users can update own comments" on comments for update using ( auth.uid() = author_id );
create policy "Authenticated users can delete own comments" on comments for delete using ( auth.uid() = author_id );
