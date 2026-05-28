# EmacsConfig ✨

> 🚀 我的个人 Emacs 配置，专注**文档处理**、**会议纪要**与 **AI 集成**！

---

## 🎯 核心功能一览

### 🤖 AI 文档处理（基于 gptel + 阿里云通义千问）

| 快捷键 | 功能 | 说明 |
|--------|------|------|
| `C-c d s` | **文档总结** 📝 | AI 自动总结当前文档或选区，输出核心观点、关键结论 |
| `C-c d p` | **文本润色** ✨ | 修正语法、提升流畅度，保持原意不变 |
| `C-c d t` | **提取待办** ✅ | 从文档中智能提取所有任务和行动计划 |
| `C-c d m` | **会议整理** 📋 | 将杂乱会议记录整理成标准格式 |
| `C-c d T` | **智能翻译** 🌐 | 自动识别中/英文，双向翻译 |

### 📅 会议纪要系统

| 快捷键 | 功能 | 说明 |
|--------|------|------|
| `C-c m` | **创建纪要** 📄 | 自动生成带日期、主题、人员、待办的模板文件 |
| `C-c a` | **提取待办** 📋 | 从纪要中提取 `- [ ]` 待办事项到新 buffer |
| `C-c s` | **搜索纪要** 🔍 | 在会议目录中全文搜索关键词 |
| `C-c i` | **生成索引** 📚 | 自动更新会议纪要 README 索引 |
| `C-c e` | **导出 Word** 📑 | 使用 pandoc 导出为 docx 格式 |

### 🎨 主题切换

| 快捷键 | 功能 |
|--------|------|
| `C-c t` | **快速切换** 🌙 循环切换主题（modus-vivendi、leuven、tango 等） |
| `C-c T` | **选择主题** 🎭 从列表中挑选喜欢的主题 |

### ⚡ 效率插件

| 快捷键 | 功能 | 插件 |
|--------|------|------|
| `C-'` | **快速跳转** 🎯 | `avy` - 输入字符即时跳转 |
| `C-c p` | **Markdown 预览** 👁️ | 使用 pandoc + 浏览器预览 |
| `C-x g` | **Git 管理** 🔧 | `magit` - 最强的 Git 界面 |
| `C-x u` | **可视化撤销** 🕰️ | `undo-tree` - 撤销历史树形展示 |

---

## 📦 安装依赖

首次使用需安装以下包（`M-x package-install`）：

```
gptel        - AI 对话（核心！）
pdf-tools    - PDF 查看
which-key    - 快捷键提示
avy          - 快速跳转
company      - 自动补全
magit        - Git 管理
undo-tree    - 可视化撤销
markdown-mode - Markdown 支持
```

---

## 🔑 配置 API Key

使用阿里云通义千问 API，需设置环境变量：

**Windows CMD:**
```cmd
set DASHSCOPE_API_KEY=your-api-key-here
```

**PowerShell:**
```powershell
$env:DASHSCOPE_API_KEY="your-api-key-here"
```

---

## 📁 文件结构

```
EmacsConfig/
├── init.el       # 主配置文件（所有功能都在这里！）
├── CLAUDE.md     # Claude Code 编码规范指南
└── README.md     # 本文档
```

---

## 🛠️ 快速上手

1. **克隆仓库** 到你的 Emacs 配置目录：
   ```bash
   git clone https://github.com/peterlau123/EmacsConfig.git
   ```

2. **复制 init.el**：
   - Windows: 复制到 `C:\Users\<用户名>\AppData\Roaming\.emacs.d\init.el`
   - Linux/Mac: 复制到 `~/.emacs.d/init.el`

3. **重启 Emacs**，会自动安装依赖包

4. **设置 API Key**（如上），然后尽情使用 AI 功能！

---

## 💡 使用技巧

- **会议纪要自动存储** 在 `C:\Users\admin\Downloads\docs\会议记录\`，可修改 `my/meeting-dir` 变量
- **Markdown 预览** 需安装 [pandoc](https://pandoc.org/)
- **`C-c r`** 快速重载配置，不用重启 Emacs！
- **`C-c g`** 打开 gptel AI 对话窗口，`C-c G` 打开菜单

---

## 📋 CLAUDE.md 说明

本仓库包含 `CLAUDE.md`，这是 Claude Code 的编码行为规范：

- **Think Before Coding** - 先思考，再编码
- **Simplicity First** - 最简代码解决问题
- **Surgical Changes** - 只改必须改的
- **Goal-Driven Execution** - 定义可验证的目标

---

## 🌟 特色亮点

✅ **中文优化** - UTF-8 编码、Emoji 字体支持、中文环境配置
✅ **清华镜像源** - 包下载速度飞起！
✅ **一键润色** - 写文档不用愁，AI 帮你优化表达
✅ **会议纪要模板** - 自动生成规范格式，告别杂乱记录
✅ **轻量配置** - 只装必要的包，启动快、不臃肿

---

## 📝 更新日志

- **2026-05** - 初始版本，整合文档处理 + 会议纪要 + AI 集成

---

## 🤝 贡献

欢迎提出建议和改进！Feel free to open issues or PRs 🎉

---

**Happy Emacs-ing! 🎹**