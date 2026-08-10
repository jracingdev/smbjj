# Teste E2E FCM admin (sem deploy).
#
# Conta tokens em admin_fcm_tokens, POST de teste em notify-admin,
# opcionalmente checa triggers/pg_net via supabase db, e ADB se houver device.
#
# Uso (PowerShell 5.1+):
#   cd D:\smbjj
#   $env:SUPABASE_SERVICE_ROLE_KEY = "<service_role Reveal>"
#   # opcional para SQL triggers:
#   $env:SUPABASE_ACCESS_TOKEN = "<PAT Account Access Tokens>"
#   powershell -ExecutionPolicy Bypass -File scripts\fcm_e2e_test.ps1
#
# Alternativa: coloque SUPABASE_SERVICE_ROLE_KEY=... em .env na raiz (gitignored).
# NAO cole secrets neste arquivo. NAO imprime chaves.

$ErrorActionPreference = 'Stop'
$ProjectRef = 'zhjnxspunbtyqhlyliuw'
$ExpectedCodeVersion = 'v3'
$PackageId = 'com.smbijj.ct_sm_bjj'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

function Import-DotEnvIfPresent {
  $envFile = Join-Path $Root '.env'
  if (-not (Test-Path $envFile)) { return }
  Write-Host '== Carregando .env (sem imprimir valores) =='
  foreach ($line in Get-Content $envFile) {
    $t = $line.Trim()
    if (-not $t -or $t.StartsWith('#')) { continue }
    $eq = $t.IndexOf('=')
    if ($eq -lt 1) { continue }
    $name = $t.Substring(0, $eq).Trim()
    $val = $t.Substring($eq + 1).Trim().Trim('"').Trim("'")
    if ($name -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') { continue }
    $existing = [Environment]::GetEnvironmentVariable($name, 'Process')
    if ([string]::IsNullOrWhiteSpace($existing)) {
      Set-Item -Path "Env:$name" -Value $val
    }
  }
}

function Get-JwtPayloadClaims {
  param([string]$Jwt)
  $parts = $Jwt.Split('.')
  if ($parts.Count -lt 2) { throw 'token nao e JWT (faltam partes)' }
  $payloadB64 = $parts[1].Replace('-', '+').Replace('_', '/')
  while ($payloadB64.Length % 4 -ne 0) { $payloadB64 += '=' }
  $payloadJson = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payloadB64))
  return ($payloadJson | ConvertFrom-Json)
}

function Find-Adb {
  $cmd = Get-Command adb.exe -ErrorAction SilentlyContinue
  if ($null -ne $cmd) { return $cmd.Source }
  $winget = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\Google.PlatformTools_Microsoft.Winget.Source_8wekyb3d8bbwe\platform-tools\adb.exe'
  if (Test-Path $winget) { return $winget }
  return $null
}

Import-DotEnvIfPresent

$srRaw = $env:SUPABASE_SERVICE_ROLE_KEY
if ([string]::IsNullOrWhiteSpace($srRaw)) {
  Write-Host ''
  Write-Host 'ERRO: SUPABASE_SERVICE_ROLE_KEY ausente.' -ForegroundColor Red
  Write-Host 'Rode UM comando (cole a service_role Reveal no lugar de <KEY>) e reexecute:' -ForegroundColor Yellow
  Write-Host ''
  Write-Host '  $env:SUPABASE_SERVICE_ROLE_KEY = "<KEY>"; powershell -ExecutionPolicy Bypass -File scripts\fcm_e2e_test.ps1'
  Write-Host ''
  Write-Host 'Fonte: Dashboard Supabase > Project Settings > API > service_role > Reveal (NAO use anon).'
  Write-Host 'Opcional: $env:SUPABASE_ACCESS_TOKEN = "<PAT>" para checar triggers via SQL.'
  exit 1
}

$sr = $srRaw.Trim().Trim('"').Trim("'")
$base = "https://$ProjectRef.supabase.co/functions/v1/notify-admin"
$rest = "https://$ProjectRef.supabase.co/rest/v1"

Write-Host '== Validando service_role (claims apenas) =='
if ($sr -match '^eyJ') {
  try {
    $claims = Get-JwtPayloadClaims -Jwt $sr
    $role = [string]$claims.role
    $ref = [string]$claims.ref
    Write-Host ("JWT claims: role=$role ref=$ref")
    if ($role -ne 'service_role') {
      Write-Host 'ERRO: chave nao e service_role (parece anon ou outra). Use Reveal da service_role.' -ForegroundColor Red
      exit 1
    }
    if ($ref -and $ref -ne $ProjectRef) {
      Write-Host ("ERRO: JWT ref=$ref nao bate com projeto $ProjectRef") -ForegroundColor Red
      exit 1
    }
  } catch {
    Write-Host ("ERRO ao decodificar JWT: " + $_.Exception.Message) -ForegroundColor Red
    exit 1
  }
} elseif ($sr -match '^sb_secret_') {
  Write-Host 'Chave sb_secret_* detectada (ok).'
} else {
  Write-Host 'AVISO: formato de chave nao reconhecido; seguindo mesmo assim.' -ForegroundColor Yellow
}

Write-Host "== GET $base =="
try {
  $get = Invoke-RestMethod -Uri $base -Method GET -TimeoutSec 30
  Write-Host ('GET: ' + ($get | ConvertTo-Json -Compress))
  if ([string]$get.codeVersion -ne $ExpectedCodeVersion) {
    Write-Host ("AVISO: codeVersion=$($get.codeVersion) (esperado $ExpectedCodeVersion)") -ForegroundColor Yellow
  }
} catch {
  Write-Host ("GET falhou: " + $_.Exception.Message) -ForegroundColor Red
}

Write-Host '== Tokens admin_fcm_tokens (count) =='
$tokenCount = 0
$platforms = @{}
try {
  $headersRest = @{
    Authorization = "Bearer $sr"
    apikey        = $sr
    Prefer        = 'count=exact'
  }
  # Prefer curl for Content-Range count reliability
  $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
  if ($null -ne $curl) {
    $hdrFile = [System.IO.Path]::GetTempFileName()
    $bodyFile = [System.IO.Path]::GetTempFileName()
    try {
      $uri = "$rest/admin_fcm_tokens?select=id,platform,updated_at"
      $code = & curl.exe -sS -D $hdrFile -o $bodyFile -w '%{http_code}' `
        -H "Authorization: Bearer $sr" `
        -H "apikey: $sr" `
        -H 'Prefer: count=exact' `
        --max-time 30 `
        $uri
      $bodyText = if (Test-Path $bodyFile) { [System.IO.File]::ReadAllText($bodyFile) } else { '[]' }
      $hdrText = if (Test-Path $hdrFile) { [System.IO.File]::ReadAllText($hdrFile) } else { '' }
      if ($code -ne '200' -and $code -ne '206') {
        Write-Host ("Falha REST tokens HTTP $code") -ForegroundColor Red
        $print = $bodyText
        if ($print.Length -gt 300) { $print = $print.Substring(0, 300) + '...' }
        Write-Host ("body=" + $print)
        exit 1
      }
      $rows = @()
      if ($bodyText.Trim()) {
        $parsed = $bodyText | ConvertFrom-Json
        if ($null -ne $parsed) { $rows = @($parsed) }
      }
      $tokenCount = $rows.Count
      if ($hdrText -match 'content-range:\s*[^\s/]+/(\d+)') {
        $tokenCount = [int]$Matches[1]
      }
      foreach ($r in $rows) {
        $p = if ($r.platform) { [string]$r.platform } else { 'unknown' }
        if (-not $platforms.ContainsKey($p)) { $platforms[$p] = 0 }
        $platforms[$p]++
      }
    } finally {
      Remove-Item -Force $hdrFile, $bodyFile -ErrorAction SilentlyContinue
    }
  } else {
    $tok = Invoke-RestMethod -Uri "$rest/admin_fcm_tokens?select=id,platform,updated_at" -Headers $headersRest -TimeoutSec 30
    $rows = @($tok)
    $tokenCount = $rows.Count
    foreach ($r in $rows) {
      $p = if ($r.platform) { [string]$r.platform } else { 'unknown' }
      if (-not $platforms.ContainsKey($p)) { $platforms[$p] = 0 }
      $platforms[$p]++
    }
  }
  $platSummary = if ($platforms.Count -gt 0) {
    ($platforms.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', '
  } else { '(nenhuma)' }
  Write-Host ("tokens: $tokenCount  platforms: $platSummary")
} catch {
  Write-Host ("Falha ao ler tokens: " + $_.Exception.Message) -ForegroundColor Red
  exit 1
}

if ($tokenCount -eq 0) {
  Write-Host ''
  Write-Host 'FALHA: 0 tokens em admin_fcm_tokens.' -ForegroundColor Red
  Write-Host 'Abra o app como admin, permita notificacao, aguarde alguns segundos e rode de novo.' -ForegroundColor Yellow
  Write-Host '  powershell -ExecutionPolicy Bypass -File scripts\fcm_e2e_test.ps1'
  exit 2
}

Write-Host '== POST teste notify-admin =='
$bodyObj = [ordered]@{
  tipo     = 'teste'
  titulo   = 'Teste FCM E2E'
  mensagem = "Push automatizado $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}
$body = $bodyObj | ConvertTo-Json -Compress

$sent = $null
$reason = $null
$errors = @()
$codeVersion = $null
$httpCode = '000'
$tipo = $null
$total = $null

$outFile = [System.IO.Path]::GetTempFileName()
$bodyFile = [System.IO.Path]::GetTempFileName()
try {
  [System.IO.File]::WriteAllText($bodyFile, $body, [System.Text.UTF8Encoding]::new($false))
  $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
  if ($null -eq $curl) {
    Write-Host 'ERRO: curl.exe nao encontrado (necessario no Windows para Authorization confiavel).' -ForegroundColor Red
    exit 1
  }
  $httpCode = & curl.exe -sS -o $outFile -w '%{http_code}' -X POST $base `
    -H "Authorization: Bearer $sr" `
    -H "apikey: $sr" `
    -H 'Content-Type: application/json' `
    --data-binary "@$bodyFile" `
    --max-time 60
  $respText = if (Test-Path $outFile) { [System.IO.File]::ReadAllText($outFile) } else { '' }
  if ($httpCode -eq '200') {
    $post = $respText | ConvertFrom-Json
    $sent = $post.sent
    $reason = $post.reason
    $codeVersion = $post.codeVersion
    $tipo = $post.tipo
    $total = $post.total
    if ($null -ne $post.errors) { $errors = @($post.errors) }
    Write-Host ("POST ok: tipo=$tipo sent=$sent total=$total reason=$reason errors=$($errors.Count) codeVersion=$codeVersion")
    if ($post.error) { Write-Host ("error=" + $post.error) -ForegroundColor Red }
    if ($errors.Count -gt 0) {
      foreach ($e in $errors) {
        $msg = [string]$e
        if ($msg.Length -gt 220) { $msg = $msg.Substring(0, 220) + '...' }
        Write-Host ("  err: " + $msg) -ForegroundColor Yellow
      }
    }
  } else {
    Write-Host ("POST falhou: HTTP $httpCode") -ForegroundColor Red
    $print = $respText
    if ($print.Length -gt 500) { $print = $print.Substring(0, 500) + '...' }
    Write-Host ("body=" + $print)
    if ($httpCode -eq '401' -and $respText -notmatch '"codeVersion"') {
      Write-Host 'DIAGNOSTICO: 401 sem codeVersion — function antiga; redeploy com scripts\fcm_deploy_test.ps1' -ForegroundColor Red
    }
    exit 1
  }
} finally {
  Remove-Item -Force $outFile, $bodyFile -ErrorAction SilentlyContinue
}

Write-Host '== Triggers / pg_net (opcional) =='
$access = $env:SUPABASE_ACCESS_TOKEN
if ([string]::IsNullOrWhiteSpace($access)) {
  Write-Host 'SKIP: SUPABASE_ACCESS_TOKEN ausente — nao da para consultar pg_trigger / net._http_response via CLI.'
  Write-Host 'Para checar no Dashboard SQL Editor:'
  Write-Host "  select tgname from pg_trigger where tgname like 'trg_notify_admin%';"
  Write-Host '  select id, status_code, created from net._http_response order by created desc limit 5;'
} else {
  try {
    $sql = @"
select json_build_object(
  'triggers', (select coalesce(json_agg(tgname), '[]'::json) from pg_trigger where tgname like 'trg_notify_admin%'),
  'fn_exists', exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname='notify_admin_via_edge'),
  'vault_secret', exists(select 1 from vault.secrets where name='notify_admin_service_role'),
  'pg_net', exists(select 1 from pg_extension where extname='pg_net')
) as info;
"@
    $tmpSql = [System.IO.Path]::GetTempFileName() + '.sql'
    try {
      [System.IO.File]::WriteAllText($tmpSql, $sql, [System.Text.UTF8Encoding]::new($false))
      $out = npx supabase db query --linked -f $tmpSql 2>&1 | Out-String
      if ($LASTEXITCODE -ne 0) {
        # fallback project-ref
        $out = npx supabase db query --project-ref $ProjectRef -f $tmpSql 2>&1 | Out-String
      }
      if ($LASTEXITCODE -eq 0) {
        Write-Host ($out.Trim())
      } else {
        Write-Host 'SKIP SQL: CLI nao autenticou / db query indisponivel.' -ForegroundColor Yellow
        $print = $out.Trim()
        if ($print.Length -gt 400) { $print = $print.Substring(0, 400) + '...' }
        Write-Host $print
      }
    } finally {
      Remove-Item -Force $tmpSql -ErrorAction SilentlyContinue
    }
  } catch {
    Write-Host ("SKIP SQL: " + $_.Exception.Message) -ForegroundColor Yellow
  }
}

Write-Host '== ADB (opcional) =='
$adb = Find-Adb
if ($null -eq $adb) {
  Write-Host 'SKIP: adb nao encontrado.'
} else {
  $devices = & $adb devices 2>&1 | Out-String
  Write-Host ($devices.Trim())
  $ready = @(& $adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\tdevice$' })
  if ($ready.Count -eq 0) {
    Write-Host 'Nenhum device ADB conectado.'
  } else {
    $path = & $adb shell pm path $PackageId 2>&1 | Out-String
    if ($path -match 'package:') {
      Write-Host ("App instalado: $PackageId")
      $ver = & $adb shell dumpsys package $PackageId 2>&1 | Select-String -Pattern 'versionName=|versionCode=' | Select-Object -First 4
      $ver | ForEach-Object { Write-Host $_.Line.Trim() }
    } else {
      Write-Host ("App NAO instalado neste device: $PackageId") -ForegroundColor Yellow
    }
  }
}

Write-Host ''
Write-Host '== Resumo =='
Write-Host ("tokens=$tokenCount sent=$sent total=$total reason=$reason errors=$($errors.Count) codeVersion=$codeVersion http=$httpCode")
if ($null -ne $sent -and [int]$sent -gt 0) {
  Write-Host 'Push deve ter chegado no celular (foreground/background). Se app morto (force-stop), Android ainda entrega se canal + FCM ok; verifique bandeja.' -ForegroundColor Green
  exit 0
}
if ($reason -eq 'nenhum token FCM') {
  Write-Host 'Function nao achou token admin (join/role). Confira usuarios.role=admin e token salvo.' -ForegroundColor Yellow
  exit 2
}
Write-Host 'sent=0 — veja errors acima / FIREBASE_SERVICE_ACCOUNT / token invalido.' -ForegroundColor Yellow
exit 3
