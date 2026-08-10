# Play Store — CT SM BJJ 1.7.31 (62)

Data de preparação: 2026-08-10  
Package: `com.smbijj.ct_sm_bjj`  
targetSdk / compileSdk: **36**

## Artefatos (locais — não versionados)

| Tipo | Caminho | Tamanho aprox. |
|------|---------|----------------|
| **AAB (Play)** | `D:\smbjj\release\smbjj-1.7.31-62-api36.aab` | ~69,5 MB |
| APK (sideload) | `D:\smbjj\release\smbjj-1.7.31-62-api36.apk` | ~77,8 MB |

Fonte do build Flutter:
- AAB: `build\app\outputs\bundle\release\app-release.aab`
- APK: `build\app\outputs\flutter-apk\app-release.apk`

> `release/*.aab` e a pasta `/release/` estão no `.gitignore`. Os binários ficam só na máquina local.

## Versão

| Campo | Valor |
|-------|-------|
| versionName | **1.7.31** |
| versionCode | **62** |
| pubspec | `1.7.31+62` |

Sem bump: a versão já estava adequada para esta subida.

## Assinatura

- `android/key.properties` + `android/upload-keystore.jks` presentes
- `android/app/build.gradle.kts`: `buildTypes.release` usa `signingConfigs.release` quando `key.properties` existe
- Certificado verificado no APK/AAB: **CN=CT SM BJJ, OU=Mobile, O=SM BJJ** (upload key — **não** debug)

### Lembrete crítico

Use **sempre o mesmo upload keystore**. **Não** gere um keystore novo nem troque o alias `upload` sem o fluxo oficial do Play Console (App signing / reset de upload key).

---

## Problema: mismatch de upload key (2026-08-10)

O upload do AAB `smbjj-1.7.31-62-api36.aab` foi **rejeitado** pela Play Store por assinatura diferente da upload key registrada.

| | SHA1 |
|--|------|
| **Esperado pela Play** (upload key registrada) | `DB:6E:9F:E9:B9:E5:C4:36:6F:46:D0:F2:B3:38:E8:19:F0:C2:2D:04` |
| **Usado no AAB / keystore local atual** | `D3:98:12:B7:02:8C:60:9F:3B:BF:78:2B:3E:0B:E8:1A:86:CC:0E:5E` |

### Diagnóstico (máquina atual)

| Campo | Valor |
|-------|-------|
| Keystore | `android/upload-keystore.jks` |
| Alias | `upload` |
| CN | `CN=CT SM BJJ, OU=Mobile, O=SM BJJ, L=Brasil, ST=BR, C=BR` |
| SHA1 | `D3:98:12:B7:02:8C:60:9F:3B:BF:78:2B:3E:0B:E8:1A:86:CC:0E:5E` |
| SHA256 | `F3:5A:88:1E:78:45:D4:B3:B9:AE:E3:90:E5:36:C4:AB:50:6B:4B:0D:22:2B:9B:12:D2:31:5B:9B:16:E1:D0:C0` |
| Criação local | 23/07/2026 |

- O AAB rejeitado confirma o mesmo SHA1 (`D3:98:...`) em `META-INF/UPLOAD.RSA`.
- `release/upload_certificate.pem` também é **D3:98:...** (exportado deste keystore local em 23/07/2026) — **não** é a chave que a Play espera.
- Busca rápida (depth limitado) em `D:\smbjj`, Desktop/OneDrive, Documents, Downloads e outros `.jks` em `D:\`: **não** foi encontrado keystore com SHA1 `DB:6E:...`.
- Contexto: a **primeira publicação** foi em **outro computador**; a chave original (`DB:6E:...`) provavelmente ficou só lá (ou em backup externo).

**Conclusão:** o keystore atual é válido em si, mas **não** é o upload key registrado na Play. Não rebuildar/reenviar com `D3:98:...` até resolver A ou B. **Não** inventar/gerar keystore “substituto” sem o fluxo oficial.

### Opção A (ideal) — recuperar o upload keystore original

1. No PC antigo / pendrive / e-mail / Google Drive / cofre de senhas, localizar o `.jks` / `.keystore` usado na **primeira** publicação (upload key).
2. Confirmar o fingerprint **sem expor senhas**:
   ```bash
   keytool -list -v -keystore CAMINHO\do\keystore.jks -alias ALIAS
   ```
   O SHA1 deve ser exatamente `DB:6E:9F:E9:B9:E5:C4:36:6F:46:D0:F2:B3:38:E8:19:F0:C2:2D:04`.
3. Copiar esse arquivo para `android/upload-keystore.jks` (substituir o atual — guardar o atual como backup renomeado, ex.: `upload-keystore.D398-LOCAL-BACKUP.jks`, **fora do git**).
4. Ajustar `android/key.properties` (`storeFile`, `keyAlias`, senhas) para esse keystore — **não** commitar.
5. Rebuild:
   ```bash
   flutter build appbundle --release
   ```
6. Verificar o AAB:
   ```bash
   # extrair META-INF/*.RSA do .aab e:
   keytool -printcert -file UPLOAD.RSA
   ```
   SHA1 deve ser `DB:6E:...`.
7. Copiar para `release/` com nome claro, ex.: `smbjj-1.7.31-62-api36-uploadkey-DB6E.aab`, e reenviar na Play Console.

### Opção B — reset da upload key no Play Console

Usar se o keystore `DB:6E:...` estiver **irrecuperável**.

1. Play Console → app **CT SM BJJ** → **Setup** / **App integrity** (Integridade do app) → **App signing** → **Request upload key reset** (solicitar redefinição da chave de upload).
2. Gerar um **novo** keystore de upload (ex.: novo `upload-keystore.jks`, alias `upload`) e exportar o certificado PEM:
   ```bash
   keytool -genkeypair -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   keytool -export -rfc -keystore android/upload-keystore.jks -alias upload -file release/upload_certificate_NEW.pem
   ```
3. Enviar o PEM à Google no pedido de reset e **aguardar aprovação** (pode levar dias).
4. Atualizar `android/key.properties` para o novo keystore; guardar backup seguro do `.jks` + senhas (fora do git).
5. Só depois da aprovação: rebuild AAB, conferir SHA1 do novo cert, upload na Play.

> Enquanto o reset não for aprovado, AABs assinados com a chave nova (ou com `D3:98:...`) continuarão rejeitados.

### Status desta sessão

- [x] SHA1 local confirmado = `D3:98:...` (mismatch com a Play)
- [x] Keystore correto `DB:6E:...` **não** localizado neste PC
- [ ] AAB com chave certa **não** gerado (bloqueado até Opção A ou B)
- [ ] Upload Play pendente da correção de assinatura

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

1. [ ] Abrir [Play Console](https://play.google.com/console) → app **CT SM BJJ**
2. [ ] Preferível: **Teste interno** / closed testing primeiro; depois **Produção**
3. [ ] Criar release → enviar **`smbjj-1.7.31-62-api36.aab`**
4. [ ] Confirmar **versionName 1.7.31** / **versionCode 62** e que o Play aceitou a assinatura (mesmo upload key)
5. [ ] Colar o texto **What's new** (PT-BR; EN se o listing tiver locale EN)
6. [ ] Revisar declarações de permissão / Data safety se o Console pedir (notificações / FCM)
7. [ ] Salvar → revisar → enviar para revisão / publicar no track escolhido
8. [ ] **Não** fazer upload automático sem credenciais explícitas nesta sessão

## SQL / backend pendentes (se ainda não rodados no Supabase)

Antes ou junto do rollout, confirme no SQL Editor do projeto:

1. **`supabase_graduacoes.sql`** — tabela/histórico de graduações + RLS  
2. **`supabase_notify_admin_triggers.sql`** — triggers FCM/notify-admin (PASSO A Vault + PASSO B)  
3. **`supabase_admin_fcm.sql`** — tokens FCM de admin, se aplicável  

Sem esses scripts, partes da release (histórico / push) podem falhar em produção mesmo com o AAB correto.

## Notas internas

- Build: `flutter build appbundle --release` (Flutter em `C:\src\flutter\bin`)
- APK release gerado só para sideload/QA local; **Play Store = AAB**
- Não commitar keystore, `key.properties`, senhas ou AAB/APK
