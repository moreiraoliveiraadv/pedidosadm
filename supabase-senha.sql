-- Acesso por e-mail e senha: só e-mails @moreiraoliveira.adv.br.
-- Rode depois do supabase-schema.sql.

-- 1. Quem pode ver e enviar pedidos: qualquer e-mail do domínio
create or replace function public.is_autorizado()
returns boolean
language sql
stable
as $$
  select lower(coalesce(auth.jwt() ->> 'email', '')) like '%@moreiraoliveira.adv.br';
$$;

-- 2. Bloqueia criação de conta com e-mail de fora do domínio
drop trigger if exists so_autorizados on auth.users;
drop function if exists public.bloquear_nao_autorizados();

create or replace function public.bloquear_fora_do_dominio()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if lower(new.email) not like '%@moreiraoliveira.adv.br' then
    raise exception 'dominio nao permitido';
  end if;
  return new;
end;
$$;

drop trigger if exists so_dominio on auth.users;
create trigger so_dominio
  before insert on auth.users
  for each row execute function public.bloquear_fora_do_dominio();

-- 3. Remove contas de teste com e-mail de fora do domínio
delete from auth.users
where lower(email) not like '%@moreiraoliveira.adv.br';
