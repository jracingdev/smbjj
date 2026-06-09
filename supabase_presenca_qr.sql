-- ============================================================
-- CT SM BJJ — Presença por QR Code
-- Execute após supabase_presencas.sql e supabase_rls_fix_v2.sql
-- (usa gen_random_uuid — não requer extensão pgcrypto)
-- ============================================================

-- Configuração global (singleton): método escolhido pelo professor
create table if not exists public.presenca_config (
  id int primary key default 1 check (id = 1),
  metodo text not null default 'chamada'
    check (metodo in ('chamada', 'qr_turma', 'qr_unico')),
  token_validade_minutos int not null default 30,
  updated_at timestamptz default now()
);

insert into public.presenca_config (id) values (1)
on conflict (id) do nothing;

alter table public.presenca_config enable row level security;

drop policy if exists "Admin gerencia presenca_config" on public.presenca_config;
drop policy if exists "Todos leem presenca_config" on public.presenca_config;

create policy "Admin gerencia presenca_config" on public.presenca_config
  for all using (public.is_admin());
create policy "Todos leem presenca_config" on public.presenca_config
  for select using (true);

-- Tokens ativos para QR (por turma ou único)
create table if not exists public.presenca_tokens (
  id uuid default gen_random_uuid() primary key,
  token text not null unique,
  tipo text not null check (tipo in ('turma', 'unico')),
  turma_id uuid references public.turmas(id) on delete cascade,
  data_aula text not null,
  valido_ate timestamptz not null,
  ativo boolean not null default true,
  created_at timestamptz default now()
);

create index if not exists idx_presenca_tokens_token on public.presenca_tokens (token) where ativo = true;

alter table public.presenca_tokens enable row level security;

drop policy if exists "Admin gerencia presenca_tokens" on public.presenca_tokens;
create policy "Admin gerencia presenca_tokens" on public.presenca_tokens
  for all using (public.is_admin());

-- Coluna opcional: origem do registro
alter table public.presencas add column if not exists origem text default 'chamada';

-- Permite aluno registrar própria presença via RPC (não insert direto)
drop policy if exists "Aluno registra propria presenca qr" on public.presencas;
create policy "Aluno registra propria presenca qr" on public.presencas for insert
  with check (aluno_id = public.meu_aluno_id());

-- ── Função: turma do aluno para QR único (dia da semana) ─────
create or replace function public.turma_checkin_aluno(p_aluno_id uuid, p_data date default current_date)
returns uuid
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_turma uuid;
  v_dow int;
begin
  v_dow := extract(dow from p_data)::int;

  select at.turma_id into v_turma
  from public.aluno_turmas at
  join public.turmas t on t.id = at.turma_id and t.ativa = true
  where at.aluno_id = p_aluno_id
    and (
      t.dias_semana is null
      or cardinality(t.dias_semana) = 0
      or v_dow::text = any(t.dias_semana)
    )
  order by t.nome
  limit 1;

  if v_turma is null then
    select at.turma_id into v_turma
    from public.aluno_turmas at
    join public.turmas t on t.id = at.turma_id and t.ativa = true
    where at.aluno_id = p_aluno_id
    order by t.nome
    limit 1;
  end if;

  return v_turma;
end;
$$;

-- ── Admin: criar/renovar token QR ───────────────────────────
create or replace function public.criar_token_presenca(
  p_tipo text,
  p_turma_id uuid default null
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cfg record;
  v_token text;
  v_data text;
  v_valido timestamptz;
begin
  if not public.is_admin() then
    raise exception 'Apenas administradores podem gerar QR de presença.';
  end if;

  if p_tipo not in ('turma', 'unico') then
    raise exception 'Tipo de token inválido.';
  end if;

  if p_tipo = 'turma' and p_turma_id is null then
    raise exception 'Informe a turma para QR por turma.';
  end if;

  select * into v_cfg from public.presenca_config where id = 1;
  v_data := to_char(current_date, 'YYYY-MM-DD');
  v_token := replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', '');
  v_valido := now() + make_interval(mins => coalesce(v_cfg.token_validade_minutos, 30));

  update public.presenca_tokens set ativo = false where ativo = true
    and tipo = p_tipo
    and ((p_tipo = 'turma' and turma_id = p_turma_id) or p_tipo = 'unico');

  insert into public.presenca_tokens (token, tipo, turma_id, data_aula, valido_ate)
  values (v_token, p_tipo, p_turma_id, v_data, v_valido);

  return json_build_object(
    'token', v_token,
    'tipo', p_tipo,
    'turma_id', p_turma_id,
    'data_aula', v_data,
    'valido_ate', v_valido
  );
end;
$$;

-- ── Aluno: registrar presença via QR ────────────────────────
create or replace function public.registrar_presenca_checkin(p_token text)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tok record;
  v_aluno_id uuid;
  v_aluno_nome text;
  v_validado boolean;
  v_turma_id uuid;
  v_turma_nome text;
begin
  v_aluno_id := public.meu_aluno_id();
  if v_aluno_id is null then
    raise exception 'Cadastro de aluno não encontrado.';
  end if;

  select nome, cadastro_validado into v_aluno_nome, v_validado
  from public.alunos where id = v_aluno_id;

  if not coalesce(v_validado, false) then
    raise exception 'Seu cadastro ainda não foi validado pelo professor.';
  end if;

  select * into v_tok from public.presenca_tokens
  where token = p_token and ativo = true and valido_ate > now()
  limit 1;

  if v_tok is null then
    raise exception 'QR inválido ou expirado. Peça ao professor para gerar um novo.';
  end if;

  if v_tok.tipo = 'turma' then
    v_turma_id := v_tok.turma_id;
    if not exists (
      select 1 from public.aluno_turmas
      where aluno_id = v_aluno_id and turma_id = v_turma_id
    ) then
      raise exception 'Você não está matriculado nesta turma.';
    end if;
  else
    v_turma_id := public.turma_checkin_aluno(v_aluno_id, v_tok.data_aula::date);
    if v_turma_id is null then
      raise exception 'Você não está em nenhuma turma ativa.';
    end if;
  end if;

  select nome into v_turma_nome from public.turmas where id = v_turma_id;

  insert into public.presencas (turma_id, aluno_id, aluno_nome, data_aula, presente, origem)
  values (v_turma_id, v_aluno_id, v_aluno_nome, v_tok.data_aula, true, 'qr')
  on conflict (turma_id, aluno_id, data_aula)
  do update set presente = true, origem = 'qr', aluno_nome = excluded.aluno_nome;

  return json_build_object(
    'ok', true,
    'turma_nome', v_turma_nome,
    'data_aula', v_tok.data_aula,
    'aluno_nome', v_aluno_nome
  );
end;
$$;

revoke all on function public.criar_token_presenca(text, uuid) from public;
revoke all on function public.registrar_presenca_checkin(text) from public;
grant execute on function public.criar_token_presenca(text, uuid) to authenticated;
grant execute on function public.registrar_presenca_checkin(text) to authenticated;

select 'Presença QR configurada!' as status;
