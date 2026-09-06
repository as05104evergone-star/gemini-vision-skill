<#
.SYNOPSIS
  Unified gemcli entry: inject proxy env vars, then call gemcli (vision/text).
.DESCRIPTION
  gemini.google.com needs a proxy in CN; Python tools ignore Windows "system proxy".
  This script decides the proxy from config.json (auto-read registry system proxy,
  or manual url), sets process-level HTTP_PROXY/HTTPS_PROXY, then passes through
  remaining args to gemcli.
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File g.ps1 chat "explain this error" -f "C:\tmp\err.png" -m pro
  powershell -ExecutionPolicy Bypass -File g.ps1 doctor
#>
[CmdletBinding()]
param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Passthru
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $ScriptDir 'config.json'

# ---------- 0. keep gemcli self-contained inside this project ----------
# gemcli resolves its config/profiles/chrome-data via Path.home() (Windows:
# honours USERPROFILE). Redirecting keeps every write inside the workspace,
# which also avoids TRAE sandbox restrictions on C:\Users\...\.gemini-*.
$FakeHome = Join-Path $ScriptDir '.home'
New-Item -ItemType Directory -Force -Path $FakeHome | Out-Null
$env:USERPROFILE = $FakeHome
$env:HOME = $FakeHome

# ---------- 1. parse config ----------
$Cfg = @{ proxy = @{ enabled = $true; auto_from_registry = $true; url = '' } }
if (Test-Path $ConfigPath) {
  try { $Cfg = Get-Content $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { Write-Warning "config.json parse failed, use defaults: $($_.Exception.Message)" }
}

# ---------- 2. resolve proxy ----------
$proxyUrl = $null
if ($Cfg.proxy.enabled) {
  if ($Cfg.proxy.url) {
    $proxyUrl = $Cfg.proxy.url
  }
  elseif ($Cfg.proxy.auto_from_registry) {
    try {
      $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
      $s = Get-ItemProperty -Path $key -ErrorAction Stop
      if ($s.ProxyEnable -and $s.ProxyServer) {
        $server = $s.ProxyServer
        if ($server -notmatch '^https?://') { $server = 'http://' + $server }
        $proxyUrl = $server
      }
    } catch {
      Write-Warning "read system proxy failed (set proxy.url in config.json manually): $($_.Exception.Message)"
    }
  }
}

# ---------- 3. inject proxy env ----------
if ($proxyUrl) {
  $env:HTTP_PROXY  = $proxyUrl
  $env:HTTPS_PROXY = $proxyUrl
  $env:NO_PROXY    = 'localhost,127.0.0.1,::1'
  Write-Host "[g] proxy: $proxyUrl"
} else {
  Write-Host "[g] proxy disabled (direct network assumed)"
}

# ---------- 4. locate gemcli ----------
$gemcli = $null
if ($Cfg.gemcli.path -and (Test-Path $Cfg.gemcli.path)) {
  $gemcli = $Cfg.gemcli.path
} else {
  $cand = Get-Command gemcli -ErrorAction SilentlyContinue
  if ($cand) { $gemcli = $cand.Source }
  else {
    $candidates = @(
      (Join-Path $ScriptDir '.uv\bin\gemcli.exe'),
      (Join-Path $HOME '.local\bin\gemcli.exe'),
      (Join-Path $HOME '.local\bin\gemcli.cmd')
    )
    foreach ($p in $candidates) {
      if (Test-Path $p) { $gemcli = $p; break }
    }
  }
}
if (-not $gemcli) {
  Write-Error "gemcli not found. Run: uv tool install gemini-web-mcp-cli"
  exit 1
}
Write-Host "[g] gemcli: ${gemcli}"

# ---------- 5. passthrough ----------
if ($Passthru.Count -eq 0) {
  & $gemcli --help
} else {
  & $gemcli @Passthru
}
exit $LASTEXITCODE
