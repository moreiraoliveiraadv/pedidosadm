insert into public.autorizados (email, nome) values
  ('laraalmeida@moreiraoliveira.adv.br', 'Lara'),
  ('marcoantonio@moreiraoliveira.adv.br', 'Marco')
on conflict (email) do update set nome = excluded.nome;
