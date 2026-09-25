# Obsidian ヴォールトをハブと同期する。タスクスケジューラから呼ばれる。
# ハブに到達できない場合は異常ではないため、記録だけして正常終了する。
$ErrorActionPreference = 'Continue'

$Vault = $env:ES_OBSIDIAN_VAULT
if (-not $Vault) {
    $Vault = 'C:\Users\100508\OneDrive\OneDrive - 株式会社いい生活\Work\es-obsidian'
}

$StateDir  = Join-Path $env:LOCALAPPDATA 'vault-sync'
$StateFile = Join-Path $StateDir 'state.json'
$LogFile   = Join-Path $StateDir 'sync.log'
$LockFile  = Join-Path $StateDir 'sync.lock'
$SshExe    = 'C:/Windows/System32/OpenSSH/ssh.exe'

# 一度の同期で許容する削除の上限。通常のノート整理で一度に消す件数（数件）を上回り、
# かつ OneDrive のプレースホルダ化・ヴォールトのマウント外れといった同期障害による
# 大量消失は確実に捕まえられる水準として 10 を採る。
$MaxDeletions = 10

# ハブ到達確認の ssh を打ち切るまでの壁時計時間（ミリ秒）。
# 5 分間隔の実行サイクルに対して十分短く、正常時の応答（1 秒未満）に対して十分長い。
$SshProbeTimeoutMs = 30000

if (-not (Test-Path $StateDir)) {
    New-Item -ItemType Directory -Force -Path $StateDir | Out-Null
}

function Write-SyncLog($Message) {
    '{0} {1}' -f (Get-Date -Format o), $Message | Add-Content -Path $LogFile -Encoding utf8
}

# 定期実行のタスクスケジューラと、end-work / organize-slack-later /
# vault-sync-resolve がスキル経由で実行する git 操作は同じ作業ツリーを触る。
# 排他しないと index.lock で衝突し、偽の競合や無音の失敗になる。
# FileShare::None で開いたハンドルはプロセス終了時に解放されるため後片付けは不要。
#
# ロックを取得できなかった場合は状態ファイルに一切書かないこと。
# unreachable を書けば check-state が誤って警告し、ok を書けば鮮度チェックを欺く。
# ロック待ちは異常ではなく「今回は別の実行に任せる」だけなので、ログにのみ残す。
try {
    $lockStream = [System.IO.File]::Open(
        $LockFile,
        [System.IO.FileMode]::OpenOrCreate,
        [System.IO.FileAccess]::ReadWrite,
        [System.IO.FileShare]::None)
} catch {
    Write-SyncLog 'skip: another sync holds the lock'
    exit 0
}

function Get-SyncState {
    if (Test-Path $StateFile) {
        try { return Get-Content $StateFile -Raw -Encoding utf8 | ConvertFrom-Json } catch { return $null }
    }
    return $null
}

function Set-SyncState($Status, $LastSuccess, $Detail) {
    # since は「その状態になった時刻」である。status と detail が前回と同じなら
    # 状態は変わっていないので前回値を持ち越す。毎回 now を書くと since は
    # スケジューラが回っている限り常に 5 分以内になり、check-state の
    # 「hub not reachable が 72 時間続いている」ゲートが実運用で発火しなくなる。
    # detail まで比較に入れるのは、'aborted: <N> deletions staged' の N が変われば
    # 状況が変わったということなので since が更新されてよいためである。
    $since = Get-Date -Format o
    if ($script:prevSince -and $Status -eq $script:prevStatus -and $Detail -eq $script:prevDetail) {
        $since = $script:prevSince
    }
    # 読み手（check-state.ps1、vault-sync-resolve スキル）が書き込み途中の
    # 不完全な JSON を観測しないよう、同一ディレクトリ内の一時ファイルに書いてから
    # Move-Item -Force で置き換える（アトミック書き込み）。
    $tmp = Join-Path $StateDir ('state.json.tmp.' + [System.Diagnostics.Process]::GetCurrentProcess().Id)
    [pscustomobject]@{
        status      = $Status
        since       = $since
        lastSuccess = $LastSuccess
        detail      = $Detail
        logPath     = $LogFile
    } | ConvertTo-Json | Set-Content -Path $tmp -Encoding utf8
    Move-Item -Path $tmp -Destination $StateFile -Force
}

function Get-NormalizedPath($Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return '' }
    try { return ([System.IO.Path]::GetFullPath($Path)).TrimEnd('\', '/') } catch { return '' }
}

$prev = Get-SyncState
# ConvertFrom-Json は ISO8601 文字列を [datetime] に強制するため、
# 書き戻す際はロケール依存の既定書式ではなく ISO8601 に揃え直す。
$lastSuccess = ''
if ($prev -and $prev.lastSuccess) {
    $lastSuccess = if ($prev.lastSuccess -is [datetime]) { $prev.lastSuccess.ToString('o') } else { [string]$prev.lastSuccess }
}

# since の持ち越し判定に使う前回値。Set-SyncState から $script: スコープで参照する。
# $prev.since も ConvertFrom-Json により [datetime] になっているため、
# lastSuccess と同じ .ToString('o') を通す。これを怠るとファイルには
# '09/11/2026 22:37:41' というロケール形式で書かれ、D-3 で直した問題が再発する
# （check-state の Get-HoursSince は InvariantCulture 解析なのでこの機では偶然
# 通ってしまい、壊れていることに気づきにくい）。
$prevStatus = if ($prev -and $prev.status) { [string]$prev.status } else { '' }
$prevDetail = if ($prev -and $prev.detail) { [string]$prev.detail } else { '' }
$prevSince = ''
if ($prev -and $prev.since) {
    $prevSince = if ($prev.since -is [datetime]) { $prev.since.ToString('o') } else { [string]$prev.since }
}

if ($prev -and $prev.status -eq 'conflict') {
    Write-SyncLog 'skip: conflict unresolved'
    exit 0
}

# ハブへの到達確認。
#
# タスクスケジューラから実行するとこの ssh が戻らなくなる事象がある（実測: 数分間
# プロセスが生存し、状態ファイルもログも一切書かれないままタスクが「実行中」で滞留する）。
# 5 分間隔なので、放置するとハングしたプロセスが積み上がる。
#
# 実測で分かっていること:
#   - タスクのコンテキストからでも ssh-agent には到達できている（ssh-add -l が成功する）。
#     「スケジューラから agent に届かない」という当初の想定は誤りだった
#   - stdin を明示的に閉じた Process.Start では約 400ms で成功する
# 根本原因は特定できていない。以下は原因が何であれ無害化するための措置である。
#
#   1. -n を付けて stdin を読まないことを明示する（無人実行での正しい指定であり、
#      原因が stdin 側にあるなら直接効く）
#   2. stdin をリダイレクトして閉じる
#   3. 壁時計 30 秒で打ち切る。& による直接呼び出しでは打ち切れないため Process.Start を使う
#
# ConnectTimeout は TCP 接続までしか縛らず、その先で止まると無制限に待つため、
# このハードタイムアウトの代わりにはならない。
#
# 打ち切った場合の detail は 'hub not reachable' と区別する。前者は機械的な不具合で
# 人が見る必要があり、check-state 側で即座に警告される。後者（LAN 外にいる等の
# 正常な不達）は鮮度 72 時間のゲートに載る。
$sshArgs = @(
    '-o', 'BatchMode=yes',
    '-o', 'ConnectTimeout=5',
    '-o', 'ControlMaster=no',
    '-o', 'ControlPath=none',
    '-x', '-T', '-n', 'm', 'true')
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $SshExe
foreach ($a in $sshArgs) { [void]$psi.ArgumentList.Add($a) }
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$sshProc = [System.Diagnostics.Process]::Start($psi)
$sshProc.StandardInput.Close()
if (-not $sshProc.WaitForExit($SshProbeTimeoutMs)) {
    try { $sshProc.Kill($true) } catch { }
    $detail = 'reachability probe timed out ({0}s)' -f [int]($SshProbeTimeoutMs / 1000)
    Set-SyncState 'unreachable' $lastSuccess $detail
    Write-SyncLog $detail
    exit 0
}
if ($sshProc.ExitCode -ne 0) {
    Set-SyncState 'unreachable' $lastSuccess 'hub not reachable'
    Write-SyncLog 'unreachable'
    exit 0
}

try {
    Set-Location -Path $Vault -ErrorAction Stop
} catch {
    Set-SyncState 'unreachable' $lastSuccess ('vault not found: ' + $Vault)
    Write-SyncLog ('vault not found: ' + $Vault)
    exit 0
}

# core.sshCommand がヴォールトリポジトリに設定済みで、これが唯一の真実である。
# $env:GIT_SSH_COMMAND をここで設定すると core.sshCommand より優先されてしまい、
# ControlMaster=no 等のオプションが失われて push が失敗するため設定しない。

# ES_OBSIDIAN_VAULT が別のリポジトリ（あるいはその配下）を指していると、
# このスクリプトは実行のたびにそのリポジトリを自動 commit & push する装置になる。
# 作業ツリーのルートがヴォールト自身であることを git に確認させる。
$toplevel = (git rev-parse --show-toplevel 2>$null)
if ((Get-NormalizedPath $toplevel) -ine (Get-NormalizedPath $PWD.ProviderPath)) {
    $actual = if ($toplevel) { $toplevel } else { 'unknown' }
    Set-SyncState 'unreachable' $lastSuccess ('not the vault repository: ' + $actual)
    Write-SyncLog ('not the vault repository: ' + $actual)
    exit 0
}

git add -A
if ($LASTEXITCODE -ne 0) {
    Set-SyncState 'unreachable' $lastSuccess 'git add failed'
    Write-SyncLog 'git add failed'
    exit 0
}

# git add -A は削除も無条件にステージする。作業ツリーからノートが消えていれば
# そのまま commit・push され、もう一方の機も次の pull で消す。両系統が同時に失われる。
# 閾値を超えたら commit せず中断し、ステージだけ戻して作業ツリーはそのまま残す。
# 件数を取れなかった場合はフェイルクローズする。配列版には bash の
# 「空文字が構文エラーになる」弱点は無いが、git 自体が失敗して無出力で終わると
# Count が 0 になり、削除が 1 件も無いのと区別が付かないままガードを通過する。
# 守っている資産が実ノートなので、取れなかったときは commit に進ませない。
$deleted = @(git diff --cached --diff-filter=D --name-only)
$countRc = $LASTEXITCODE
if ($countRc -ne 0) {
    git reset -q
    $detail = 'aborted: deletion count unavailable, manual review required'
    Set-SyncState 'unreachable' $lastSuccess $detail
    Write-SyncLog $detail
    exit 0
}
if ($deleted.Count -gt $MaxDeletions) {
    git reset -q
    $detail = 'aborted: {0} deletions staged, manual review required' -f $deleted.Count
    Set-SyncState 'unreachable' $lastSuccess $detail
    Write-SyncLog $detail
    exit 0
}

git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    git commit -q -m ('sync({0}): {1}' -f $env:COMPUTERNAME, (Get-Date -Format o))
    if ($LASTEXITCODE -ne 0) {
        Set-SyncState 'unreachable' $lastSuccess ('git commit failed: ' + $LASTEXITCODE)
        Write-SyncLog 'git commit failed'
        exit 0
    }
}

git pull --rebase -q
$pullExit = $LASTEXITCODE
if ($pullExit -ne 0) {
    # pull の失敗は競合とは限らない。作業ツリーが汚れている・ハブが途中で落ちる・
    # hook が失敗する、いずれも競合ではない。これらを conflict として記録すると
    # 以後の実行が conflict スキップに入り、競合が無いまま同期が恒久停止する。
    # 競合ファイルの取得は rebase --abort より前に行う必要がある。
    $conflicted = @(git diff --name-only --diff-filter=U)
    git rebase --abort 2>$null
    if ($conflicted.Count -eq 0) {
        $detail = 'pull failed (not a conflict): {0}' -f $pullExit
        Set-SyncState 'unreachable' $lastSuccess $detail
        Write-SyncLog $detail
    } else {
        $detail = 'rebase conflict: ' + ($conflicted -join ' ')
        Set-SyncState 'conflict' $lastSuccess $detail
        Write-SyncLog ('conflict: ' + ($conflicted -join ' '))
    }
    exit 0
}

git push -q
if ($LASTEXITCODE -ne 0) {
    Set-SyncState 'unreachable' $lastSuccess 'push failed'
    Write-SyncLog 'push failed'
    exit 0
}

Set-SyncState 'ok' (Get-Date -Format o) ''
Write-SyncLog 'ok'
exit 0
