# Push FCM para admin (CT SM BJJ)

Push sonora/visual (logo + canal `smbjj_admin_alerts`) quando:

1. um **novo aluno** é inserido em `public.alunos`
2. um **novo pedido** é inserido em `public.pedidos`

Funciona com o app **fechado/morto**. Os alertas in-app + polling locais continuam ativos.

Versão do app com cliente FCM: **1.7.27+58**.

---

## 1) Firebase Console (Android)

1. Crie/use um projeto em [Firebase Console](https://console.firebase.google.com/).
2. **Add app → Android**
   - Package name **exato**: `com.smbijj.ct_sm_bjj`
3. Baixe `google-services.json`.
4. Coloque em:

```
android/app/google-services.json
```

5. (Opcional) Em Project settings → Cloud Messaging, confirme que a API FCM está ativa.

Sem esse arquivo o app **compila e roda**; o FCM só fica desligado (log: `Firebase indisponível`).

---

## 2) Service account (servidor — NÃO vai no git)

1. Firebase Console → Project settings → **Service accounts**
2. **Generate new private key** → JSON
3. Guarde fora do repositório (ex.: gerenciador de senhas / secrets do Supabase)
4. Nunca commitе `*firebase-adminsdk*.json`

---

## 3) Supabase SQL

No SQL Editor, execute:

```
supabase_admin_fcm.sql
```

Cria `public.admin_fcm_tokens` + RLS (só o próprio admin gerencia o token).

---

## 4) Secrets da Edge Function

No projeto Supabase (CLI ou Dashboard → Edge Functions → Secrets):

| Secret | Valor |
|--------|--------|
| `FIREBASE_SERVICE_ACCOUNT` | Conteúdo **inteiro** do JSON da service account (uma linha / string JSON) |
| `FCM_WEBHOOK_SECRET` | (opcional) segredo compartilhado com o webhook |

CLI:

```bash
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat /caminho/seguro/service-account.json)"
supabase secrets set FCM_WEBHOOK_SECRET="troque-por-um-segredo-forte"
```

`SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY` já existem no runtime das functions.

---

## 5) Deploy da function

Project ref: `zhjnxspunbtyqhlyliuw`  
URL:

```
https://zhjnxspunbtyqhlyliuw.supabase.co/functions/v1/notify-admin
```

### Via CLI (recomendado)

1. Crie um Access Token em [Account → Access Tokens](https://supabase.com/dashboard/account/tokens)
2. No PowerShell:

```powershell
$env:SUPABASE_ACCESS_TOKEN = "sbp_..."   # não commitar
cd D:\smbjj
npx supabase functions deploy notify-admin --project-ref zhjnxspunbtyqhlyliuw --no-verify-jwt
```

Ou use o script (deploy + smoke test). Ordem obrigatoria:

```powershell
cd D:\smbjj
$env:SUPABASE_ACCESS_TOKEN = "sbp_..."           # obrigatorio (Account > Access Tokens)
$env:SUPABASE_SERVICE_ROLE_KEY = "..."           # opcional, so para POST de teste
powershell -ExecutionPolicy Bypass -File scripts\fcm_deploy_test.ps1
```

O script valida as env vars no inicio e falha com mensagem clara se `SUPABASE_ACCESS_TOKEN` faltar.

`config.toml` já define `verify_jwt = false` para `notify-admin`. A flag `--no-verify-jwt` reforça isso. A function ainda valida `Authorization: Bearer <SERVICE_ROLE_KEY>` (ou `apikey` / `x-webhook-secret`).

**401 no POST de teste:** quase sempre é auth (não “0 tokens”). Causas comuns: (1) `Invoke-RestMethod` no Windows PowerShell 5.1 omitindo o header `Authorization` — o script usa `curl.exe` no POST; (2) chave errada (anon em vez de `service_role` / `sb_secret`); (3) deploy sem `--no-verify-jwt`. Com auth ok e 0 tokens, a function responde **200** com `reason: nenhum token FCM`.

### Via Dashboard (se não houver CLI/token)

1. [Edge Functions](https://supabase.com/dashboard/project/zhjnxspunbtyqhlyliuw/functions) → **Deploy a new function**
2. Nome: `notify-admin`
3. Cole o código de `supabase/functions/notify-admin/index.ts`
4. Desative **Verify JWT** / habilite invocação com service role
5. Confirme o secret `FIREBASE_SERVICE_ACCOUNT` em Edge Functions → Secrets

---

## 6) Disparar notify-admin no INSERT (recomendado: SQL / pg_net)

### Se a UI de Webhooks falhar com `supabase_functions`

Erro típico ao salvar no Dashboard:

```text
ERROR: 3F000: schema "supabase_functions" does not exist
```

A UI de Database Webhooks assume um schema interno (`supabase_functions`) que **não existe** em vários projetos. Não tente “criar esse schema na mão” — use a alternativa abaixo com **pg_net + triggers SQL** (mesmo destino HTTP da Edge Function).

### Alternativa 100% SQL (use esta)

Arquivo: `supabase_notify_admin_triggers.sql`

1. Abra o [SQL Editor](https://supabase.com/dashboard/project/zhjnxspunbtyqhlyliuw/sql/new).
2. Em **Settings → API**, Reveal da `service_role` (nunca a anon).
3. No Editor, rode o **PASSO A** do SQL (bloco comentado no topo): descomente o `vault.create_secret(...)`, cole a service_role no lugar de `YOUR_SERVICE_ROLE_KEY` e execute **só essa linha**.  
   A chave fica no **Vault** do projeto — **não** vai no git.
4. Cole/rode o restante do arquivo (extensão `pg_net`, função `notify_admin_via_edge`, triggers `AFTER INSERT` em `public.alunos` e `public.pedidos`).
5. Teste: cadastre um aluno ou faça um pedido; opcionalmente inspecione respostas:

```sql
select id, status_code, error_msg, content
from net._http_response
order by created desc
limit 5;
```

O body enviado replica o formato Database Webhook (`type`, `table`, `schema`, `record`) que `notify-admin` já entende.

### Opcional: Database Webhooks (Dashboard)

Só se a UI funcionar no seu projeto. A Management API não cria o webhook HTTP completo com headers customizados de forma simples.

Abra [Database Webhooks](https://supabase.com/dashboard/project/zhjnxspunbtyqhlyliuw/integrations/webhooks/overview) (ou **Database → Webhooks**).

Crie **dois** webhooks idênticos, mudando só a tabela:

#### A) Novo aluno

1. **Create a new hook**
2. Name: `notify-admin-aluno`
3. Table: `public.alunos`
4. Events: **Insert** (só Insert)
5. Type: **HTTP Request**
6. Method: **POST**
7. URL: `https://zhjnxspunbtyqhlyliuw.supabase.co/functions/v1/notify-admin`
8. Headers:
   - `Content-Type` = `application/json`
   - `Authorization` = `Bearer <SERVICE_ROLE_KEY>`  
     (Settings → API → `service_role` → Reveal; não use a anon/publishable)
   - (opcional) `x-webhook-secret` = mesmo valor de `FCM_WEBHOOK_SECRET`
9. Salvar

#### B) Novo pedido

- Igual ao A, name `notify-admin-pedido`, table `public.pedidos`, event **Insert**

O body padrão do webhook já inclui `table`, `type`, `record` — a function monta título/mensagem.

**Não use Webhooks UI e triggers SQL ao mesmo tempo** (push duplicado). Prefira só o SQL se a UI falhar.

---

## 7) App admin

1. `flutter pub get`
2. Garanta `android/app/google-services.json`
3. Instale o APK / rode no aparelho
4. Faça **login como admin** (permite notificações no Android 13+)
5. Confirme linha em `admin_fcm_tokens` (Table Editor)

---

## 8) Como testar com app morto

1. Abra o app como admin uma vez (grava o token) e **force stop** / limpe da recente.
2. De outro aparelho/conta, cadastre um aluno **ou** faça um pedido na loja.
3. Deve chegar notificação do sistema (som + ícone `ic_stat_smbjj` / logo).
4. Toque na notificação → abre na aba **Alunos** ou **Loja**.

### Teste manual da function

```bash
curl -X POST "https://<PROJECT_REF>.supabase.co/functions/v1/notify-admin" \
  -H "Authorization: Bearer <SERVICE_ROLE_KEY>" \
  -H "Content-Type: application/json" \
  -d "{\"tipo\":\"teste\",\"titulo\":\"Teste FCM\",\"mensagem\":\"Push com app morto\"}"
```

---

## Troubleshooting

| Sintoma | Checagem |
|---------|----------|
| App roda sem push | `google-services.json` presente? Log `FcmService: Firebase Messaging pronto`? |
| Token não grava | Usuário é `role = admin`? SQL `supabase_admin_fcm.sql` aplicado? |
| UI Webhooks: `schema "supabase_functions" does not exist` | Ignore a UI; rode `supabase_notify_admin_triggers.sql` (seção 6) |
| Trigger SQL sem push | Vault secret `notify_admin_service_role` criado (PASSO A)? `net._http_response` com 401/erro? |
| Webhook / POST 401 | Header `Authorization: Bearer` com **service_role** (não anon); redeploy com `--no-verify-jwt`; no PS 5.1 preferir `curl.exe` ou o script `fcm_deploy_test.ps1` |
| POST 200 + `nenhum token FCM` | Auth ok — falta login admin no app (grava em `admin_fcm_tokens`) |
| Function 500 OAuth | JSON da service account completo (`project_id`, `client_email`, `private_key`) |
| Sem som | Canal `smbjj_admin_alerts` → importância Alta; som do sistema não silenciado |

---

## Arquivos do repositório

- `lib/core/notifications/fcm_service.dart` — cliente FCM
- `lib/core/notifications/local_notification_service.dart` — canal/ícone/som
- `supabase_admin_fcm.sql` — tabela de tokens
- `supabase_notify_admin_triggers.sql` — triggers pg_net → notify-admin (alternativa aos Webhooks UI)
- `supabase/functions/notify-admin/` — envio FCM HTTP v1
