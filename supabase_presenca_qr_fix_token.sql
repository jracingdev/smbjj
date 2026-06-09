-- CORREÇÃO: gen_random_bytes não existe sem pgcrypto
-- Execute este script no SQL Editor do Supabase e tente o QR de novo.

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

select 'Função criar_token_presenca corrigida!' as status;
