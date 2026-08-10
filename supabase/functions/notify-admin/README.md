# notify-admin

Envia push FCM (HTTP v1) para tokens em `admin_fcm_tokens` quando há novo aluno ou pedido.

## Secrets

```bash
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat caminho/service-account.json)"
# opcional
supabase secrets set FCM_WEBHOOK_SECRET="um-segredo-forte"
```

## Deploy

```bash
supabase functions deploy notify-admin --no-verify-jwt
```

`--no-verify-jwt` permite Database Webhooks (service role no header). A function ainda valida:

1. Match exact com `SUPABASE_SERVICE_ROLE_KEY` / `SUPABASE_SECRET_KEYS`
2. JWT com `role=service_role` + `ref` do projeto (aceito mesmo sem `SUPABASE_JWT_SECRET`; tradeoff documentado no código — uso interno/webhooks)
3. HMAC HS256 se `SUPABASE_JWT_SECRET` ou `JWT_SECRET` estiver setado como secret
4. `x-webhook-secret` se configurado

O debug 401 / GET inclui `codeVersion` (ex.: `v3`) para confirmar qual build está no ar.

Veja `FCM_SETUP.md` na raiz do repositório.
