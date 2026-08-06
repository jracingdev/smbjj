# Instala o app no celular via ADB Wi-Fi (rode no PC local).
# Uso:
#   .\tools\install_adb_wifi.ps1
#   .\tools\install_adb_wifi.ps1 -Device "192.168.0.50:5555"

param(
  [string]$Device = ""
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "==> Atualizando repositorio..." -ForegroundColor Cyan
git pull origin main
if ($LASTEXITCODE -ne 0) { git pull origin master }

Write-Host "==> Dependencias..." -ForegroundColor Cyan
flutter pub get

if ($Device -ne "") {
  Write-Host "==> Conectando ADB Wi-Fi em $Device ..." -ForegroundColor Cyan
  adb connect $Device
}

Write-Host "==> Dispositivos:" -ForegroundColor Cyan
adb devices -l
flutter devices

Write-Host "==> Build + install release..." -ForegroundColor Cyan
flutter install --release

Write-Host "Concluido." -ForegroundColor Green
