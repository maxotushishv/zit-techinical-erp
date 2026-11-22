-- TECHNICAL GROUP ERP — run once in Supabase SQL Editor.
-- IMPORTANT: Replace the email below with the EXACT email you created in Authentication > Users.
-- Never place a service_role / secret key in the frontend.

create table if not exists public.erp_admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);
revoke all on public.erp_admins from anon, authenticated;

insert into public.erp_admins(user_id)
select id from auth.users where lower(email) = lower('matu@sartichala2.ge')
on conflict do nothing;

create or replace function public.is_erp_admin()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.erp_admins where user_id = (select auth.uid())); $$;
revoke all on function public.is_erp_admin() from public;
grant execute on function public.is_erp_admin() to authenticated;

create table if not exists public.products (
 id uuid primary key default gen_random_uuid(),
 name text not null, sku text, category text not null default 'სხვა',
 cost_price numeric(14,2) not null default 0 check(cost_price>=0),
 sale_price numeric(14,2) not null default 0 check(sale_price>=0),
 stock_qty numeric(14,2) not null default 0,
 unit text not null default 'ც', warranty_months integer not null default 0,
 created_at timestamptz not null default now()
);
create table if not exists public.customers (
 id uuid primary key default gen_random_uuid(),
 name text not null, phone text, email text, address text, tax_id text,
 created_at timestamptz not null default now()
);
create table if not exists public.documents (
 id uuid primary key default gen_random_uuid(),
 number text not null unique, type text not null check(type in ('quote','invoice')),
 customer_id uuid references public.customers(id) on delete restrict,
 status text not null default 'draft' check(status in ('draft','sent','accepted','paid','cancelled')),
 items jsonb not null default '[]'::jsonb check(jsonb_typeof(items)='array'),
 subtotal numeric(14,2) not null default 0,
 discount numeric(14,2) not null default 0,
 total numeric(14,2) not null default 0,
 notes text not null default '',
 created_at timestamptz not null default now()
);

alter table public.products enable row level security;
alter table public.customers enable row level security;
alter table public.documents enable row level security;
alter table public.erp_admins enable row level security;

drop policy if exists "admin products" on public.products;
drop policy if exists "admin customers" on public.customers;
drop policy if exists "admin documents" on public.documents;
create policy "admin products" on public.products for all to authenticated using ((select public.is_erp_admin())) with check ((select public.is_erp_admin()));
create policy "admin customers" on public.customers for all to authenticated using ((select public.is_erp_admin())) with check ((select public.is_erp_admin()));
create policy "admin documents" on public.documents for all to authenticated using ((select public.is_erp_admin())) with check ((select public.is_erp_admin()));

-- Verify the result: the next query should return exactly one row.
select a.user_id, u.email from public.erp_admins a join auth.users u on u.id=a.user_id;
