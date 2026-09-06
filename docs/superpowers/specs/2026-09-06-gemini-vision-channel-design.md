# Gemini 视觉通道设计规格

- 日期：2026-09-06
- 状态：已批准（会话内逐项确认）
- 项目目录：`e:\TRAE SOLO\View_Skill`

## 1. 背景与目标

用户主模型（Deepseek-V4-Flash API）非多模态，缺乏视觉能力。用户在网页端拥有 Google AI Pro/Gemini 订阅（人在中国大陆，通过系统代理访问 Google；无境外信用卡，无法走官方付费 API）。

目标：基于用户已订阅的网页端 Gemini，建立一条**识图 + 文本问答**通道，供 TRAE 代理在需要看图（如代码报错截图）时调用；并封装为 TRAE Skill，使其"随时可调用"。

## 2. 关键决策（已与用户确认）

| 决策点 | 结论 |
|---|---|
| 接入路线 | Cookie 通道（非官方网页 RPC），复用网页订阅能力；接受低账号风险 |
| 实现策略 | 直接采用现成社区工具 `gemini-web-mcp-cli`，不自研 MCP/协议层 |
| 能力范围 | 识图 + 文本问答为核心；文生图/视频/音乐/研究等为附带加分项 |
| 浏览器 | 接受安装 Google Chrome 并登录一次 Gemini（识图附件需 Chrome BotGuard token） |
| 网络 | 中国大陆系统代理模式；代理在封装层注入进程环境变量 |
| 交付形态 | 仅封装为 TRAE Skill（CLI 驱动），不注册 TRAE MCP |

## 3. 采用组件

- **`gemini-web-mcp-cli` v0.6.13**（MIT，PyPI，2026-08-20 发布，Python >=3.11）
  - CLI：`gemcli`；MCP Server：`gemini-web-mcp`（本次不注册到 TRAE）
  - 识图：`gemcli chat "<question>" -f <local-image> -m pro`
  - 文本：`gemcli chat "<question>" -m pro`
  - 附带：`gemcli image|video|music|research|limits`
  - 运维：`gemcli doctor`、`gemcli login [--manual] [--check]`、`gemcli chrome start|status`（后台持久 Chrome daemon）、`gemcli limits`
- **Google Chrome**（winget 安装；识图/BotGuard 必需）
- **uv**（winget 安装；推荐安装器，用于 `uv tool install gemini-web-mcp-cli`）

## 4. 本机环境现状（已探测）

- Edge 存在（默认路径）；**Chrome 缺失** → 需安装
- 无可用 Python（仅 WindowsApps 占位符）、无 uv、无 node/git
- winget 可用
- PowerShell 执行策略禁用脚本（封装脚本与运行命令需注意：RunCommand 走 toolhost，项目脚本用 `powershell -ExecutionPolicy Bypass -File` 方式避免受限）

## 5. 网络/代理设计（中国大陆）

- Python HTTP 客户端默认不读 Windows"系统代理" → 必须在进程环境变量注入代理
- `config.json`（项目根）：`proxy.enabled`、`proxy.auto_from_registry`（默认 true）、`proxy.url`（手动覆盖，如 `http://127.0.0.1:7890`）、`model`（默认 `pro`）
- 封装脚本 **`g.ps1`**（唯一对外入口）：
  1. 读取代理设置（注册表自动探测或 config 覆盖）
  2. 进程级设置 `HTTP_PROXY` / `HTTPS_PROXY`
  3. 透传参数调用 `gemcli`
- Chrome 自身走系统代理，无需处理
- 手动模式备用脚本：`g-manual.ps1`（提示用户临时粘贴代理 URL）— 仅在自动探测失效时使用（可选，YAGNI 暂不建，写入 README 排障）

## 6. 项目结构

```
e:\TRAE SOLO\View_Skill\
├── config.json            # 代理/模型默认配置
├── g.ps1                  # 统一入口：设代理后调用 gemcli（skill 调用它）
├── setup.ps1              # 首次安装向导：装 uv/Chrome、装 gemini-web-mcp-cli、登录引导
├── README.md              # 安装/登录/风控/排障说明
└── docs/superpowers/specs/2026-09-06-gemini-vision-channel-design.md
```

TRAE Skill 安装到 `C:\Users\123\.trae\skills\gemini-vision\`（含 `SKILL.md`）。

## 7. 首次安装与认证流程（用户配合 ~1-2 分钟）

1. 我执行 `setup.ps1` 各步骤：
   - `winget install` uv → 刷新 PATH
   - `uv tool install gemini-web-mcp-cli`
   - `winget install` Google Chrome
2. `gemcli login`（CDP 自动打开 Chrome 至 gemini.google.com）
3. **用户手动完成 Google 账号登录**（密码对代理不可见）
4. 我验证：`gemcli login --check` + `gemcli doctor` + 一次真实 `chat` 冒烟

## 8. 数据流

```
用户贴报错截图/问图
   → TRAE 代理识别到需视觉 → 按 gemini-vision SKILL
   → 运行 g.ps1 chat "<问题>" -f <图片路径> -m pro
   → 注入代理 → gemcli → Gemini 网页 RPC（上传图片）→ 文本回答
   → 代理将结果带回主对话，由主模型整合处理
```

## 9. 风控与纪律

- 仅低频个人使用（发报错截图、少量问答）；禁止批量/并发/爬取式调用
- 账号价值较高（含 Google 数据/订阅）——如遇临时风控验证，停止并人工在浏览器确认
- 工具属"教育用途、自担风险"；本规格已向用户明示

## 10. Skill 内容要点（SKILL.md）

- 触发条件：用户提供/引用图片需要识别（报错截图、UI 截图等）或需要文本备用问答且主模型不适合
- 调用方式：`powershell -ExecutionPolicy Bypass -File g.ps1 chat "<question>" -f "<image>" -m pro`（或纯文本不带 `-f`）
- 前置检查：首次先 `gemcli login --check`，失败引导 `gemcli login`
- 排障：`gemcli doctor`；代理失效 → 检查 config.json 与系统代理
- 纪律：低频；大图先压缩/裁剪（可选说明）；回答后回到主模型流程

## 11. 验证与交付

- 冒烟：文本问答 1 次
- 真实验证：用户提供一张真实报错截图识图 1 次
- 交付清单：项目文件 + 已登录会话 + `gemini-vision` Skill（经 Skill 加载验证可用）
