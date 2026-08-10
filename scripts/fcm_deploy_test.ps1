# Deploy + smoke test da Edge Function notify-admin (FCM admin).
#
# Ordem de uso (PowerShell 5.1):
#   1) cd D:\smbjj
#   2) $env:SUPABASE_ACCESS_TOKEN = "<PAT>"          # obrigatorio (Dashboard > Account > Access Tokens)
#   3) $env:SUPABASE_SERVICE_ROLE_KEY = "<service>" # opcional (so para POST de teste / contagem de tokens)
#   4) powershell -ExecutionPolicy Bypass -File scripts\fcm_deploy_test.ps1
#
# NAO cole tokens neste arquivo. NAO commit env vars.

$ErrorActionPreference = 'Stop'
$ProjectRef = 'zhjnxspunbtyqhlyliuw'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

# --- Validacao de env no inicio ---
$missing = @()
if ([string]::IsNullOrWhiteSpace($env:SUPABASE_ACCESS_TOKEN)) {
  $missing += 'SUPABASE_ACCESS_TOKEN'
}
if ($missing.Count -gt 0) {
  Write-Host ''
  Write-Host 'ERRO: variaveis de ambiente obrigatorias ausentes:' -ForegroundColor Red
  foreach ($m in $missing) { Write-Host ("  - " + $m) -ForegroundColor Red }
  Write-Host ''
  Write-Host 'Ordem correta:'
  Write-Host '  cd D:\smbjj'
  Write-Host '  $env:SUPABASE_ACCESS_TOKEN = "<PAT>"'
  Write-Host '  $env:SUPABASE_SERVICE_ROLE_KEY = "<service_role>"   # opcional para POST de teste'
  Write-Host '  powershell -ExecutionPolicy Bypass -File scripts\fcm_deploy_test.ps1'
  Write-Host ''
  Write-Host 'Tokens: Dashboard Supabase > Account > Access Tokens e Project Settings > API > service_role.'
  exit 1
}

$hasServiceRole = -not [string]::IsNullOrWhiteSpace($env:SUPABASE_SERVICE_ROLE_KEY)
if (-not $hasServiceRole) {
  Write-Host 'AVISO: SUPABASE_SERVICE_ROLE_KEY ausente - deploy segue; POST de teste e leitura de tokens serao pulados.' -ForegroundColor Yellow
}

Write-Host '== Deploy notify-admin =='
npx supabase functions deploy notify-admin --project-ref $ProjectRef --no-verify-jwt
if ($LASTEXITCODE -ne 0) {
  Write-Error "Deploy falhou (exit $LASTEXITCODE)."
}

Write-Host '== Functions list =='
npx supabase functions list --project-ref $ProjectRef

$base = "https://$ProjectRef.supabase.co/functions/v1/notify-admin"
Write-Host "== GET $base =="
try {
  $get = Invoke-RestMethod -Uri $base -Method GET -TimeoutSec 30
  Write-Host ('GET ok: ' + ($get | ConvertTo-Json -Compress))
} catch {
  Write-Host ("GET falhou: " + $_.Exception.Message)
}

if (-not $hasServiceRole) {
  Write-Host 'SUPABASE_SERVICE_ROLE_KEY ausente - pulando POST de teste e checagem de tokens.'
  Write-Host 'Webhooks: Database > Webhooks > INSERT em alunos/pedidos > URL acima + Authorization Bearer service_role.'
  exit 0
}

# Trim evita espaco/BOM colado do Dashboard (quebra match exact na function)
$sr = $env:SUPABASE_SERVICE_ROLE_KEY.Trim().Trim('"').Trim("'")

# Aviso se parecer anon/publishable em vez de service_role
if ($sr -match '^eyJ') {
  try {
    $payloadB64 = ($sr.Split('.')[1]).Replace('-', '+').Replace('_', '/')
    while ($payloadB64.Length % 4 -ne 0) { $payloadB64 += '=' }
    $payloadJson = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payloadB64))
    if ($payloadJson -notmatch '"role"\s*:\s*"service_role"') {
      Write-Host 'AVISO: JWT em SUPABASE_SERVICE_ROLE_KEY nao tem role=service_role (anon/publishable?). POST tende a 401.' -ForegroundColor Yellow
    }
  } catch {
    Write-Host 'AVISO: nao foi possivel decodificar SUPABASE_SERVICE_ROLE_KEY como JWT.' -ForegroundColor Yellow
  }
}

$headers = @{
  Authorization  = "Bearer $sr"
  apikey         = $sr
  'Content-Type' = 'application/json'
}

Write-Host '== Tokens admin_fcm_tokens (count) =='
try {
  $tok = Invoke-RestMethod -Uri "https://$ProjectRef.supabase.co/rest/v1/admin_fcm_tokens?select=id,platform,updated_at" -Headers $headers -TimeoutSec 30
  Write-Host ("tokens: " + @($tok).Count)
} catch {
  Write-Host ("Falha ao ler tokens: " + $_.Exception.Message)
}

Write-Host '== POST teste notify-admin =='
# ConvertTo-Json evita parser error de aspas/encoding no body (PS 5.1)
$bodyObj = [ordered]@{
  tipo     = 'teste'
  titulo   = 'Teste FCM'
  mensagem = 'Push com app morto'
}
$body = $bodyObj | ConvertTo-Json -Compress

# curl.exe envia Authorization de forma confiavel no Windows PowerShell 5.1
# (Invoke-RestMethod / WebRequest podem omitir o header Authorization)
$curl = Get-Command curl.exe -ErrorAction SilentlyContinue
if ($null -eq $curl) {
  Write-Host 'curl.exe nao encontrado; tentando Invoke-RestMethod (pode falhar com 401 no PS 5.1)...' -ForegroundColor Yellow
  try {
    $post = Invoke-RestMethod -Uri $base -Method POST -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 60
    $errCount = 0
    if ($null -ne $post.errors) { $errCount = @($post.errors).Count }
    Write-Host ("POST ok: tipo=$($post.tipo) sent=$($post.sent) total=$($post.total) reason=$($post.reason) errors=$errCount")
    if ($post.error) { Write-Host ("error=" + $post.error) }
  } catch {
    Write-Host ("POST falhou: " + $_.Exception.Message)
    if ($_.ErrorDetails.Message) {
      $msg = [string]$_.ErrorDetails.Message
      if ($msg.Length -gt 400) { $msg = $msg.Substring(0, 400) + '...' }
      Write-Host ("body=" + $msg)
    }
  }
  exit 0
}

$outFile = [System.IO.Path]::GetTempFileName()
$bodyFile = [System.IO.Path]::GetTempFileName()
try {
  # Arquivo evita que o PowerShell mastigue aspas do JSON na linha de comando do curl
  [System.IO.File]::WriteAllText($bodyFile, $body, [System.Text.UTF8Encoding]::new($false))
  $httpCode = & curl.exe -sS -o $outFile -w '%{http_code}' -X POST $base `
    -H "Authorization: Bearer $sr" `
    -H "apikey: $sr" `
    -H 'Content-Type: application/json' `
    --data-binary "@$bodyFile" `
    --max-time 60
  $respText = ''
  if (Test-Path $outFile) {
    $respText = [System.IO.File]::ReadAllText($outFile)
  }
  if ($httpCode -eq '200') {
    try {
      $post = $respText | ConvertFrom-Json
      $errCount = 0
      if ($null -ne $post.errors) { $errCount = @($post.errors).Count }
      Write-Host ("POST ok: tipo=$($post.tipo) sent=$($post.sent) total=$($post.total) reason=$($post.reason) errors=$errCount")
      if ($post.error) { Write-Host ("error=" + $post.error) }
    } catch {
      Write-Host ("POST ok (HTTP 200): " + $respText)
    }
  } else {
    Write-Host ("POST falhou: HTTP $httpCode")
    if ($respText.Length -gt 500) { $respText = $respText.Substring(0, 500) + '...' }
    Write-Host ("body=" + $respText)
  }
} finally {
  if (Test-Path $outFile) { Remove-Item -Force $outFile -ErrorAction SilentlyContinue }
  if (Test-Path $bodyFile) { Remove-Item -Force $bodyFile -ErrorAction SilentlyContinue }
}
