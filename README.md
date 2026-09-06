# Gemini 视觉通道（View_Skill）

基于网页端 Gemini（Google AI 订阅账号）的**识图 + 文本问答**通道封装，供 TRAE 代理随时调用。

> 底层采用社区工具 [`gemini-web-mcp-cli`](https://pypi.org/project/gemini-web-mcp-cli/)（MIT）。
> 该工具逆向调用 gemini.google.com 网页协议，**仅供教育/个人低频率使用**，与 Google 无关，
> 使用后果自负（违反 Google 服务条款，账号存在被风控的风险，请勿批量/并发滥用）。

## 目录

- [能力](#能力)
- [安装（首次，需联网）](#安装首次需联网)
- [登录认证](#登录认证)
- [日常使用](#日常使用)
- [代理说明](#代理说明)
- [排障](#排障)
- [风险与纪律](#风险与纪律)

## 能力

通过统一入口 [g.ps1](g.ps1) 调用（自动注入代理环境变量）：

```powershell
# 识图（本地图片 + 问题）
powershell -ExecutionPolicy Bypass -File g.ps1 chat "请详细解释这个报错" -f "C:\path\error.png" -m pro

# 纯文本问答
powershell -ExecutionPolicy Bypass -File g.ps1 chat "帮我解释这段代码" -m pro

# 体检 / 登录状态
powershell -ExecutionPolicy Bypass -File g.ps1 doctor
powershell -ExecutionPolicy Bypass -File g.ps1 login --check

# 附带能力（加分项，低频使用）
powershell -ExecutionPolicy Bypass -File g.ps1 image "一只戴礼帽的熊猫" -o out.png
powershell -ExecutionPolicy Bypass -File g.ps1 research "topic" -o report.md
```

支持的图片格式：PNG / JPEG / GIF / WebP。
模型可用列表以实际登录账号为准（默认 `-m pro`，可省略；Flash 模型纯文本聊天无需 Chrome）。

## 安装（首次，需联网）

前置：Windows + winget。以下命令在终端执行（代理无需特殊处理，安装源在国内可达）：

```powershell
# 1) 安装 uv（Python 包管理器）
winget install --id astral-sh.uv -e --scope user --silent --accept-package-agreements --accept-source-agreements

# 2) 安装 gemini-web-mcp-cli（提供 gemcli 命令）
uv tool install gemini-web-mcp-cli

# 3) 安装 Google Chrome（识图附件需要 Chrome 生成 BotGuard token）
winget install --id Google.Chrome -e --scope user --silent --accept-package-agreements --accept-source-agreements
```

> 若某步执行后找不到命令，请**新开一个终端**再试（PATH 刷新）。

## 登录认证

```powershell
powershell -ExecutionPolicy Bypass -File g.ps1 login
```

会打开 Chrome 到 gemini.google.com，用你的 Google 账号登录一次（首次需人工输入，密码不会被程序记录）。
之后验证：

```powershell
powershell -ExecutionPolicy Bypass -File g.ps1 login --check
powershell -ExecutionPolicy Bypass -File g.ps1 doctor
```

> 后台/长时间运行的识图任务如需稳定，可参考 `gemcli chrome start` 维持 Chrome daemon；普通交互使用无需。

## 代理说明

[config.json](config.json)：

- `proxy.enabled`：是否注入代理（国内访问 Google 需 `true`）
- `proxy.auto_from_registry`：为 `true` 时自动读 Windows“系统代理”设置
- `proxy.url`：留空走自动；若自动读不到（如代理软件只在你手动开系统代理时生效），可手填，如 `http://127.0.0.1:7890`

Chrome 自身走系统代理，无需额外配置。

## 排障

| 现象 | 处理 |
|---|---|
| `找不到 gemcli` | 确认 `uv tool install gemini-web-mcp-cli` 成功并新开终端；或编辑 `config.json` 的 `gemcli.path` |
| 提示登录失效 | `g.ps1 login --check`；失效则 `g.ps1 login` 重新登录 |
| 网络超时/连不上 | 检查代理软件是否开启；`config.json` 手填 `proxy.url`；`g.ps1 doctor` |
| 识图报 BotGuard/需要 Chrome | 确认 Chrome 已装、已在其中登录过 Google；长时运行用 `gemcli chrome start` |
| 模型不存在 | `g.ps1 chat "hi" -m flash` 或查看账号可用模型列表 |
| 其它 | `g.ps1 doctor --verbose`，把输出发回给 TRAE 协助排查 |

## 风险与纪律

- **低频个人使用**（发报错截图、少量问答）；**禁止**批量、并发、爬取式调用，避免触发账号风控。
- 如遇临时验证页/会话受限：立即停止，去浏览器人工确认一次，稍后再用。
- Cookie/登录态文件等价于账号凭证，请勿外泄。
