# Deploy + smoke test da Edge Function notify-admin (FCM admin).
# Requisitos:
#   $env:SUPABASE_ACCESS_TOKEN  = PAT em https://supabase.com/dashboard/account/tokens
#   $env:SUPABASE_SERVICE_ROLE_KEY = Project Settings → API → service_role (só para o teste POST)
#
# Uso (na raiz do repo):
#   powershell -ExecutionPolicy Bypass -File scripts/fcm_deploy_test.ps1

$ErrorActionPreference = 'Stop'
$ProjectRef = 'zhjnxspunbtyqhlyliuw'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

if (-not $env:SUPABASE_ACCESS_TOKEN) {
  Write-Error 'Defina SUPABASE_ACCESS_TOKEN (Dashboard → Account → Access Tokens).'
}

Write-Host '== Deploy notify-admin =='
npx supabase functions deploy notify-admin --project-ref $ProjectRef --no-verify-jwt

Write-Host '== Functions list =='
npx supabase functions list --project-ref $ProjectRef

$base = "https://$ProjectRef.supabase.co/functions/v1/notify-admin"
Write-Host "== GET $base =="
try {
  $get = Invoke-RestMethod -Uri $base -Method GET -TimeoutSec 30
  Write-Host ("GET ok: " + ($get | ConvertTo-Json -Compress))
} catch {
  Write-Host "GET falhou: $($_.Exception.Message)"
}

if (-not $env:SUPABASE_SERVICE_ROLE_KEY) {
  Write-Host 'SUPABASE_SERVICE_ROLE_KEY ausente — pulando POST de teste e checagem de tokens.'
  Write-Host 'Webhooks: Database → Webhooks → INSERT em alunos/pedidos → URL acima + Authorization Bearer service_role.'
  exit 0
}

$sr = $env:SUPABASE_SERVICE_ROLE_KEY
$headers = @{
  Authorization  = "Bearer $sr"
  apikey         = $sr
  'Content-Type' = 'application/json'
}

Write-Host '== Tokens admin_fcm_tokens (count) =='
try {
  $tok = Invoke-RestMethod -Uri "https://$ProjectRef.supabase.co/rest/v1/admin_fcm_tokens?select=id,platform,updated_at" -Headers $headers -TimeoutSec 30
  Write-Host ("tokens: $($tok.Count)")
} catch {
  Write-Host "Falha ao ler tokens: $($_.Exception.Message)"
}

Write-Host '== POST teste notify-admin =='
$body = '{"tipo":"teste","titulo":"Teste FCM","mensagem":"Push com app morto"}'
try {
  $post = Invoke-RestMethod -Uri $base -Method POST -Headers $headers -Body $body -TimeoutSec 60
  # Não imprime tokens/erros longos; só resumo
  Write-Host ("POST ok: tipo=$($post.tipo) sent=$($post.sent) total=$($post.total) reason=$($post.reason) errors=$($post.errors.Count)")
  if ($post.error) { Write-Host "error=$($post.error)" }
} catch {
  Write-Host "POST falhou: $($_.Exception.Message)"
  if ($_.ErrorDetails.Message) {
    $msg = $_.ErrorDetails.Message
    if ($msg.Length -gt 400) { $msg = $msg.Substring(0, 400) + '…' }
    Write-Host "body=$msg"
  }
}
