-- Só e-mails da tabela "autorizados" conseguem criar senha.
create or replace function public.bloquear_nao_autorizados()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from public.autorizados where lower(email) = lower(new.email)) then
    raise exception 'email nao autorizado';
  end if;
  return new;
end;
$$;

drop trigger if exists so_autorizados on auth.users;
create trigger so_autorizados
  before insert on auth.users
  for each row execute function public.bloquear_nao_autorizados();

-- Remove contas criadas no teste com e-mails fora da lista
delete from auth.users u
where not exists (select 1 from public.autorizados a where lower(a.email) = lower(u.email));
