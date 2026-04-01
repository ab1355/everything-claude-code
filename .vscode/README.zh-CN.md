# Everything Claude Code for VS Code

为 VS Code 的 Claude Code 扩展带来 Everything Claude Code (ECC) 工作流。此仓库提供自定义命令、智能体、技能和规则，可以通过单个命令安装到任何 VS Code 项目中。

## 快速开始

```bash
# 安装到当前项目
.vscode/install.sh

# 全局安装到 ~/.vscode/
.vscode/install.sh ~
```

安装程序使用非破坏性复制 — 不会覆盖您现有的文件。

## 包含内容

### 命令

命令是可通过 Claude Code 面板中 `/` 菜单调用的按需工作流。所有命令直接从项目根目录的 `commands/` 文件夹复用。

### 智能体

智能体是具有特定工具配置的专业 AI 助手。所有智能体直接从项目根目录的 `agents/` 文件夹复用。

### 技能

技能是可通过聊天中 `/` 菜单调用的按需工作流。所有技能直接从项目的 `skills/` 文件夹复用。

### 规则

规则提供始终有效的上下文，塑造智能体处理代码的方式。所有规则直接从项目根目录的 `rules/` 文件夹复用。

### VS Code 设置

安装程序创建包含推荐设置的 `.vscode/settings.json`：

- `editor.formatOnSave` — 保存时自动格式化文件
- `files.trimTrailingWhitespace` — 保持文件整洁
- `claude.agentsFile` — 指向项目根目录中的 `AGENTS.md` 文件

### 推荐扩展

安装程序创建 `.vscode/extensions.json`，推荐 Claude Code 扩展（`anthropic.claude-code`）。

## 卸载

卸载程序使用清单文件（`.ecc-manifest`）跟踪已安装的文件，确保安全删除：

```bash
.vscode/uninstall.sh
```

## 项目结构

```
.vscode/
├── settings.json       # VS Code 工作区设置
├── extensions.json     # 推荐扩展
├── install.sh          # 安装脚本
├── uninstall.sh        # 卸载脚本
└── README.md           # 本文件

commands/               # 命令文件（从项目根目录复用）
agents/                 # 智能体文件（从项目根目录复用）
skills/                 # 技能文件（从 skills/ 复用）
rules/                  # 规则文件（从项目根目录复用）
AGENTS.md               # 智能体描述（由 Claude Code 扩展读取）
```

## 使用方法

1. 在 VS Code 中打开您的项目
2. 打开 Claude Code 面板（点击侧边栏中的 Claude 图标）
3. 输入 `/` 查看可用命令
4. 选择命令或技能以调用它
5. 智能体将引导您完成工作流程

## 推荐工作流程

1. **从规划开始**：使用 `/plan` 命令分解复杂功能
2. **先写测试**：在实现之前调用 `/tdd` 命令
3. **审查代码**：编写代码后使用 `/code-review`
4. **检查安全**：对认证、API 端点或敏感数据使用 `/code-review`
5. **修复构建错误**：如果有构建错误，使用 `/build-fix`
