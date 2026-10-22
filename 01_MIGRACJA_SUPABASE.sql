-- IMPACT Manager 1.2: uruchom JEDEN RAZ w SQL Editor jako właściciel projektu.
-- Zalogowany użytkownik musi już istnieć w Authentication > Users.
begin;
create table if not exists public.impact_members (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('admin','office','production','installer')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);
alter table public.impact_members enable row level security;
revoke all on public.impact_members from anon;
grant select on public.impact_members to authenticated;
drop policy if exists "Odczyt swojego czlonkostwa" on public.impact_members;
create policy "Odczyt swojego czlonkostwa" on public.impact_members
 for select to authenticated using (user_id = (select auth.uid()));
-- Funkcja sprawdza rolę po stronie bazy, nie ufa roli podanej przez przeglądarkę.
create or replace function public.impact_has_role(allowed text[])
returns boolean language sql stable security definer set search_path = ''
as $$ select exists (
 select 1 from public.impact_members m
 where m.user_id = (select auth.uid()) and m.active and m.role = any(allowed)
) $$;
revoke all on function public.impact_has_role(text[]) from public, anon;
grant execute on function public.impact_has_role(text[]) to authenticated;
-- Zastępujemy poprzednie polityki "tylko własne" politykami firmowymi.
drop policy if exists "Odczyt wlasnych zamowien" on public.orders;
drop policy if exists "Dodawanie wlasnych zamowien" on public.orders;
drop policy if exists "Edycja wlasnych zamowien" on public.orders;
drop policy if exists "Usuwanie wlasnych zamowien" on public.orders;
drop policy if exists "IMPACT odczyt" on public.orders;
drop policy if exists "IMPACT dodawanie" on public.orders;
drop policy if exists "IMPACT edycja" on public.orders;
drop policy if exists "IMPACT usuwanie" on public.orders;
alter table public.orders enable row level security;
revoke all on public.orders from anon;
grant select, insert, update, delete on public.orders to authenticated;
create policy "IMPACT odczyt" on public.orders for select to authenticated
 using ((select public.impact_has_role(array['admin','office','production','installer'])));
create policy "IMPACT dodawanie" on public.orders for insert to authenticated
 with check ((select public.impact_has_role(array['admin','office'])) and created_by = (select auth.uid()));
create policy "IMPACT edycja" on public.orders for update to authenticated
 using ((select public.impact_has_role(array['admin','office','production'])))
 with check ((select public.impact_has_role(array['admin','office','production'])));
create policy "IMPACT usuwanie" on public.orders for delete to authenticated
 using ((select public.impact_has_role(array['admin'])));
-- Produkcja może zmieniać wiersze, nie tylko status. Nie przechowuj tu finansów ani danych wrażliwych.
commit;

-- WAŻNE: po migracji wykonaj OSOBNO 02_PIERWSZY_ADMIN.sql
-- Dopóki nie przypiszesz admina, żadne konto nie zobaczy zamówień.
