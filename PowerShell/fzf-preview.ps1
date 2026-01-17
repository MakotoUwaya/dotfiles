<#
.SYNOPSIS
    fzf 用のプレビュースクリプト (PowerShell版) - Updated

.DESCRIPTION
    ディレクトリは eza でツリー表示し、ファイルは bat/chafa でプレビューします。
#>

param(
    [string]$Target
)

# 出力エンコーディングを UTF-8 に設定
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not $Target) {
    Write-Error "Usage: fzf-preview.ps1 TARGET"
    exit 1
}

# チルダ (~) の展開
if ($Target.StartsWith("~")) {
    $Target = $Target.Replace("~", $HOME)
}

# ---------------------------------------------------------
# 1. ディレクトリの処理 (今回の追加要件)
# ---------------------------------------------------------
if (Test-Path -LiteralPath $Target) {
    # フォルダなら eza でツリー表示（行数制限付き）
    if ((Get-Item -LiteralPath $Target) -is [System.IO.DirectoryInfo]) {
        # eza が使えるか確認
        if (Get-Command eza -ErrorAction SilentlyContinue) {
            eza -h -T -F --no-user --no-time --no-filesize --no-permissions --long $Target | Select-Object -First 200
        } else {
            # eza がない場合のフォールバック
            Get-ChildItem -LiteralPath $Target | Select-Object -First 50
        }
        exit 0
    }
}

# ---------------------------------------------------------
# 2. ファイルの処理 (既存の高度なプレビュー機能を維持)
# ---------------------------------------------------------

$file = $Target
$center = 0

# ファイルが存在しない場合、"path:line" 形式 (grep/ripgrepの結果) かどうかをチェックして分離
if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
    # Regex: パス:行番号(:無視)
    if ($file -match '^(.+):(\d+)(:\d+)?$') {
        $checkPath = $Matches[1]
        if (Test-Path -LiteralPath $checkPath -PathType Leaf) {
            $file = $checkPath
            $center = $Matches[2]
        }
    }
}

# 拡張子による簡易的な画像判定
$ext = [System.IO.Path]::GetExtension($file).ToLower()
$imageExts = @('.png', '.jpg', '.jpeg', '.gif', '.bmp', '.tiff', '.webp', '.ico', '.svg')
$isImage = $imageExts -contains $ext

# --- 画像の場合 (chafa などを利用) ---
if ($isImage) {
    $cols = if ($env:FZF_PREVIEW_COLUMNS) { $env:FZF_PREVIEW_COLUMNS } else { 80 }
    $lines = if ($env:FZF_PREVIEW_LINES) { $env:FZF_PREVIEW_LINES } else { 24 }
    
    # Kitten (Kitty / WezTerm)
    if (Get-Command kitten -ErrorAction SilentlyContinue) {
        kitten icat --clear --transfer-mode=memory --stdin=no --place="${cols}x${lines}@0x0" "$file"
        exit
    }
    
    # Chafa (Sixel)
    if (Get-Command chafa -ErrorAction SilentlyContinue) {
        chafa -s "${cols}x${lines}" "$file"
        exit
    }
    
    # 画像プレビューアがない場合
    Write-Host "[Image: $file] (Install 'chafa' to preview)"
    exit
}

# --- テキスト/バイナリの場合 (bat を利用) ---

# bat があるか確認 (シンタックスハイライト付き)
if (Get-Command bat -ErrorAction SilentlyContinue) {
    $style = if ($env:BAT_STYLE) { $env:BAT_STYLE } else { "numbers" }
    bat --style="$style" --color=always --pager=never --highlight-line=$center -- "$file"
} else {
    # bat がない場合のフォールバック (指定された通り Get-Content を使用)
    Get-Content $file -TotalCount 200
}
