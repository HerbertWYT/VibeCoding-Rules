---
name: vibe-coding-agents
description: 为使用 Codex 或 Claude Code 的 Vibe Coding 软件开发工程安装严格的 AGENTS.md 治理文件，并在 Claude Code 模式下建立 CLAUDE.md 导入桥接。仅当用户明确调用本 Skill，或明确要求为会编写、修改、构建、测试软件代码的 Vibe Coding 工程安装开发约束时使用。纯文档、调研、设计、图片、表格、邮件、知识管理、文件整理等非编码项目不得使用。
disable-model-invocation: true
---

# Vibe Coding AGENTS 安装

## 适用边界

本 Skill 只适用于由 Codex 或 Claude Code 实际编写、修改、构建或测试软件代码的 Vibe Coding 工程。用户在 Codex 中明确调用 `$vibe-coding-agents`，或在 Claude Code 中明确调用 `/vibe-coding-agents`，并且当前任务已经明确是软件开发工程时，视为同意把本 Skill 内置的治理文件安装到用户指定的工程根目录。

纯文档编写、资料调研、方案策划、视觉设计、图片生成、演示文稿、电子表格、邮件、知识库、普通文件整理和其他不产生软件代码的项目不适用本 Skill。调用场景无法判断是否涉及编码时，MUST NOT 安装文件，必须先向用户说明：“这个约束 Skill 只用于 Vibe Coding 软件开发工程；请确认该目录是否会由 AI 编写、修改、构建或测试软件代码。”错误地把开发治理文件放入非编码项目会污染项目指令，因此属于禁止行为。

## 目标目录

目标必须是用户明确提供的工程根目录，或当前任务上下文中唯一且明确的工程根目录。目标不明确时 MUST 询问准确目录，MUST NOT 搜索磁盘、猜测相似工程、选择父目录、选择子目录或操作其他项目。路径必须是已经存在的绝对目录。

## 安装行为

确认适用场景和目标目录后，MUST 根据实际使用工具选择安装模式。在 Codex 中调用时使用 `codex`：

```bash
bash <skill-directory>/scripts/install-agents.sh \
  --project-dir "/absolute/path/to/project" \
  --confirm-vibe-coding \
  --coding-agent codex
```

在 Claude Code 中调用时使用 `claude-code`。该模式安装 `AGENTS.md`，并创建引用它的 `CLAUDE.md`：

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/install-agents.sh" \
  --project-dir "/absolute/path/to/project" \
  --confirm-vibe-coding \
  --coding-agent claude-code
```

用户明确要求同一工程同时支持 Codex 和 Claude Code 时使用 `both`：

```bash
bash <skill-directory>/scripts/install-agents.sh \
  --project-dir "/absolute/path/to/project" \
  --confirm-vibe-coding \
  --coding-agent both
```

目标 `AGENTS.md` 不存在时自动安装，与内置版本一致时保持不变，已经存在且内容不同时必须停止。Agent 必须告知用户存在冲突，未经用户明确同意不得覆盖。用户明确要求覆盖该文件后，才允许增加 `--replace-existing`：

```bash
bash <skill-directory>/scripts/install-agents.sh \
  --project-dir "/absolute/path/to/project" \
  --confirm-vibe-coding \
  --coding-agent codex \
  --replace-existing
```

Claude Code 模式下，`CLAUDE.md` 不存在时只写入 `@AGENTS.md`，已经包含该独立导入行或已经是指向 `AGENTS.md` 的符号链接时保持不变。已有 `CLAUDE.md` 但未导入 `AGENTS.md` 时必须停止，未经用户明确同意不得追加。用户明确同意保留原内容并增加导入后，才允许增加 `--add-claude-import`。不得自动覆盖已有 `CLAUDE.md`。

不得因为安装治理文件而读取或扫描工程内容，不得运行 Git 命令，不得初始化仓库、创建分支、暂存或提交，不得修改 SDD、TDD、代码、配置或其他工程文件。Codex 模式只能处理 `AGENTS.md`；Claude Code 或双工具模式只能额外处理根目录 `CLAUDE.md` 的导入桥接。违反该边界会使治理文件安装扩大成未授权的工程操作。

## 完成证据

脚本必须用逐字节比较确认目标 `AGENTS.md` 与内置 `assets/AGENTS.md` 完全一致，并在 Claude Code 或双工具模式下确认 `CLAUDE.md` 已有效导入 `AGENTS.md`。Agent 的完成汇报只说明适用性判断、准确目标路径、所选编码工具、两个文件各自的安装状态和一致性验证结果，不得附带未获授权的工程诊断、Git 检查或后续开发建议。
