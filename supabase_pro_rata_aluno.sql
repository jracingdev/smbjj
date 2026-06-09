-- Preferência de pro-rata no primeiro mês por aluno (validação)
alter table public.alunos add column if not exists pro_rata_primeiro_mes boolean default true;
