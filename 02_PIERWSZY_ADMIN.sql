-- Zamień adres na DOKŁADNY e-mail swojego konta w Authentication > Users.
-- Uruchom w SQL Editor (nie w aplikacji). Nie wysyłaj nam adresu ani hasła.
insert into public.impact_members (user_id, role, active)
select id, 'admin', true from auth.users
where lower(email) = lower('WPISZ_TUTAJ_SWOJ_EMAIL')
on conflict (user_id) do update set role='admin', active=true;
-- Wynik powinien zwrócić 1. Jeśli 0, sprawdź adres e-mail.
select count(*) as liczba_adminow
from public.impact_members where role='admin' and active;
