# mp-webhook — Edge Function

Recebe notificações de pagamento do Mercado Pago e marca mensalidades como pagas automaticamente.

## Deploy

```bash
# Na pasta raiz do projeto Flutter (onde está a pasta supabase/)
npx supabase functions deploy mp-webhook --project-ref zhjnxspunbtyqhlyliuw
```

## Como funciona

1. O Mercado Pago envia um POST para `https://zhjnxspunbtyqhlyliuw.supabase.co/functions/v1/mp-webhook`
2. A função busca o `mp_access_token` salvo em `financeiro_config`
3. Consulta os detalhes do pagamento na API do MP
4. Se `status == approved`, marca a mensalidade com esse `mp_preferencia_id` como paga

## Configurar no Mercado Pago

1. Acesse https://www.mercadopago.com.br/developers/panel/app
2. Selecione seu app → Webhooks
3. Adicione a URL: `https://zhjnxspunbtyqhlyliuw.supabase.co/functions/v1/mp-webhook`
4. Evento: Pagamentos
