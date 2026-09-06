---
name: "gemini-vision"
description: "Gives the agent vision/OCR plus a text Q&A channel through the user's web Gemini subscription. Invoke when the user attaches or references an image/screenshot to read (e.g. code error screenshots, UI screenshots) or asks to answer a text question via Gemini."
---

# Gemini Vision Channel (gemini-vision)

Provide **image understanding (vision/OCR)** and **text Q&A** by driving the user's
web-Gemini subscription (Google AI plan account) through a local CLI wrapper.
Useful when the primary model cannot see images.

## When to invoke

- The user attaches/pastes a **screenshot or image** and wants it read/explained
  (typical: code error messages, IDE screenshots, UI bugs, diagrams, charts).
- The user explicitly asks to use Gemini to answer a **text question** (backup channel).

## Where the channel lives

- Project: `E:\TRAE SOLO\View_Skill`
- Entry script (always use this): `E:\TRAE SOLO\View_Skill\g.ps1`
  It injects the system proxy (auto-read from Windows registry) and redirects
  gemcli's home into `E:\TRAE SOLO\View_Skill\.home` so everything stays
  self-contained.
- Binary: gemcli (gemini-web-mcp-cli), installed in the project, not on PATH.
  Never call `gemcli` directly — always through `g.ps1`.
- Config: `E:\TRAE SOLO\View_Skill\config.json` (proxy / default model / gemcli path).
- Runtime requirement: a proxy that can reach Google must be running (user is in CN,
  system-proxy mode). Auto-detected; if auto fails, set `proxy.url` in config.json.

## Standard invocation

All commands run in a shell (PowerShell). Note: the process may print benign
sandbox warnings about `TokenBroker`/`OneAuth` paths and `BotGuard` fallback —
ignore them and judge success by the answer content, not the exit code.

```powershell
# 1) Read / explain an image (vision). Default model pro; -m flash is a lighter option.
powershell -NoProfile -ExecutionPolicy Bypass -File "E:\TRAE SOLO\View_Skill\g.ps1" chat "<question about the image>" -f "<absolute path to image>" -m pro

# 2) Plain text Q&A through Gemini
powershell -NoProfile -ExecutionPolicy Bypass -File "E:\TRAE SOLO\View_Skill\g.ps1" chat "<question>" -m pro
```

### Good prompt style for code-error screenshots

Describe exactly what you need, e.g.:
`Read this error screenshot carefully. Quote the exact error line, then explain
the likely cause and how to fix it.`

If the image needs closer inspection, mention what detail matters (stack trace,
line numbers, red text) — the model will zoom accordingly.

## Preflight / health checks

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "E:\TRAE SOLO\View_Skill\g.ps1" login --check
powershell -NoProfile -ExecutionPolicy Bypass -File "E:\TRAE SOLO\View_Skill\g.ps1" doctor
```

- `login --check` should print "Authentication is valid."
- If auth is expired: re-login (opens a browser window for the user to sign in once):
  `... g.ps1 login`  — then re-check.

## Troubleshooting

| Symptom | Action |
|---|---|
| `ConnectTimeout` / network error | Transient. Simply retry the same command once. |
| Output says auth invalid / `login --check` fails | Run `g.ps1 login` (user signs in once in the opened browser), then retry. |
| `BotGuard` / Token Factory warning | Usually benign — requests fall back to plain HTTP and still work for chat & image Q&A. |
| Trailing "TRAE Sandbox Error: hit restricted ... TokenBroker/OneAuth ..." | Benign browser background noise. Judge by the answer text. |
| Image upload fails repeatedly | Check the file is PNG/JPEG/GIF/WebP and the path is absolute; retry once. |
| Pro model refuses / needs BotGuard | Retry; or retry with `-m flash`. |
| Proxy change | Edit `proxy.url` in `E:\TRAE SOLO\View_Skill\config.json` (e.g. `http://127.0.0.1:PORT`). |

## Discipline & risk (important)

- **Low-frequency personal use only.** This channel reverse-engineers the Gemini
  web app using the account's login cookies. Do NOT batch, loop, parallelize, or
  scrape with it — heavy automation risks Google account flags.
- Never paste or expose the account's cookies/auth files (they live under
  `E:\TRAE SOLO\View_Skill\.home\.gemini-web-mcp-cli\`, treat as credentials).
- Favor the primary model for ordinary text work; use this channel when vision is
  genuinely needed (images the primary model cannot see).
- After getting the answer, summarize/act on it in the main conversation flow.

## Bonus capabilities (available, same low-frequency rules)

```powershell
# Generate an image from text
... g.ps1 image "a red panda wearing a top hat" -o "E:\out.png"
# Usage limits of the account
... g.ps1 limits
```
