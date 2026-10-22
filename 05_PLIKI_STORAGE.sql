-- IMPACT Manager 2.1: uruchom w SQL Editor PostgreSQL po migracjach 1.2 i 2.0.
-- Prywatny bucket. Limit 10 MB i typy plikow kontrolowane takze na serwerze.
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('impact-order-files','impact-order-files',false,10485760,array['application/pdf','image/jpeg','image/png','image/webp'])
on conflict (id) do update set public=false,file_size_limit=10485760,allowed_mime_types=excluded.allowed_mime_types;
create table if not exists public.impact_order_files (
 id uuid primary key default gen_random_uuid(),
 order_id uuid not null references public.orders(id) on delete cascade,
 storage_path text not null unique,
 file_name text not null check (length(file_name) between 1 and 255),
 mime_type text not null check (mime_type in ('application/pdf','image/jpeg','image/png','image/webp')),
 file_size bigint not null check (file_size between 1 and 10485760),
 uploaded_by uuid not null references auth.users(id),
 created_at timestamptz not null default now(),
 constraint file_path_matches_order check (split_part(storage_path,'/',1)=order_id::text)
);
alter table public.impact_order_files enable row level security;
revoke all on public.impact_order_files from anon;
grant select,insert,delete on public.impact_order_files to authenticated;
drop policy if exists "IMPACT files select" on public.impact_order_files;
create policy "IMPACT files select" on public.impact_order_files for select to authenticated
using ((select public.impact_has_role(array['admin','office','production','installer'])));
drop policy if exists "IMPACT files insert" on public.impact_order_files;
create policy "IMPACT files insert" on public.impact_order_files for insert to authenticated
with check (uploaded_by=(select auth.uid()) and (select public.impact_has_role(array['admin','office','production','installer'])));
drop policy if exists "IMPACT files delete" on public.impact_order_files;
create policy "IMPACT files delete" on public.impact_order_files for delete to authenticated
using ((select public.impact_has_role(array['admin','office'])));
-- Sciezki w Storage: <UUID zamowienia>/<UUID pliku>.<rozszerzenie>.
-- Sprawdzamy, czy zamowienie istnieje, a uzytkownik jest aktywnym czlonkiem zespolu.
drop policy if exists "IMPACT storage read" on storage.objects;
create policy "IMPACT storage read" on storage.objects for select to authenticated
using (bucket_id='impact-order-files' and (select public.impact_has_role(array['admin','office','production','installer']))
 and exists (select 1 from public.orders o where o.id::text=split_part(name,'/',1)));
drop policy if exists "IMPACT storage upload" on storage.objects;
create policy "IMPACT storage upload" on storage.objects for insert to authenticated
with check (bucket_id='impact-order-files' and (select public.impact_has_role(array['admin','office','production','installer']))
 and exists (select 1 from public.orders o where o.id::text=split_part(name,'/',1))
 and name ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.(pdf|jpg|png|webp)$');
drop policy if exists "IMPACT storage delete" on storage.objects;
create policy "IMPACT storage delete" on storage.objects for delete to authenticated
using (bucket_id='impact-order-files' and (select public.impact_has_role(array['admin','office'])));
