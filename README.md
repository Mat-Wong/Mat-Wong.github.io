# 个人网站（GitHub Pages）

## 一键发布 / 更新

**双击 `一键发布网站.bat`**，就这一步。

第一次运行时它会自动：

1. 装好 Git 和 GitHub CLI（没装的话，用 Windows 自带的 winget，只装一次）
2. 弹出浏览器让你登录 GitHub 并点"Authorize"（只需一次）
3. 创建公开仓库 `Mat-Wong.github.io`，上传网站，打开 GitHub Pages
4. 自动打开 https://mat-wong.github.io （首次上线约 1–2 分钟，刚打开是 404 就等一下再刷新）

以后改了网站或简历，**再双击一次**就更新。每次运行都会先把
`D:\上个大学我都学了些什么\简历个人陈述推荐信\Xu_Wang_CV_2026Sep\Xu_Wang_CV.pdf`
复制到 `cv\` 里，所以简历只需要在那个文件夹里改。

## 文件

- `index.html` —— 网站本体（内容取自 CV）
- `cv/Xu_Wang_CV.pdf` —— 网站上的 CV 下载链接指向这里
- `publish.ps1` —— 一键发布脚本（`.bat` 只是用来双击启动它）
- `.nojekyll` —— 告诉 GitHub 按原样发布静态文件

## 如果出问题

- 提示 winget 不存在：在 Microsoft Store 里装"应用安装程序（App Installer）"，再双击一次。
- 提示装好了但找不到 git/gh：关掉窗口再双击一次（新装的程序需要新窗口才能识别）。
- 登录的不是 MatWang 账号：脚本会提示，网站会发到你登录的那个账号下。
  在命令行运行 `gh auth logout` 后再双击，即可换号登录。
