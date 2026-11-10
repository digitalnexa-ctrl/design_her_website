-- DESIGN HER gift store: Supabase production schema
-- Run in Supabase SQL Editor only after creating the project.
-- SECURITY: never expose service_role keys in browser code.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'customer' check (role in ('customer','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  category text not null check (category in (
    'Personalised Gifts','Kids Books','Birthday Gifts','Anniversary Gifts',
    'Photo Frames','Gift Hampers','Corporate Gifts','Handmade Gifts'
  )),
  description text not null default '',
  price numeric(10,2) not null check (price >= 0),
  compare_at_price numeric(10,2) check (compare_at_price is null or compare_at_price >= price),
  image_url text,
  images jsonb not null default '[]'::jsonb,
  stock integer not null default 0 check (stock >= 0),
  sku text unique,
  is_active boolean not null default false,
  is_featured boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists products_active_category_idx
  on public.products (is_active, category);
create index if not exists products_featured_idx
  on public.products (is_featured) where is_active = true;

create or replace function public.is_store_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

alter table public.profiles enable row level security;
alter table public.products enable row level security;

drop policy if exists "Customers can read own profile" on public.profiles;
create policy "Customers can read own profile"
  on public.profiles for select
  using (id = auth.uid());

drop policy if exists "Public can read active products" on public.products;
create policy "Public can read active products"
  on public.products for select
  using (is_active = true);

drop policy if exists "Admins can read all products" on public.products;
create policy "Admins can read all products"
  on public.products for select
  using (public.is_store_admin());

drop policy if exists "Admins can insert products" on public.products;
create policy "Admins can insert products"
  on public.products for insert
  with check (public.is_store_admin());

drop policy if exists "Admins can update products" on public.products;
create policy "Admins can update products"
  on public.products for update
  using (public.is_store_admin())
  with check (public.is_store_admin());

drop policy if exists "Admins can delete products" on public.products;
create policy "Admins can delete products"
  on public.products for delete
  using (public.is_store_admin());

-- Create a public product-image bucket. Admin-only writes; public read.
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do update set public = true;

drop policy if exists "Public can view product images" on storage.objects;
create policy "Public can view product images"
  on storage.objects for select
  using (bucket_id = 'product-images');

drop policy if exists "Admins can upload product images" on storage.objects;
create policy "Admins can upload product images"
  on storage.objects for insert
  with check (bucket_id = 'product-images' and public.is_store_admin());

drop policy if exists "Admins can update product images" on storage.objects;
create policy "Admins can update product images"
  on storage.objects for update
  using (bucket_id = 'product-images' and public.is_store_admin())
  with check (bucket_id = 'product-images' and public.is_store_admin());

drop policy if exists "Admins can delete product images" on storage.objects;
create policy "Admins can delete product images"
  on storage.objects for delete
  using (bucket_id = 'product-images' and public.is_store_admin());

-- After creating the first admin account, promote its auth UUID manually:
-- insert into public.profiles (id, role) values ('AUTH_USER_UUID', 'admin')
-- on conflict (id) do update set role = 'admin';


-- Browser storefront read access: grants are required in addition to RLS policies.
grant usage on schema public to anon, authenticated;
grant select on table public.products to anon, authenticated;
alter table public.products enable row level security;
drop policy if exists "Public can read active products" on public.products;
create policy "Public can read active products"
  on public.products for select
  to anon, authenticated
  using (is_active = true);
