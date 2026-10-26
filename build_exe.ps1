# ==============================================================================
# Build Script: Package ps_deploy.ps1 into Standalone ps_deploy.exe (ps2exe)
# Hardened against Windows Defender ML False Positives (Trojan:Win32/Bearfoos.A!ml)
# ==============================================================================
[CmdletBinding()]
param(
    [string]$SourceScript   = "",
    [string]$OutputExe      = "",
    [string]$IconFile       = "",
    [string]$AppTitle       = "Remote Deployment Console",
    [string]$AppDescription = "Enterprise Windows Remote Software Deployment & Administration Console",
    [string]$CompanyName    = "Enterprise IT Operations",
    [string]$ProductName    = "Remote Deployment Console",
    [string]$AppVersion     = "1.4.0.0",
    [string]$Copyright      = "Copyright (c) 2026 Enterprise IT Operations. All rights reserved.",
    [string]$CertThumbprint = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { [System.AppDomain]::CurrentDomain.BaseDirectory.TrimEnd('\') }
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }
if (-not $SourceScript) { $SourceScript = Join-Path $scriptDir "ps_deploy.ps1" }
if (-not $OutputExe)    { $OutputExe    = Join-Path $scriptDir "ps_deploy.exe" }
if (-not $IconFile)     { $IconFile     = Join-Path $scriptDir "ps_deploy.ico" }

if (-not (Test-Path -LiteralPath $SourceScript)) {
    Write-Error "Source script not found: $SourceScript"
    exit 1
}

if (-not (Test-Path -LiteralPath $IconFile)) {
    Write-Error "Icon file not found: $IconFile (ps_deploy.ico is required when packaging ps_deploy.exe)"
    exit 1
}

$resolvedSource = (Resolve-Path -LiteralPath $SourceScript).Path
$resolvedIcon   = (Resolve-Path -LiteralPath $IconFile).Path
$indexerScript  = Join-Path $scriptDir ".agents\skills\windows-team-orchestrator\scripts\Get-PsAstGraph.ps1"

# ==============================================================================
# Step 0 Pre-Flight Gate (WL-009 & WL-011): Delegate CRLF + UTF-8 BOM Normalization,
# Line 1 Header Guard, PS 5.1 + PS 7 AST, and Embedded [xml] XAML + Control Check
# ==============================================================================
Write-Host "Running Pre-Flight Validation Gate via Get-PsAstGraph.ps1..." -ForegroundColor Cyan
$preFlightJson = & $indexerScript -LiteralPath $resolvedSource -NormalizeCrlf -ExportGraphify | Out-String
$preFlight = $preFlightJson | ConvertFrom-Json

if (-not $preFlight.ast_verified -or -not $preFlight.ps51_verified -or -not $preFlight.header_clean -or -not $preFlight.xaml_verified) {
    $errMsg = ($preFlight.errors | ForEach-Object { "[$($_.engine) L$($_.line)] $($_.message)" }) -join "`n"
    Write-Error "PRE-FLIGHT GATE FAILED:`n$errMsg"
    exit 1
}
Write-Host "Pre-Flight Gate PASSED (SHA256: $($preFlight.sha256.Substring(0,12))..., 0 PS 5.1/PS 7 AST errors, clean header, $($preFlight.xaml_control_check.xaml_named_count) XAML controls verified)." -ForegroundColor Green

# Verify PS2EXE is installed
if (-not (Get-Command -Name 'Invoke-PS2EXE' -ErrorAction SilentlyContinue)) {
    Write-Host "Installing ps2exe module..." -ForegroundColor Cyan
    Install-Module -Name 'ps2exe' -Scope CurrentUser -Force -AllowClobber
}

# Close any running ps_deploy process before overwriting
$running = Get-Process -Name 'ps_deploy' -ErrorAction SilentlyContinue
if ($running) {
    Write-Host "Stopping running instance of ps_deploy..." -ForegroundColor Yellow
    $running | Stop-Process -Force
    Start-Sleep -Milliseconds 500
}

# Backup existing executable
if (Test-Path -LiteralPath $OutputExe) {
    $prevExe = [System.IO.Path]::ChangeExtension($OutputExe, ".prev.exe")
    Copy-Item -LiteralPath $OutputExe -Destination $prevExe -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $OutputExe -Force -ErrorAction SilentlyContinue
}

# Strip Mark-of-the-Web (Zone.Identifier ADS) from source and icon prior to compilation
Unblock-File -LiteralPath $resolvedSource -ErrorAction SilentlyContinue
Unblock-File -LiteralPath $resolvedIcon   -ErrorAction SilentlyContinue

# ==============================================================================
# Compile with Full PE Assembly Metadata, Native x64 PE32+ Header & OS Manifest
# Mitigates Windows Defender ML False Positives (Trojan:Win32/Bearfoos.A!ml)
# ==============================================================================
Write-Host "Compiling $resolvedSource into 64-bit PE32+ $OutputExe (Icon: $resolvedIcon, Version: $AppVersion)..." -ForegroundColor Cyan
$ps2exeParams = @{
    inputFile       = $resolvedSource
    outputFile      = $OutputExe
    iconFile        = $resolvedIcon
    noConsole       = $true
    STA             = $true
    x64             = $true
    UNICODEEncoding = $true
    supportOS       = $true
    DPIAware        = $true
    title           = $AppTitle
    description     = $AppDescription
    company         = $CompanyName
    product         = $ProductName
    copyright       = $Copyright
    trademark       = $ProductName
    version         = $AppVersion
}
Invoke-PS2EXE @ps2exeParams

if (-not (Test-Path -LiteralPath $OutputExe)) {
    Write-Error "Build failed: output executable was not generated."
    exit 1
}

# Remove any companion .config if present and strip Mark-of-the-Web (Zone.Identifier ADS)
$exeConfigPath = "$OutputExe.config"
if (Test-Path -LiteralPath $exeConfigPath) {
    Remove-Item -LiteralPath $exeConfigPath -Force -ErrorAction SilentlyContinue
}
Unblock-File -LiteralPath $OutputExe -ErrorAction SilentlyContinue

# ==============================================================================
# Authenticode Code Signing (SHA-256)
# ==============================================================================
$signingCert = $null
if ($CertThumbprint) {
    $signingCert = Get-ChildItem -LiteralPath 'Cert:\CurrentUser\My', 'Cert:\LocalMachine\My' -ErrorAction SilentlyContinue |
        Where-Object { $_.Thumbprint -eq $CertThumbprint -and $_.HasPrivateKey } |
        Select-Object -First 1
} else {
    $now = Get-Date
    $signingCert = Get-ChildItem -LiteralPath 'Cert:\CurrentUser\My', 'Cert:\LocalMachine\My' -CodeSigningCert -ErrorAction SilentlyContinue |
        Where-Object { $_.HasPrivateKey -and $_.NotAfter -gt $now } |
        Sort-Object NotAfter -Descending |
        Select-Object -First 1
}

$sigStatusText = "Unsigned (no local CodeSigningCert found)"
if ($signingCert) {
    Write-Host "Applying SHA-256 Authenticode signature using certificate: $($signingCert.Subject) [$($signingCert.Thumbprint)]..." -ForegroundColor Cyan
    $sigResult = $null
    for ($attempt = 1; $attempt -le 5; $attempt++) {
        Start-Sleep -Milliseconds 400
        try {
            $sigResult = Set-AuthenticodeSignature -LiteralPath $OutputExe -Certificate $signingCert -HashAlgorithm SHA256 -ErrorAction Stop
            if ($sigResult -and $sigResult.SignerCertificate) { break }
        } catch {
            if ($attempt -eq 5) { Write-Warning "Authenticode signing retry exhausted: $($_.Exception.Message)" }
        }
    }
    if ($sigResult -and $sigResult.SignerCertificate) {
        $sigStatusText = "Signed ($($sigResult.SignerCertificate.Subject) | Status: $($sigResult.Status))"
    }
}

$item = Get-Item -LiteralPath $OutputExe
Write-Host "Build complete: $($item.FullName) ($([Math]::Round($item.Length / 1KB, 1)) KB) | Icon: $resolvedIcon | Authenticode: $sigStatusText" -ForegroundColor Green
