-- DESIGN HER commerce expansion. Run in Supabase SQL Editor after reviewing.
create table if not exists public.store_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id)
);
alter table public.store_settings enable row level security;
drop policy if exists "Public can read published store settings" on public.store_settings;
create policy "Public can read published store settings" on public.store_settings for select using (key in ('storefront','branding','shipping','seo'));
drop policy if exists "Admins manage store settings" on public.store_settings;
create policy "Admins manage store settings" on public.store_settings for all using (public.is_store_admin()) with check (public.is_store_admin());

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  description text,
  image_url text,
  sort_order int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
alter table public.categories enable row level security;
drop policy if exists "Public read active categories" on public.categories;
create policy "Public read active categories" on public.categories for select using (is_active = true);
drop policy if exists "Admins manage categories" on public.categories;
create policy "Admins manage categories" on public.categories for all using (public.is_store_admin()) with check (public.is_store_admin());

create table if not exists public.coupons (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  discount_type text not null check (discount_type in ('percentage','fixed')),
  discount_value numeric(10,2) not null check (discount_value > 0),
  minimum_order numeric(10,2) not null default 0,
  max_uses int,
  used_count int not null default 0,
  starts_at timestamptz,
  expires_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
alter table public.coupons enable row level security;
drop policy if exists "Admins manage coupons" on public.coupons;
create policy "Admins manage coupons" on public.coupons for all using (public.is_store_admin()) with check (public.is_store_admin());

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  user_id uuid references auth.users(id),
  customer_name text not null,
  customer_email text not null,
  customer_phone text,
  shipping_address jsonb not null default '{}'::jsonb,
  subtotal numeric(10,2) not null default 0,
  discount numeric(10,2) not null default 0,
  shipping_fee numeric(10,2) not null default 0,
  total numeric(10,2) not null default 0,
  payment_status text not null default 'pending',
  order_status text not null default 'placed',
  notes text,
  created_at timestamptz not null default now()
);
alter table public.orders enable row level security;
drop policy if exists "Admins manage orders" on public.orders;
create policy "Admins manage orders" on public.orders for all using (public.is_store_admin()) with check (public.is_store_admin());
drop policy if exists "Customers read own orders" on public.orders;
create policy "Customers read own orders" on public.orders for select using (auth.uid() = user_id);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  quantity int not null check (quantity > 0),
  unit_price numeric(10,2) not null,
  selected_options jsonb not null default '{}'::jsonb
);
alter table public.order_items enable row level security;
drop policy if exists "Admins manage order items" on public.order_items;
create policy "Admins manage order items" on public.order_items for all using (public.is_store_admin()) with check (public.is_store_admin());

create table if not exists public.banners (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subtitle text,
  image_url text,
  link_url text,
  placement text not null default 'home-hero',
  sort_order int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
alter table public.banners enable row level security;
drop policy if exists "Public read active banners" on public.banners;
create policy "Public read active banners" on public.banners for select using (is_active = true);
drop policy if exists "Admins manage banners" on public.banners;
create policy "Admins manage banners" on public.banners for all using (public.is_store_admin()) with check (public.is_store_admin());
