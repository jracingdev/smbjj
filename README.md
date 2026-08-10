# CT SM BJJ

App Flutter de gestão da academia SM BJJ, com backend [Supabase](https://zhjnxspunbtyqhlyliuw.supabase.co).

Repositório: https://github.com/jracingdev/smbjj.git

## Configuração Supabase

1. Execute `supabase_setup.sql` no SQL Editor do projeto.
2. Execute `supabase_turmas.sql` (turmas e vínculo aluno ↔ turma).
3. Opcional: `supabase_pedidos.sql` para a loja.
4. Crie o usuário admin em **Authentication → Users** (`admin@smbj.com`).

Credenciais do app estão em `lib/core/supabase_service.dart` (chave publishable — uso client-side com RLS).

## Versão atual

**1.7.27** (build 58) — push FCM para admin (novo aluno / novo pedido) com app morto; ver [FCM_SETUP.md](FCM_SETUP.md).

## Push FCM (admin)

Para notificações com o app fechado, siga o checklist em **[FCM_SETUP.md](FCM_SETUP.md)** (`google-services.json`, SQL `supabase_admin_fcm.sql`, secrets e Edge Function `notify-admin`).

## Executar

```bash
flutter pub get
flutter run
```

## Instalar no celular

```bash
flutter build apk --release
flutter install
```
