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

**1.2.4** (build 9) — cadastro aluno, validação admin, turmas, biometria, loja com Storage, datas DD-MM-AAAA.

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
