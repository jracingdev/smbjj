# Play Store — Reset da upload key (Opção B)

Este guia cobre o fluxo quando o **keystore de upload local** não corresponde ao certificado registrado na Play Console, e só existem certificados públicos (`.der`) sem a chave privada (`.jks`).

## Contexto (diagnóstico)

| Artefato | SHA-1 | Papel |
|---|---|---|
| Play espera (upload) | `DB:6E:9F:E9:B9:E5:C4:36:6F:46:D0:F2:B3:38:E8:19:F0:C2:2D:04` | Certificado de upload registrado |
| `upload_cert.der` (baixado da Play) | `DB:6E:...` (igual ao acima) | **Só certificado público** — não assina AAB |
| Keystore local atual (`upload-keystore.jks`) | `D3:98:12:B7:02:8C:60:9F:3B:BF:78:2B:3E:0B:E8:1A:86:CC:0E:5E` | Não bate com a Play |
| `deployment_cert.der` | `F6:64:AA:3A:59:C9:CC:67:16:05:3E:7A:12:8E:75:E8:C7:9D:F7:ED` | App signing key da Google (Play App Signing) — **não** é upload key |

**Importante:** arquivos `.der` / `.pem` exportados pela Play são certificados **públicos**. Sem o `.jks` (ou `.p12`) que contém a chave privada correspondente ao SHA-1 `DB:6E:...`, não é possível assinar um AAB aceito pela Play. Por isso a Opção B (reset da upload key).

Não há `.jks` recuperável em `d:\chaves privadas\smbjj\` com o fingerprint antigo.

## Arquivos gerados (fora do git)

Local seguro (não versionar):

| Arquivo | Uso |
|---|---|
| `d:\chaves privadas\smbjj\upload-keystore-NEW.jks` | Novo keystore de upload |
| `d:\chaves privadas\smbjj\upload_certificate_NEW.pem` | Enviar no pedido de reset na Play |
| `d:\chaves privadas\smbjj\upload_certificate_NEW.der` | Cópia pública do novo cert |
| `d:\chaves privadas\smbjj\upload-keystore-NEW.credentials.txt` | Senhas (anotar em gerenciador de senhas) |
| `d:\chaves privadas\smbjj\key.properties.NEW` | Modelo de `android/key.properties` **após** aprovação |

Fingerprint do **novo** certificado de upload (após reset, a Play deve passar a esperar este):

- SHA-1: `27:EF:AB:43:0F:CB:72:49:A0:24:A0:64:E9:61:DD:E1:FA:0B:3F:A0`
- Alias: `upload`

---

## AGORA (antes da aprovação da Google)

1. Abra [Google Play Console](https://play.google.com/console) → app **SMBJJ** (ou nome do app).
2. Vá em **Testar e lançar** → **Integridade do app** (App integrity) → seção **Assinatura do app** / **Upload key certificate**.
3. Escolha **Solicitar redefinição da chave de upload** (*Request upload key reset*).
4. Anexe / envie o arquivo:
   - `d:\chaves privadas\smbjj\upload_certificate_NEW.pem`
5. Informe o motivo (ex.: perda do keystore de upload antigo; certificado público `DB:6E:...` sem chave privada).
6. Envie o pedido e **aguarde a aprovação** (pode levar alguns dias; a Google envia e-mail).
7. **Não** substitua ainda `android/upload-keystore.jks` nem `android/key.properties` no fluxo de release — builds assinados com o keystore novo serão rejeitados até o reset valer.
8. Guarde backup do JKS + senhas fora do PC (cofre / gerenciador de senhas). O arquivo de credenciais está em:
   - `d:\chaves privadas\smbjj\upload-keystore-NEW.credentials.txt`

## DEPOIS da aprovação da Google

1. Confirme na Play Console que o certificado de upload passou a mostrar SHA-1  
   `27:EF:AB:43:0F:CB:72:49:A0:24:A0:64:E9:61:DD:E1:FA:0B:3F:A0`.
2. Copie o novo keystore para o projeto:
   ```powershell
   Copy-Item -LiteralPath "d:\chaves privadas\smbjj\upload-keystore-NEW.jks" `
     -Destination "D:\smbjj\android\upload-keystore.jks" -Force
   ```
3. Atualize `android/key.properties` com o conteúdo de  
   `d:\chaves privadas\smbjj\key.properties.NEW`  
   (esses arquivos já estão no `.gitignore` do Android — não commitar).
4. Gere o AAB:
   ```powershell
   cd D:\smbjj
   flutter build appbundle --release
   ```
5. Faça upload do AAB na Play Console (teste interno / produção conforme o fluxo).
6. Confirme que a Play aceita a assinatura (sem erro de certificado de upload).

## O que NÃO fazer

- Não commitar `.jks`, `.pem`, `.der` de chave, nem `key.properties` / arquivos de senha.
- Não usar `deployment_cert.der` como upload key (é a chave da Google para App Signing).
- Não esperar que `upload_cert.der` antigo assine o AAB — falta a chave privada `DB:6E:...`.
- Não fazer force push nem versionar backups de chave no repositório.

## Referência rápida — ordem correta

```
[AGORA]  Gerar novo JKS + exportar PEM  →  já feito
[AGORA]  Pedir reset na Play com upload_certificate_NEW.pem
[ESPERAR] Aprovação Google
[DEPOIS] Copiar JKS → android/upload-keystore.jks
[DEPOIS] Aplicar key.properties.NEW → android/key.properties
[DEPOIS] flutter build appbundle --release → upload na Play
```
