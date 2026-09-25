# 一键发布 / 更新个人网站到 https://<GitHub用户名>.github.io
# 可以反复运行：每次都会复制最新 CV、提交并推送。
# 不再用 winget/安装程序：缺 git 或 gh 时，直接下载官方"免安装版"到本机用户目录，
# 不需要管理员权限，也不会弹安装界面。
$ErrorActionPreference = 'Continue'   # git/gh 会往 stderr 写进度，靠退出码判断成败
$ProgressPreference    = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Site = $PSScriptRoot
Set-Location $Site
$CvSource = 'D:\上个大学我都学了些什么\简历个人陈述推荐信\Xu_Wang_CV_2026Sep\Xu_Wang_CV.pdf'
$Tools    = Join-Path $env:LOCALAPPDATA 'MatWangSiteTools'

function Step($m) { Write-Host "`n==> $m" -ForegroundColor Cyan }
function Fail($m) { Write-Host "`n[出错] $m" -ForegroundColor Red; exit 1 }

$mutex = New-Object System.Threading.Mutex($false, 'Global\MatWangSitePublisher')
if (-not $mutex.WaitOne(0)) { Fail '已经有一个发布窗口在运行。请只保留一个窗口。' }

function Use-Dir($d) { if (Test-Path -LiteralPath $d) { $env:Path = "$d;" + $env:Path } }

# 在 PATH、常见安装位置、以及本脚本下载的免安装目录里找工具
function Find-Tool($exe, $candidates) {
  if (Get-Command $exe -ErrorAction SilentlyContinue) { return $true }
  foreach ($c in $candidates) {
    if ($c -and (Test-Path -LiteralPath $c)) { Use-Dir (Split-Path $c); return $true }
  }
  return $false
}

# 从 GitHub Releases 下载免安装 zip 并解压
function Get-PortableZip($repo, $assetPattern, $dest) {
  $rel = Invoke-RestMethod -UseBasicParsing "https://api.github.com/repos/$repo/releases/latest" -Headers @{ 'User-Agent' = 'MatWangSitePublisher' }
  $asset = $rel.assets | Where-Object { $_.name -match $assetPattern } | Select-Object -First 1
  if (-not $asset) { throw "在 $repo 的最新版本里没找到匹配 $assetPattern 的文件" }
  $zip = Join-Path $env:TEMP $asset.name
  Write-Host "下载 $($asset.name) ..."
  Invoke-WebRequest -UseBasicParsing $asset.browser_download_url -OutFile $zip
  if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
  Expand-Archive -Path $zip -DestinationPath $dest -Force
  Remove-Item $zip -Force
}

Step '检查工具'
$gitCandidates = @("$env:ProgramFiles\Git\cmd\git.exe", "${env:ProgramFiles(x86)}\Git\cmd\git.exe",
                   "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe", "$Tools\git\cmd\git.exe")
$ghCandidates  = @("$env:ProgramFiles\GitHub CLI\gh.exe", "${env:ProgramFiles(x86)}\GitHub CLI\gh.exe",
                   "$env:LOCALAPPDATA\Programs\GitHub CLI\gh.exe", "$Tools\gh\bin\gh.exe")
try {
  if (-not (Find-Tool git $gitCandidates)) {
    Step '下载 Git 免安装版（只需一次，约 40 MB）'
    Get-PortableZip 'git-for-windows/git' '^MinGit-[\d\.]+-64-bit\.zip$' "$Tools\git"
    if (-not (Find-Tool git $gitCandidates)) { throw 'Git 解压后仍找不到 git.exe' }
  }
  if (-not (Find-Tool gh $ghCandidates)) {
    Step '下载 GitHub CLI 免安装版（只需一次，约 15 MB）'
    Get-PortableZip 'cli/cli' '^gh_[\d\.]+_windows_amd64\.zip$' "$Tools\gh"
    if (-not (Find-Tool gh $ghCandidates)) { throw 'GitHub CLI 解压后仍找不到 gh.exe' }
  }
} catch {
  Fail "下载工具失败：$($_.Exception.Message)`n请检查网络（能否打开 github.com）后再双击一次。"
}
Write-Host ('git: ' + (git --version)); Write-Host ('gh : ' + ((gh --version) | Select-Object -First 1))

Step '登录 GitHub（第一次会弹出浏览器：复制窗口里的 8 位验证码，粘贴到网页，点 Authorize）'
gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
  gh auth login --hostname github.com --web --git-protocol https
  if ($LASTEXITCODE -ne 0) { Fail 'GitHub 登录没有完成。再双击一次重试。' }
}
gh auth setup-git *> $null
$Login  = ((gh api user --jq .login) | Out-String).Trim()
$UserId = ((gh api user --jq .id)    | Out-String).Trim()
if (-not $Login) { Fail '读取 GitHub 账号信息失败，请检查网络后重试。' }
$Repo = "$Login.github.io"
Write-Host "已登录：$Login"
if ($Login -ne 'MatWang') { Write-Host "注意：当前登录的不是 MatWang，网站会发布到 $Login 名下。" -ForegroundColor Yellow }

Step '复制最新的 CV'
if (Test-Path -LiteralPath $CvSource) {
  New-Item -ItemType Directory -Force -Path (Join-Path $Site 'cv') | Out-Null
  Copy-Item -LiteralPath $CvSource -Destination (Join-Path $Site 'cv\Xu_Wang_CV.pdf') -Force
  Write-Host '已从简历文件夹更新 cv\Xu_Wang_CV.pdf'
} else { Write-Host '没找到简历源文件，沿用 cv\Xu_Wang_CV.pdf。' -ForegroundColor Yellow }

Step '提交改动'
if (-not (Test-Path (Join-Path $Site '.git'))) { git init -q }
git config core.quotepath false
git config user.name  'Xu Wang'
git config user.email "$UserId+$Login@users.noreply.github.com"
git add -A
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) { git commit -q -m "Update site $(Get-Date -Format 'yyyy-MM-dd HH:mm')" } else { Write-Host '没有新的改动。' }
git branch -M main

Step '推送到 GitHub'
gh repo view "$Login/$Repo" *> $null
if ($LASTEXITCODE -ne 0) {
  gh repo create $Repo --public --description 'Personal academic website' --source . --remote origin --push
} else {
  if ((git remote) -notcontains 'origin') { git remote add origin "https://github.com/$Login/$Repo.git" }
  git push -u origin main
}
if ($LASTEXITCODE -ne 0) { Fail '推送失败，请把这个窗口截图发给 Claude。' }

Step '开启 GitHub Pages'
gh api -X POST "repos/$Login/$Repo/pages" -f 'source[branch]=main' -f 'source[path]=/' *> $null
if ($LASTEXITCODE -ne 0) { Write-Host 'Pages 已经是开启状态（或 GitHub 已自动开启）。' }

$Url = "https://$($Login.ToLower()).github.io"
Step "完成！1–2 分钟后网站上线：$Url （先看到 404 就稍等再刷新）"
Start-Process $Url
