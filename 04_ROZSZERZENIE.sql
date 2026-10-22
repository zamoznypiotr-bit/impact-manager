-- Uruchom po migracji 1.2, w Supabase SQL Editor (PostgreSQL).
begin;
alter table public.orders add column if not exists description text;
alter table public.orders add column if not exists installation_address text;
alter table public.orders add column if not exists measurement_date date;
alter table public.orders add column if not exists installation_date date;
create table if not exists public.impact_order_notes (
 id uuid primary key default gen_random_uuid(),
 order_id uuid not null references public.orders(id) on delete cascade,
 body text not null check (length(body) between 1 and 5000),
 author_id uuid not null default auth.uid() references auth.users(id),
 created_at timestamptz not null default now()
);
create table if not exists public.impact_order_history (
 id bigint generated always as identity primary key,
 order_id uuid not null references public.orders(id) on delete cascade,
 actor_id uuid,
 action text not null,
 created_at timestamptz not null default now()
);
alter table public.impact_order_notes enable row level security;
alter table public.impact_order_history enable row level security;
revoke all on public.impact_order_notes, public.impact_order_history from anon;
grant select,insert on public.impact_order_notes to authenticated;
grant select on public.impact_order_history to authenticated;
drop policy if exists "IMPACT notes read" on public.impact_order_notes;
create policy "IMPACT notes read" on public.impact_order_notes for select to authenticated
using ((select public.impact_has_role(array['admin','office','production','installer'])));
drop policy if exists "IMPACT notes add" on public.impact_order_notes;
create policy "IMPACT notes add" on public.impact_order_notes for insert to authenticated
with check (author_id = (select auth.uid()) and (select public.impact_has_role(array['admin','office','production','installer'])));
drop policy if exists "IMPACT history read" on public.impact_order_history;
create policy "IMPACT history read" on public.impact_order_history for select to authenticated
using ((select public.impact_has_role(array['admin','office','production','installer'])));
-- Produkcja nie może zmieniać pól klienta i terminów, nawet wywołując API bez interfejsu.
create or replace function public.impact_guard_order_update()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
 if public.impact_has_role(array['production']) and not public.impact_has_role(array['admin','office']) then
   if (old.client,old.project,old.deadline,old.owner,old.order_number,old.created_by,old.description,old.installation_address,old.measurement_date,old.installation_date)
      is distinct from
      (new.client,new.project,new.deadline,new.owner,new.order_number,new.created_by,new.description,new.installation_address,new.measurement_date,new.installation_date) then
     raise exception 'Produkcja może zmieniać wyłącznie status zamówienia';
   end if;
 end if;
 if old.created_by is distinct from new.created_by then
   raise exception 'Nie można zmienić autora zamówienia';
 end if;
 return new;
end $$;
drop trigger if exists impact_guard_order_update on public.orders;
create trigger impact_guard_order_update before update on public.orders
for each row execute function public.impact_guard_order_update();
create or replace function public.impact_log_order_change()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
 insert into public.impact_order_history(order_id,actor_id,action)
 values(new.id,auth.uid(),case when tg_op='INSERT' then 'Utworzono zamówienie' else 'Zmieniono zamówienie' end);
 return new;
end $$;
drop trigger if exists impact_log_order_change on public.orders;
create trigger impact_log_order_change after insert or update on public.orders
for each row execute function public.impact_log_order_change();
commit;
