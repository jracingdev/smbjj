-- Regras extras de cobrança (JSON) — execute após supabase_financeiro.sql
alter table public.financeiro_config
  add column if not exists regras_extras jsonb not null default '[]'::jsonb;

select 'Coluna regras_extras aplicada!' as status;
