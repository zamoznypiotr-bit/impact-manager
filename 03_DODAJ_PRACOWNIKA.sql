-- Najpierw utwórz pracownika: Supabase > Authentication > Users > Add user.
-- Następnie zastąp e-mail i rolę poniżej i uruchom w SQL Editor.
-- Role: office / production / installer. Nie przyznawaj admin bez potrzeby.
insert into public.impact_members (user_id, role, active)
select id, 'production', true from auth.users
where lower(email) = lower('EMAIL_PRACOWNIKA')
on conflict (user_id) do update set role=excluded.role, active=true;
-- Aby zablokować dostęp: update public.impact_members set active=false where user_id=(select id from auth.users where email='EMAIL_PRACOWNIKA');
