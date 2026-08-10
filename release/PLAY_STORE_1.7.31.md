# Play Store — CT SM BJJ 1.7.31 (62)

Data de preparação: 2026-08-10  
Package: `com.smbijj.ct_sm_bjj`  
targetSdk / compileSdk: **36**

## Status upload key (2026-08-10)

- Reset da upload key **aprovado** na Play.
- Nova chave válida a partir de **12/08/2026 17:43 UTC**.
- **AAB com a nova chave já gerado** — **só enviar após** essa data/hora.
- Detalhes do reset: `release/PLAY_STORE_UPLOAD_KEY_RESET.md`

## Artefatos (locais — não versionados)

| Tipo | Caminho | Tamanho aprox. |
|------|---------|----------------|
| **AAB (Play) — NOVA CHAVE** | `D:\smbjj\release\smbjj-1.7.31-62-api36-NEWKEY.aab` | ~69,5 MB |
| AAB antigo (chave errada D3:98) | `D:\smbjj\release\smbjj-1.7.31-62-api36.aab` | ~69,5 MB — **não usar** |
| APK (sideload) | `D:\smbjj\release\smbjj-1.7.31-62-api36.apk` | ~77,8 MB |

Fonte do build Flutter:

- AAB: `build\app\outputs\bundle\release\app-release.aab`

> `release/*.aab` e a pasta `/release/` estão no `.gitignore`. Os binários ficam só na máquina local.

## Versão

| Campo | Valor |
|-------|-------|
| versionName | **1.7.31** |
| versionCode | **62** |
| pubspec | `1.7.31+62` |

## Assinatura (confirmada no AAB NEWKEY)

| Campo | Valor |
|-------|-------|
| Keystore | `android/upload-keystore.jks` (cópia do NEW) |
| Alias | `upload` |
| CN | `CN=CT SM BJJ Academia, OU=JRacing Dev, O=JRacing Dev, L=Rio de Janeiro, ST=RJ, C=BR` |
| **SHA1** | `27:EF:AB:43:0F:CB:72:49:A0:24:A0:64:E9:61:DD:E1:FA:0B:3F:A0` |
| SHA256 | `A2:1B:1F:71:2C:9B:B2:6E:A7:86:63:64:08:01:6D:66:AC:82:33:2D:16:19:8B:80:6F:0B:04:9C:1A:DE:6F:F8` |

Backups fora do git: `d:\chaves privadas\smbjj\upload-keystore-OLD-D398.jks` + `key.properties.OLD`.

> Nota: `key.properties` deve estar em UTF-8 **sem BOM** (BOM quebra o Gradle: cast null em `storePassword`).

---

## Título / nome da release (sugestão)

**1.7.31 (62) — Graduações, Legacy e notificações**

## What's new — PT-BR (colar no Play Console)

### Curta (~280 caracteres)

```
Novidades nesta versão:
• Notificações push para administradores (FCM)
• Cobrança de mensalidades pelo WhatsApp em lote
• Histórico de graduações dos alunos
• Destaque BLACK BELT LEGACY no app
• Início mais limpo, sem a seção de Alunos
• Melhorias na permissão de notificações
```

### Mais completa (~480 caracteres)

```
Atualização CT SM BJJ:

• Push FCM para admins (avisos importantes mesmo com o app em segundo plano)
• Cobrança WhatsApp em lote para mensalidades em atraso
• Histórico de graduações (registro e consulta de faixas/graus)
• Seção BLACK BELT LEGACY em destaque
• Remoção da listagem de Alunos na tela Início (navegação mais direta)
• Fluxo de permissão de notificações mais claro no Android

Obrigado por treinar e usar o app da academia.
```

## What's new — EN (opcional, curto)

```
What's new:
• Admin push notifications (FCM)
• Bulk WhatsApp payment reminders
• Graduation history
• BLACK BELT LEGACY highlight
• Cleaner Home (Alunos section removed)
• Better notification permission flow
```

## Checklist de upload (Play Console)

1. [ ] **Esperar** até **12/08/2026 17:43 UTC** (nova upload key válida)
2. [ ] Abrir [Play Console](https://play.google.com/console) → app **CT SM BJJ**
3. [ ] Preferível: **Teste interno** / closed testing primeiro; depois **Produção**
4. [ ] Criar release → enviar **`smbjj-1.7.31-62-api36-NEWKEY.aab`**
5. [ ] Confirmar **versionName 1.7.31** / **versionCode 62** e aceite da assinatura (SHA1 `27:EF:...`)
6. [ ] Colar o texto **What's new** (PT-BR; EN se o listing tiver locale EN)
7. [ ] Revisar declarações de permissão / Data safety se o Console pedir (notificações / FCM)
8. [ ] Salvar → revisar → enviar para revisão / publicar no track escolhido

## SQL / backend pendentes (se ainda não rodados no Supabase)

1. **`supabase_graduacoes.sql`** — tabela/histórico de graduações + RLS  
2. **`supabase_notify_admin_triggers.sql`** — triggers FCM/notify-admin  
3. **`supabase_admin_fcm.sql`** — tokens FCM de admin, se aplicável  

## Notas internas

- Build: `flutter build appbundle --release` (Flutter em `C:\src\flutter\bin`)
- Play Store = **AAB** assinado com a nova upload key
- Não commitar keystore, `key.properties`, senhas ou AAB/APK