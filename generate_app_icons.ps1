# Script to generate app icons from logo_peer.png
Write-Host "Generating app icons from logo_peer.png..." -ForegroundColor Cyan

# Check if logo_peer.png exists
$logoPath = "assets\images\logo_peer.png"
if (-not (Test-Path $logoPath)) {
    Write-Host "Error: logo_peer.png not found at $logoPath" -ForegroundColor Red
    Write-Host "Please place your logo at: $logoPath" -ForegroundColor Yellow
    exit 1
}

Write-Host "Found logo at: $logoPath" -ForegroundColor Green

# Run flutter pub get to install flutter_launcher_icons
Write-Host "`nInstalling dependencies..." -ForegroundColor Cyan
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to install dependencies" -ForegroundColor Red
    exit 1
}

# Generate icons
Write-Host "`nGenerating launcher icons..." -ForegroundColor Cyan
flutter pub run flutter_launcher_icons

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nApp icons generated successfully!" -ForegroundColor Green
    Write-Host "`nIcons created for:" -ForegroundColor Cyan
    Write-Host "  Android" -ForegroundColor White
    Write-Host "  iOS" -ForegroundColor White
    Write-Host "  Web" -ForegroundColor White
    Write-Host "  Windows" -ForegroundColor White
    Write-Host "  macOS" -ForegroundColor White
} else {
    Write-Host "`nFailed to generate icons" -ForegroundColor Red
    exit 1
}

Write-Host "`nDone! Your app now uses logo_peer.png as the icon." -ForegroundColor Green
