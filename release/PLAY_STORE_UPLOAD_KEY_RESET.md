# Play Store — Reset da upload key (Opção B) — PRONTO

**Status (2026-08-10):** reset **aprovado** pela Google. Nova upload key válida a partir de **12/08/2026 17:43 UTC**.  
**Não enviar o AAB à Play antes dessa data/hora.**

## AAB pronto (nova chave)

| Campo | Valor |
|---|---|
| Arquivo | `D:\smbjj\release\smbjj-1.7.31-62-api36-NEWKEY.aab` |
| Versão | **1.7.31** (versionCode **62**) |
| Tamanho | ~69,5 MB |
| SHA1 da assinatura (upload) | `27:EF:AB:43:0F:CB:72:49:A0:24:A0:64:E9:61:DD:E1:FA:0B:3F:A0` |
| Alias | `upload` |
| CN | `CN=CT SM BJJ Academia, OU=JRacing Dev, O=JRacing Dev, L=Rio de Janeiro, ST=RJ, C=BR` |

Liberação Play (nova chave aceita): **após 12/08/2026 17:43 UTC**.

## Backups / arquivos (fora do git)

| Arquivo | Uso |
|---|---|
| `d:\chaves privadas\smbjj\upload-keystore-NEW.jks` | Novo keystore de upload (fonte) |
| `d:\chaves privadas\smbjj\upload-keystore-OLD-D398.jks` | Backup do keystore antigo (SHA1 `D3:98:...`) |
| `d:\chaves privadas\smbjj\key.properties.OLD` | Backup do `key.properties` antigo |
| `d:\chaves privadas\smbjj\key.properties.NEW` | Modelo (sem BOM; `storeFile=upload-keystore.jks`) |
| `d:\chaves privadas\smbjj\upload_certificate_NEW.pem` | PEM enviado no reset |
| `d:\chaves privadas\smbjj\upload-keystore-NEW.credentials.txt` | Senhas (cofre) |

No projeto (gitignore):

- `android/upload-keystore.jks` ← cópia do NEW
- `android/key.properties` ← a partir do NEW (UTF-8 **sem BOM**)

## Contexto histórico

| Artefato | SHA-1 | Papel |
|---|---|---|
| Play (upload antiga) | `DB:6E:9F:E9:B9:E5:C4:36:6F:46:D0:F2:B3:38:E8:19:F0:C2:2D:04` | Upload key perdida |
| Keystore local antigo | `D3:98:12:B7:02:8C:60:9F:3B:BF:78:2B:3E:0B:E8:1A:86:CC:0E:5E` | Backup `…-OLD-D398.jks` |
| **Nova upload key (atual)** | `27:EF:AB:43:0F:CB:72:49:A0:24:A0:64:E9:61:DD:E1:FA:0B:3F:A0` | Em uso no AAB NEWKEY |
| `deployment_cert.der` | `F6:64:AA:3A:59:C9:CC:67:16:05:3E:7A:12:8E:75:E8:C7:9D:F7:ED` | App signing key Google |

## Checklist de upload (só depois de 12/08/2026 17:43 UTC)

1. [ ] Confirmar na Play Console o certificado de upload SHA-1 `27:EF:...`
2. [ ] Enviar `release\smbjj-1.7.31-62-api36-NEWKEY.aab` (teste interno / produção)
3. [ ] Colar What's new (abaixo / `PLAY_STORE_1.7.31.md`)
4. [ ] Confirmar versionName **1.7.31** / versionCode **62** e aceite da assinatura

## What's new — PT-BR (curta)

```
Novidades nesta versão:
• Notificações push para administradores (FCM)
• Cobrança de mensalidades pelo WhatsApp em lote
• Histórico de graduações dos alunos
• Destaque BLACK BELT LEGACY no app
• Início mais limpo, sem a seção de Alunos
• Melhorias na permissão de notificações
```

## What's new — PT-BR (completa)

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

## O que NÃO fazer

- Não fazer upload do AAB **antes** de **12/08/2026 17:43 UTC**.
- Não commitar `.jks`, `key.properties`, senhas, AAB/APK.
- Não reutilizar o keystore `D3:98:...` / `DB:6E:...` para novos uploads.
- Não fazer force push nem versionar backups de chave no repositório.

## Referência rápida

```
[FEITO] Gerar novo JKS + PEM + pedir reset
[FEITO] Reset aprovado (válido a partir de 12/08/2026 17:43 UTC)
[FEITO] Copiar JKS NEW → android/upload-keystore.jks
[FEITO] Aplicar key.properties (sem BOM)
[FEITO] flutter build appbundle --release → smbjj-1.7.31-62-api36-NEWKEY.aab
[FEITO] SHA1 AAB = 27:EF:...
[AGUARDAR] 12/08/2026 17:43 UTC
[DEPOIS] Upload na Play Console
```