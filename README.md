# VibeCoding Rules

`VibeCoding Rules` 是一个面向 Codex 和 Claude Code 的用户显式调用型 Skill。它把统一的软件开发治理规则安装到指定工程根目录，要求编码 Agent 以 SDD、TDD、需求追溯、证据验证和严格作用域为依据工作，减少模型自行假设、擅自扩展、过度设计、修改无关内容和把未验证结果当成交付的情况。

> 本 Skill 只用于 Vibe Coding 软件开发工程。纯文档、调研、方案、图片、演示文稿、表格、邮件、知识库、文件整理等不编写、不修改、不构建且不测试软件代码的项目不需要安装。

## 它会安装什么

核心治理文件位于 [`assets/AGENTS.md`](./assets/AGENTS.md)。在 Codex 模式下，Skill 只把它安装为目标工程根目录的 `AGENTS.md`。在 Claude Code 模式下，Skill 还会创建或确认根目录 `CLAUDE.md` 中存在独立的 `@AGENTS.md` 导入行，因为 Claude Code 原生读取 `CLAUDE.md`，而不是直接读取 `AGENTS.md`。选择双工具模式后，同一份规则会同时供 Codex 和 Claude Code 使用，避免维护两套内容。

治理文件规定：工程行为必须由用户要求、SDD、TDD 和当前证据驱动；缺少 SDD 或 TDD 时必须先辅助建立；功能增加、行为修改和 Bug 修复必须同步更新 SDD 与 TDD；实现、测试和交付汇报必须引用准确的 SDD/TDD 条款；模型假设必须显式披露；困惑和冲突不得静默猜测；子工程只能在有明确边界证据时建立；Git 必须保护上级、下级和兄弟仓库；完成汇报必须区分已观察、已修改、已验证和未验证状态。

## 治理思想来源

本项目的 [`AGENTS.md`](./assets/AGENTS.md) 也参考了 Andrej Karpathy 对 Vibe Coding 与 LLM Coding 问题的总结和治理方向，重点吸收了显式暴露假设、主动管理模型困惑、拒绝无依据迎合、避免过度设计、优先简单且可验证的实现、限制无关修改、保留人类对产品与架构决策权等原则。仓库中的规则是对这些方向进行的工程化和可执行化表达，不是对 Karpathy 原文的逐字复制，也不表示其对本项目的认可或背书。相关原始讨论见 [Andrej Karpathy 的公开说明](https://x.com/karpathy/status/2015883857489522876)。

## 安装 Skill

### Codex

Codex 的用户级 Skill 目录是 `~/.agents/skills`。执行：

```bash
mkdir -p ~/.agents/skills
git clone https://github.com/HerbertWYT/VibeCoding-Rules.git \
  ~/.agents/skills/vibe-coding-agents
```

安装后在 Codex 中使用 `$vibe-coding-agents`。Codex 通常可以发现新安装的 Skill；如果选择器中没有出现，重新启动 Codex。

### Claude Code

Claude Code 的用户级 Skill 目录是 `~/.claude/skills`。执行：

```bash
mkdir -p ~/.claude/skills
git clone https://github.com/HerbertWYT/VibeCoding-Rules.git \
  ~/.claude/skills/vibe-coding-agents
```

安装后在 Claude Code 中使用 `/vibe-coding-agents`。如果 `~/.claude/skills` 是在当前 Claude Code 会话启动后首次创建的顶层目录，请重新启动 Claude Code，使其开始监听该目录。

### 同时支持 Codex 和 Claude Code

需要在两个工具中调用时，分别安装到两个用户级 Skill 目录：

```bash
mkdir -p ~/.agents/skills ~/.claude/skills
git clone https://github.com/HerbertWYT/VibeCoding-Rules.git \
  ~/.agents/skills/vibe-coding-agents
git clone https://github.com/HerbertWYT/VibeCoding-Rules.git \
  ~/.claude/skills/vibe-coding-agents
```

## 怎么调用

在 Codex 中：

```text
$vibe-coding-agents
这是一个 Vibe Coding 软件开发工程。
请把约束安装到 /absolute/path/to/project，使用 Codex 模式。
```

在 Claude Code 中：

```text
/vibe-coding-agents
这是一个 Vibe Coding 软件开发工程。
请把约束安装到 /absolute/path/to/project，使用 Claude Code 模式。
```

同一工程同时使用两个工具时：

```text
$vibe-coding-agents
这是一个 Vibe Coding 软件开发工程。
请把约束安装到 /absolute/path/to/project，同时支持 Codex 和 Claude Code。
```

目标目录必须是已经存在的绝对路径。Skill 不会搜索磁盘，也不会根据相似名称猜测工程。

## 文件冲突如何处理

目标工程没有 `AGENTS.md` 时，Skill 自动创建；内容已经一致时保持不变；存在不同内容时停止，不会静默覆盖。只有用户明确说“允许覆盖现有 `AGENTS.md`”后，Skill 才会替换它。

Claude Code 模式下，如果 `CLAUDE.md` 不存在，Skill 创建只含 `@AGENTS.md` 的桥接文件；如果已经存在该导入或已经是指向 `AGENTS.md` 的符号链接，则保持不变；如果已有其他 `CLAUDE.md` 内容但没有导入，Skill 会停止。只有用户明确说“保留现有 `CLAUDE.md` 内容并追加 `@AGENTS.md`”后，Skill 才会追加导入，不会覆盖原有 Claude Code 规则。

## 直接运行安装脚本

通常应通过 Skill 调用。需要直接运行时，Codex 模式使用：

```bash
bash ./scripts/install-agents.sh \
  --project-dir "/absolute/path/to/project" \
  --confirm-vibe-coding \
  --coding-agent codex
```

Claude Code 模式使用：

```bash
bash ./scripts/install-agents.sh \
  --project-dir "/absolute/path/to/project" \
  --confirm-vibe-coding \
  --coding-agent claude-code
```

双工具模式使用：

```bash
bash ./scripts/install-agents.sh \
  --project-dir "/absolute/path/to/project" \
  --confirm-vibe-coding \
  --coding-agent both
```

明确允许替换不同的 `AGENTS.md` 时增加 `--replace-existing`。明确允许保留现有 `CLAUDE.md` 并追加导入时增加 `--add-claude-import`。

## 安装边界

安装脚本只处理指定工程根目录中的 `AGENTS.md`，以及 Claude Code 或双工具模式所需的 `CLAUDE.md` 导入桥接。它不会扫描工程、运行 Git、初始化仓库、创建分支、暂存、提交、推送、修改 SDD/TDD、修改代码或操作其他项目。Skill 被设置为仅用户显式调用，Codex 和 Claude Code 均不应自行触发安装。

`AGENTS.md` 与 `CLAUDE.md` 属于模型指令治理层，能够显著提高行为一致性，但不等同于操作系统安全隔离。必须强制阻断的命令、目录或联网行为，还应使用 Codex/Claude Code 的权限、沙箱、Hooks 和 CI 策略执行技术控制。

## 仓库结构

```text
VibeCoding-Rules/
├── README.md
├── SKILL.md
├── agents/
│   └── openai.yaml
├── assets/
│   └── AGENTS.md
└── scripts/
    └── install-agents.sh
```

`SKILL.md` 定义适用场景、禁止场景和安装流程；`assets/AGENTS.md` 是实际写入软件工程的治理规则；`scripts/install-agents.sh` 提供可重复、可验证且冲突安全的安装行为；`agents/openai.yaml` 关闭 Codex 隐式调用并提供 Skill 界面信息。

## 官方机制参考

Codex 的 `AGENTS.md` 发现机制与 Skill 目录说明见 [OpenAI：Custom instructions with AGENTS.md](https://developers.openai.com/codex/guides/agents-md) 和 [OpenAI：Build skills](https://developers.openai.com/codex/skills)。

Claude Code 的 Skill 目录、显式调用控制以及 `CLAUDE.md` 导入 `AGENTS.md` 的方式见 [Anthropic：Extend Claude with skills](https://code.claude.com/docs/en/slash-commands) 和 [Anthropic：How Claude remembers your project](https://code.claude.com/docs/en/memory#agentsmd)。
