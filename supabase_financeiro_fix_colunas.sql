-- Corrige financeiro_config quando a tabela existe sem regras_extras / pro_rata_ativo
-- Execute no Supabase → SQL Editor → Run

alter table public.financeiro_config
  add column if not exists regras_extras jsonb not null default '[]'::jsonb;

alter table public.financeiro_config
  add column if not exists pro_rata_ativo boolean default true;

update public.financeiro_config
set
  regras_extras = coalesce(regras_extras, '[]'::jsonb),
  pro_rata_ativo = coalesce(pro_rata_ativo, true)
where id = 1;

insert into public.financeiro_config (id, regras_extras, pro_rata_ativo)
values (1, '[]'::jsonb, true)
on conflict (id) do nothing;

select id, regras_extras, pro_rata_ativo, updated_at
from public.financeiro_config
where id = 1;
