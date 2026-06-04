# Auditoria CT SM BJJ — App + Web (Supabase)

**Projeto:** `https://github.com/jracingdev/smbjj`  
**Backend:** `https://zhjnxspunbtyqhlyliuw.supabase.co`  
**Web:** `https://jracingdev.github.io/smbjj/`  
**Versão alvo atual:** **1.2.4** (build 9)

---

## 1. Versões (por que você via 1.1.0 / 1.1.2)

| Onde | O que acontecia | O que fazer |
|------|-----------------|-------------|
| **APK no celular** | Instalação antiga ou cache do ícone/atalho | Desinstalar → instalar APK **1.2.4**; conferir **Perfil → Sobre** |
| **Web GitHub Pages** | Branch `gh-pages` só atualiza após `flutter build web` + push | Ctrl+F5; versão em `version.json` na gh-pages |
| **Código `master`** | Pode estar à frente do que está no aparelho | `git pull` + novo build |

---

## 2. Cadastros “aguardando validação” sem botão Validar

### Causa (falha de UX)
- Aluno no auto-cadastro é salvo com **`ativo: false`** e **`cadastro_validado: false`**.
- A aba **Alunos** abria com filtro **“Ativos”** → pendentes **não apareciam**.
- O painel **Início** contava todos os não validados, mas não levava à lista.

### Correção (v1.2.4)
- Ao abrir Alunos, se houver pendentes, filtro vai para **“Pendentes”**.
- Banner amarelo **clicável** (Início e Alunos) → aba Alunos + filtro Pendentes.
- Em cada card: botão **Validar** → `ValidarAlunoScreen` (faixa, grau, turmas).

### Como validar (admin)
1. Login `admin@smbj.com`
2. **Início** → toque no alerta amarelo **ou** **Alunos** (já em Pendentes)
3. **Validar** no aluno → confirmar dados, faixa, turmas → salvar

---

## 3. Loja — fotos não salvam / não aparecem

### Causas
| # | Problema |
|---|----------|
| 1 | Produtos antigos com `foto_url` = **caminho local** do celular (inválido em outro aparelho/web) |
| 2 | Upload falha se bucket **`fotos`** ou políticas RLS não existirem no Supabase |
| 3 | **Web:** picker local **não faz upload** (limitação; usar app Android ou URL http) |

### Correção app (v1.2.4)
- Upload com `upsert` + `contentType` no Storage.
- Aviso ao admin: “X produto(s) com foto antiga — edite e salve de novo”.

### O que você deve fazer no Supabase (SQL Editor)
Executar (se ainda não rodou):
1. `supabase_setup.sql` — tabelas + bucket `fotos` + políticas
2. Trecho novo de **Update autenticado** no storage (no final do setup)

### Re-cadastrar fotos
Para cada produto sem imagem: **Loja → Editar → escolher foto → Salvar** (logado como admin).

---

## 4. Checklist Supabase (obrigatório para 100%)

- [ ] `supabase_setup.sql`
- [ ] `supabase_turmas.sql`
- [ ] `supabase_auth_fix.sql` (só `admin@smbj.com` como admin)
- [ ] `supabase_pedidos.sql` (se usar pedidos)
- [ ] Auth: usuário **admin@smbj.com**
- [ ] Auth → URL: redirect `io.supabase.flutter://callback` (Google Android)
- [ ] Storage → bucket **fotos** público + políticas insert/update autenticado

---

## 5. Funcionalidades por área

### Login / Auth
| Item | App | Web | Notas |
|------|-----|-----|-------|
| Email/senha | OK | OK | |
| Google OAuth | OK Android | OK | Redirect no painel Supabase |
| Esqueci senha | OK | OK | E-mail com link Supabase |
| Biometria | OK Android | N/A | Após 1º login com senha |
| Role admin segura | OK | OK | Rodar `supabase_auth_fix.sql` |

### Aluno
| Item | Status |
|------|--------|
| Primeiro acesso → formulário | OK |
| Data **DD-MM-AAAA** | OK (ISO no banco) |
| Aguardar validação (banner) | OK |
| Ver faixa/turma após admin validar | OK |
| Faixa ilustrada | OK após validação |

### Admin
| Item | Status |
|------|--------|
| Validar cadastro + turmas | OK (v1.2.4 navegação) |
| Turmas / dias da semana | OK |
| Financeiro / mensalidades | OK |
| Loja / produtos | OK após re-upload fotos |
| Pedidos loja | Requer `supabase_pedidos.sql` |

### Web (GitHub Pages)
| Item | Status |
|------|--------|
| Mesmo código após deploy gh-pages | Depende do deploy |
| Upload foto produto local | **Limitado** — usar URL ou app mobile |
| PWA / cache | Limpar com Ctrl+F5 |

---

## 6. Falhas “bobas” já corrigidas ou conhecidas

1. **Pendentes invisíveis** — filtro Ativos (corrigido v1.2.4)
2. **Versão desatualizada no celular** — reinstalar APK
3. **Foto produto path local** — re-salvar produto; aviso no admin
4. **README desatualizado** — atualizar para 1.2.4
5. **Web atrás do app** — republicar `gh-pages` após cada release

---

## 7. Deploy rápido (referência)

```bash
# Android
flutter build apk --release
adb uninstall com.smbijj.ct_sm_bjj
flutter install -d <device_id>

# Web
flutter build web --release --base-href "/smbjj/"
# copiar build/web para branch gh-pages e push
```

---

*Última atualização desta auditoria: release 1.2.4*
