-- Promote the newly created DESIGN HER store owner account to admin.
-- Run this once in Supabase SQL Editor for the DESIGN HER Gift Store project.
insert into public.profiles (id, role)
values ('b7b6c8d4-3007-4fe6-9f02-97d43c6a9c51'::uuid, 'admin')
on conflict (id) do update set role = excluded.role;
