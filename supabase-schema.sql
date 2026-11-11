-- Pedidos de documentos · Moreira Oliveira Advocacia
-- Acesso só para e-mails da tabela "autorizados" (login por link no e-mail).

create table if not exists public.autorizados (
  email text primary key,
  nome  text
);

create or replace function public.is_autorizado()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.autorizados
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

create table if not exists public.pedidos (
  id          uuid primary key default gen_random_uuid(),
  criado_em   timestamptz not null default now(),
  criado_por  uuid default auth.uid(),
  solicitante text default (auth.jwt() ->> 'email'),
  cliente     text not null,
  modelo      text,
  status      text not null default 'Novo',
  entrega     date,
  dados       jsonb not null default '{}'::jsonb
);

create table if not exists public.anexos (
  id           uuid primary key default gen_random_uuid(),
  pedido_id    uuid not null references public.pedidos(id) on delete cascade,
  criado_em    timestamptz not null default now(),
  nome         text not null,
  tipo         text,
  tamanho      bigint,
  texto        text,
  truncado     boolean default false,
  storage_path text
);

create index if not exists pedidos_criado_em_idx on public.pedidos (criado_em desc);
create index if not exists anexos_pedido_idx on public.anexos (pedido_id);

alter table public.autorizados enable row level security;
alter table public.pedidos     enable row level security;
alter table public.anexos      enable row level security;

drop policy if exists "autorizados leem a lista" on public.autorizados;
create policy "autorizados leem a lista" on public.autorizados
  for select to authenticated using (public.is_autorizado());

drop policy if exists "autorizados usam pedidos" on public.pedidos;
create policy "autorizados usam pedidos" on public.pedidos
  for all to authenticated using (public.is_autorizado()) with check (public.is_autorizado());

drop policy if exists "autorizados usam anexos" on public.anexos;
create policy "autorizados usam anexos" on public.anexos
  for all to authenticated using (public.is_autorizado()) with check (public.is_autorizado());

-- Arquivos: anexos dos pedidos e documentos da galeria (privados)
insert into storage.buckets (id, name, public)
values ('anexos', 'anexos', false), ('galeria', 'galeria', false)
on conflict (id) do nothing;

drop policy if exists "autorizados leem arquivos" on storage.objects;
create policy "autorizados leem arquivos" on storage.objects
  for select to authenticated
  using (bucket_id in ('anexos', 'galeria') and public.is_autorizado());

drop policy if exists "autorizados enviam anexos" on storage.objects;
create policy "autorizados enviam anexos" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'anexos' and public.is_autorizado());

drop policy if exists "autorizados apagam anexos" on storage.objects;
create policy "autorizados apagam anexos" on storage.objects
  for delete to authenticated
  using (bucket_id = 'anexos' and public.is_autorizado());
