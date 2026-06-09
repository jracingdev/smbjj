-- Campos: data de início nas aulas (mês/ano) e flag iniciante (pro-rata)
alter table public.alunos add column if not exists data_inicio_aulas text;
alter table public.alunos add column if not exists iniciante boolean default false;
