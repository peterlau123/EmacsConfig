;;; init.el --- Emacs 配置文件
;;; -*- coding: utf-8 -*-
;;; Commentary:
;;  文档处理 + 会议纪要 + LLM集成

;;; Code:

;; ============================================
;; 基础配置
;; ============================================

(set-language-environment 'Chinese-GB)
(set-default-coding-systems 'utf-8)
(prefer-coding-system 'utf-8)

;; Emoji 字体支持（使用 Windows 内置 Segoe UI Emoji）
(when (display-graphic-p)
  (set-fontset-font "fontset-default" 'unicode
                    (font-spec :family "Segoe UI Emoji")
                    nil 'prepend))

;; 补充缺失的 static-when/static-if 宏（兼容旧版 compat）
;; 这些宏在 Emacs 30.1+ 中由 C 实现，这里提供 Elisp 替代
(unless (fboundp 'static-when)
  (defmacro static-when (cond &rest body)
    "静态条件：COND 为真时展开 BODY。"
    (declare (indent 1) (debug (form body)))
    (if (eval cond t)
        (macroexp-progn body))))

(unless (fboundp 'static-if)
  (defmacro static-if (cond then &rest else)
    "静态条件判断。"
    (declare (indent 2) (debug (form form body)))
    (if (eval cond t)
        then
      (macroexp-progn else))))

;; ============================================
;; 变量定义
;; ============================================

(defvar my/meeting-dir "C:/Users/admin/Downloads/docs/会议记录/"
  "会议纪要存储目录。")

(defvar my/theme-list '(modus-vivendi modus-operandi leuven tango-dark tango)
  "可用主题列表。")

(defvar my/theme-index 0
  "当前主题索引。")

;; ============================================
;; 包管理
;; ============================================

(require 'package)
;; 使用清华镜像源
(add-to-list 'package-archives '("gnu"    . "https://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/") t)
(add-to-list 'package-archives '("nongnu" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/nongnu/") t)
(add-to-list 'package-archives '("melpa"  . "https://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/") t)
(package-initialize)

(defun my/ensure-package (pkg)
  "确保包 PKG 已安装。"
  (unless (package-installed-p pkg)
    (package-refresh-contents)
    (package-install pkg)))

;; 安装必要包
(my/ensure-package 'gptel)
(my/ensure-package 'pdf-tools)     ; PDF 查看
(my/ensure-package 'which-key)     ; 快捷键提示
(my/ensure-package 'avy)           ; 快速跳转
(my/ensure-package 'company)       ; 自动补全
(my/ensure-package 'magit)         ; Git 管理
(my/ensure-package 'undo-tree)     ; 可视化撤销

;; ============================================
;; LLM 配置（阿里云通义千问）
;; ============================================

;; API Key：从环境变量读取
;; 设置方式：Windows CMD: set DASHSCOPE_API_KEY=xxx
;;          PowerShell: $env:DASHSCOPE_API_KEY="xxx"
(defvar my/dashscope-api-key (or (getenv "DASHSCOPE_API_KEY") "your-api-key-here")
  "阿里云 DashScope API Key。")

;; 配置阿里云 Anthropic 兼容端点
;; 端点：https://coding.dashscope.aliyuncs.com/v1
(gptel-make-anthropic "阿里云Coding"
  :host "coding.dashscope.aliyuncs.com"
  :protocol "https"
  :endpoint "/v1"
  :stream t
  :key 'my/dashscope-api-key
  :header (lambda (_info)
            (when-let* ((key (gptel--get-api-key)))
              `(("Authorization" . ,(concat "Bearer " key))
                ("Content-Type" . "application/json"))))
  :models '((glm-5
             :description "智谱 GLM-5"
             :capabilities (tool-use)
             :context-window 128)
            (kimi-2.5
             :description "Moonshot Kimi 2.5"
             :capabilities (tool-use)
             :context-window 128)))

;; 设置默认模型
(setq gptel-model 'glm-5)

;; ============================================
;; 文档处理功能
;; ============================================

(defun my/doc-summary ()
  "总结当前文档或选中内容。"
  (interactive)
  (let* ((content (if (use-region-p)
                      (buffer-substring (region-beginning) (region-end))
                    (buffer-substring (point-min) (point-max))))
         (buf (get-buffer-create "*文档总结*")))
    (with-current-buffer buf
      (erase-buffer)
      (insert "# 文档总结\n\n正在生成...\n")
      (display-buffer buf))
    (gptel-request
     content
     :system "你是文档分析专家。请用简洁的中文总结以下文档的核心内容，包括：1)主要观点 2)关键结论 3)重要数据（如有）。控制在200字以内。"
     :callback
     (lambda (response)
       (with-current-buffer buf
         (erase-buffer)
         (insert "# 文档总结\n\n")
         (insert response)
         (goto-char (point-min)))))))

(defun my/doc-polish ()
  "润色选中的文本。"
  (interactive)
  (if (not (use-region-p))
      (message "请先选中要润色的文本")
    (let* ((content (buffer-substring (region-beginning) (region-end)))
           (start (region-beginning))
           (end (region-end)))
      (gptel-request
       content
       :system "你是文字润色专家。请优化以下中文文本：1)修正语法错误 2)提升表达流畅度 3)保持原意不变。直接输出润色后的文本，不要解释。"
       :callback
       (lambda (response)
         ;; 使用保存的位置，避免异步回调时 region 已失效
         (delete-region start end)
         (goto-char start)
         (insert response))))))

(defun my/doc-extract-todo ()
  "从文档中提取待办事项。"
  (interactive)
  (let ((content (buffer-substring (point-min) (point-max)))
        (buf (get-buffer-create "*待办提取*")))
    (with-current-buffer buf
      (erase-buffer)
      (insert "# 待办事项\n\n正在分析...\n")
      (display-buffer buf))
    (gptel-request
     content
     :system "从以下文档中提取所有待办事项、任务、行动计划。格式为：- [ ] 任务描述（责任人/时间）。按优先级排序。"
     :callback
     (lambda (response)
       (with-current-buffer buf
         (erase-buffer)
         (insert "# 待办事项\n\n")
         (insert response)
         (goto-char (point-min)))))))

(defun my/doc-meeting-fix ()
  "整理会议纪要格式。"
  (interactive)
  (let ((content (buffer-substring (point-min) (point-max))))
    (gptel-request
     content
     :system "你是会议纪要整理专家。请整理以下会议内容为标准格式：
# 日期 主题

## 参会人员

## 会议背景

## 讨论要点
（按重要性排序，每个要点简明扼要）

## 决议事项

- [ ] 待办：责任人、截止时间

## 后续安排

保持原有核心内容，删除冗余描述。"
     :callback
     (lambda (response)
       (erase-buffer)
       (insert response)
       (goto-char (point-min))))))

(defun my/doc-translate ()
  "翻译选中文本（自动识别中英文）。"
  (interactive)
  (if (not (use-region-p))
      (message "请先选中要翻译的文本")
    (let ((content (buffer-substring (region-beginning) (region-end))))
      (gptel-request
       content
       :system "请翻译以下文本。如果是中文翻译成英文，如果是英文翻译成中文。直接输出翻译结果，不要解释。"
       :callback
       (lambda (response)
         (let ((buf (get-buffer-create "*翻译结果*")))
           (with-current-buffer buf
             (erase-buffer)
             (insert response)
             (display-buffer buf))))))))

;; ============================================
;; 主题配置
;; ============================================

(defun my/next-theme ()
  "切换下一个主题。"
  (interactive)
  (setq my/theme-index (% (+ my/theme-index 1) (length my/theme-list)))
  (let ((theme (nth my/theme-index my/theme-list)))
    (disable-theme (car custom-enabled-themes))
    (load-theme theme t)
    (message "主题: %s" theme)))

(defun my/set-theme ()
  "选择主题。"
  (interactive)
  (let ((theme (intern (completing-read "主题: "
                                        (mapcar #'symbol-name my/theme-list)))))
    (disable-theme (car custom-enabled-themes))
    (load-theme theme t)
    (message "已切换: %s" theme)))

;; 默认主题
(load-theme 'leuven t)

;; ============================================
;; 会议纪要功能
;; ============================================

(defun my/create-meeting ()
  "创建会议纪要文件。"
  (interactive)
  (let* ((date (format-time-string "%Y-%m-%d"))
         (topic (read-string "主题: "))
         (people (read-string "人员: "))
         (file (concat my/meeting-dir date "-" topic ".md")))
    (make-directory my/meeting-dir t)
    (find-file file)
    (erase-buffer)
    (insert "# " date " " topic "\n\n")
    (insert "## 人员\n\n" people "\n\n")
    (insert "---\n\n")
    (insert "## 背景\n\n\n")
    (insert "---\n\n")
    (insert "## 要点\n\n1. \n2. \n3. \n\n")
    (insert "---\n\n")
    (insert "## 待办\n\n- [ ] \n- [ ] \n\n")
    (insert "---\n\n")
    (insert "## 后续\n\n\n")
    (goto-char (point-min))
    (search-forward "## 背景")
    (end-of-line)))

(defun my/extract-todo ()
  "从当前文件提取待办事项。"
  (interactive)
  (let (items title)
    (save-excursion
      (goto-char (point-min))
      (when (re-search-forward "^# .+ (.+)" nil t)
        (setq title (match-string 1)))
      (goto-char (point-min))
      (while (re-search-forward "- \\[ \\] (.+)" nil t)
        (push (match-string 1) items)))
    (if items
        (let ((buf (get-buffer-create "*待办*")))
          (with-current-buffer buf
            (erase-buffer)
            (insert "# " title "\n\n")
            (dolist (i items)
              (insert "- " i "\n"))
            (goto-char (point-min)))
          (display-buffer buf))
      (message "无待办"))))

(defun my/search (kw)
  "在会议目录中搜索关键词 KW。"
  (interactive "s关键词: ")
  (let (results)
    (dolist (f (directory-files my/meeting-dir t "\\.md$"))
      (unless (string-match-p "README" f)
        (with-temp-buffer
          (insert-file-contents f)
          (goto-char (point-min))
          (while (search-forward kw nil t)
            (let ((line (string-trim (thing-at-point 'line))))
              (when (> (length line) 3)
                (push (cons (file-name-base f) line) results)))))))
    (if results
        (let ((buf (get-buffer-create "*结果*")))
          (with-current-buffer buf
            (erase-buffer)
            (insert "# " kw "\n\n")
            (dolist (r results)
              (insert (car r) ": " (cdr r) "\n"))
            (goto-char (point-min)))
          (display-buffer buf))
      (message "未找到"))))

(defun my/index ()
  "生成会议纪要索引。"
  (interactive)
  (let ((file (concat my/meeting-dir "README.md")))
    (find-file file)
    (erase-buffer)
    (insert "# 索引\n\n")
    (insert (format-time-string "%Y-%m-%d") "\n\n")
    (dolist (f (directory-files my/meeting-dir nil "\\.md$"))
      (unless (string-match-p "README" f)
        (insert "- " f "\n")))
    (save-buffer)))

(defun my/export ()
  "使用 pandoc 导出当前文件为 docx。"
  (interactive)
  (if (executable-find "pandoc")
      (let ((out (concat (file-name-base (buffer-file-name)) ".docx")))
        (shell-command (concat "pandoc " (buffer-file-name) " -o " out))
        (message "导出完成: %s" out))
    (message "未找到 pandoc，请先安装")))

(defun my/reload-config ()
  "重新加载配置文件。"
  (interactive)
  (load-file (or user-init-file
                 (expand-file-name "init.el" user-emacs-directory)))
  (message "配置已重新加载"))

;; ============================================
;; 快捷键绑定
;; ============================================

;; LLM 相关
(global-set-key (kbd "C-c g") #'gptel)
(global-set-key (kbd "C-c G") #'gptel-menu)

;; 文档处理
(global-set-key (kbd "C-c d s") #'my/doc-summary)
(global-set-key (kbd "C-c d p") #'my/doc-polish)
(global-set-key (kbd "C-c d t") #'my/doc-extract-todo)
(global-set-key (kbd "C-c d m") #'my/doc-meeting-fix)
(global-set-key (kbd "C-c d T") #'my/doc-translate)

;; 主题
(global-set-key (kbd "C-c t") #'my/next-theme)
(global-set-key (kbd "C-c T") #'my/set-theme)

;; 会议纪要
(global-set-key (kbd "C-c m") #'my/create-meeting)
(global-set-key (kbd "C-c a") #'my/extract-todo)
(global-set-key (kbd "C-c s") #'my/search)
(global-set-key (kbd "C-c i") #'my/index)
(global-set-key (kbd "C-c e") #'my/export)
(global-set-key (kbd "C-c r") #'my/reload-config)

;; ============================================
;; Markdown 预览配置
;; ============================================

;; 重启后执行: M-x package-install → markdown-mode
(when (require 'markdown-mode nil t)
  (add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))
  (setq markdown-command "pandoc"))

;; 简易预览命令（无需 markdown-mode）
(defun my/md-preview ()
  "用浏览器预览当前 Markdown 文件。"
  (interactive)
  (let ((html-file (concat (file-name-sans-extension (buffer-file-name)) ".html")))
    (shell-command (concat "pandoc " (buffer-file-name) " -o " html-file " --standalone"))
    (shell-command (concat "start " html-file))))

(global-set-key (kbd "C-c p") #'my/md-preview)

;; ============================================
;; 效率插件配置
;; ============================================

;; PDF 查看（重启后安装: M-x package-install pdf-tools）
(when (require 'pdf-tools nil t)
  (pdf-tools-install)
  (setq pdf-view-display-size 'fit-page))

;; 快捷键提示（重启后安装: M-x package-install which-key）
(when (require 'which-key nil t)
  (which-key-mode 1)
  (setq which-key-idle-delay 0.5))

;; 快速跳转（已安装）
(when (require 'avy nil t)
  (global-set-key (kbd "C-'") #'avy-goto-char-timer))

;; 自动补全（重启后安装: M-x package-install company）
(when (require 'company nil t)
  (global-company-mode 1)
  (setq company-idle-delay 0.2))

;; Git 管理（重启后安装: M-x package-install magit）
(when (require 'magit nil t)
  (global-set-key (kbd "C-x g") #'magit-status))

;; 可视化撤销（重启后安装: M-x package-install undo-tree）
(when (require 'undo-tree nil t)
  (global-undo-tree-mode 1)
  (global-set-key (kbd "C-x u") #'undo-tree-visualize))

;; ============================================
;; 启动消息
;; ============================================

(message "配置加载完成")
(message "文档处理: C-c d s总结 | C-c d p润色 | C-c d t待办 | C-c d m会议整理 | C-c d T翻译")
(message "会议功能: C-c m创建 | C-c a待办 | C-c s搜索 | C-c i索引 | C-c e导出 | C-c r重载")
(message "效率插件: C-'快速跳转(avy) | C-c p预览MD")
(message "重启后安装: pdf-tools, which-key, company, magit, undo-tree (M-x package-install)")

(provide 'init)
;;; init.el ends here