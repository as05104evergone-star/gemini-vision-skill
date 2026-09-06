# Copies gemini-vision SKILL.md to the user-level TRAE skills dir (global).
$src = 'e:\TRAE SOLO\View_Skill\.trae\skills\gemini-vision\SKILL.md'
$dstDir = Join-Path $env:USERPROFILE '.trae\skills\gemini-vision'
New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
Copy-Item $src (Join-Path $dstDir 'SKILL.md') -Force
Write-Host ("copied -> " + (Test-Path (Join-Path $dstDir 'SKILL.md')))
