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

`--no-verify-jwt` permite Database Webhooks (service role no header). A function ainda valida `Authorization: Bearer <SERVICE_ROLE>` ou `x-webhook-secret`.

Veja `FCM_SETUP.md` na raiz do repositório.
