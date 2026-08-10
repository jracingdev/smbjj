-- ============================================================
-- CT SM BJJ — Alternativa 100% SQL aos Database Webhooks
-- Dispara Edge Function notify-admin em INSERT de alunos/pedidos
-- via pg_net (sem schema supabase_functions / sem UI de Webhooks).
--
-- POR QUE ISTO EXISTE
-- A UI Database Webhooks falha com:
--   ERROR: 3F000: schema "supabase_functions" does not exist
-- Isso é um bug/limitação do Dashboard (ele assume um schema interno
-- que nem sempre existe no projeto). NÃO invente esse schema —
-- use este arquivo com pg_net.
--
-- COMO RODAR (SQL Editor do projeto zhjnxspunbtyqhlyliuw)
-- 1) Settings → API → copie a service_role (Reveal). NÃO use anon.
-- 2) Rode APENAS no Editor (nunca commitе a chave) o PASSO A abaixo,
--    colando a service_role no lugar do placeholder.
-- 3) Rode o restante deste arquivo (PASSO B + triggers).
-- 4) Teste com INSERT em alunos ou pedidos (ou cadastro/pedido no app).
-- 5) Opcional: SELECT * FROM net._http_response ORDER BY created DESC LIMIT 5;
-- ============================================================

-- ------------------------------------------------------------
-- PASSO A — Guardar service_role no Vault (UMA vez, só no Editor)
-- Substitua YOUR_SERVICE_ROLE_KEY pela chave real e execute.
-- NÃO commitе este select com a chave preenchida.
-- ------------------------------------------------------------
-- select vault.create_secret(
--   'YOUR_SERVICE_ROLE_KEY',
--   'notify_admin_service_role',
--   'Bearer para trigger pg_net -> Edge Function notify-admin'
-- );
--
-- Se o secret já existir e você precisar trocar a chave:
-- select vault.update_secret(
--   (select id from vault.secrets where name = 'notify_admin_service_role' limit 1),
--   'YOUR_SERVICE_ROLE_KEY',
--   'notify_admin_service_role',
--   'Bearer para trigger pg_net -> Edge Function notify-admin'
-- );

-- ------------------------------------------------------------
-- PASSO B — Extensão + função + triggers (seguro para commit)
-- ------------------------------------------------------------

-- pg_net cria o schema "net" (http_post assíncrono, ideal em triggers).
-- Em alguns projetos a extensão já está em "extensions"; IF NOT EXISTS cobre ambos.
create extension if not exists pg_net;

create or replace function public.notify_admin_via_edge()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  service_key text;
  payload jsonb;
  req_id bigint;
begin
  select trim(ds.decrypted_secret)
    into service_key
  from vault.decrypted_secrets ds
  where ds.name = 'notify_admin_service_role'
  limit 1;

  if service_key is null or service_key = '' then
    raise warning
      'notify_admin_via_edge: secret vault "notify_admin_service_role" ausente — pulando HTTP. Rode o PASSO A do supabase_notify_admin_triggers.sql';
    return NEW;
  end if;

  -- Formato Database Webhook que parseWebhookOrManual() em notify-admin espera
  payload := jsonb_build_object(
    'type', TG_OP,
    'table', TG_TABLE_NAME,
    'schema', TG_TABLE_SCHEMA,
    'record', to_jsonb(NEW),
    'old_record', null
  );

  select net.http_post(
    url := 'https://zhjnxspunbtyqhlyliuw.supabase.co/functions/v1/notify-admin',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || service_key,
      'apikey', service_key
    ),
    body := payload,
    timeout_milliseconds := 5000
  ) into req_id;

  return NEW;
exception
  when others then
    -- Nunca derruba o INSERT do aluno/pedido por falha de notificação
    raise warning 'notify_admin_via_edge: %', SQLERRM;
    return NEW;
end;
$$;

comment on function public.notify_admin_via_edge() is
  'AFTER INSERT em alunos/pedidos: POST assíncrono (pg_net) para Edge Function notify-admin. Auth via Vault secret notify_admin_service_role.';

drop trigger if exists trg_notify_admin_aluno on public.alunos;
create trigger trg_notify_admin_aluno
  after insert on public.alunos
  for each row
  execute function public.notify_admin_via_edge();

drop trigger if exists trg_notify_admin_pedido on public.pedidos;
create trigger trg_notify_admin_pedido
  after insert on public.pedidos
  for each row
  execute function public.notify_admin_via_edge();

select 'notify_admin triggers OK — confirme Vault secret notify_admin_service_role (PASSO A)' as status;
