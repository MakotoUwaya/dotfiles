---
name: git
description: バージョン管理の読み取り操作専用。差分・履歴・ブランチ状態の確認に使用。コミット・マージ・リベース等の書き込み操作は禁止
---

# Git

Git はバージョン管理システムです。ソースコードの変更履歴を管理し、複数人での開発を可能にします。

## When to Use

- 差分の確認（`git diff`、`git status`）
- コミット履歴の確認（`git log`、`git show`）
- ブランチの状態確認（`git branch`）

## Prohibited Operations

以下の操作は禁止です。このスキルを使って実行しないでください:

- コミットの作成・修正（`git commit`、`git commit --amend`）
- ブランチの作成・削除・切り替え
- マージ・リベース
- その他の書き込み操作

### 書き込み操作にあたるコマンド

- `git commit` - コミット作成
- `git commit --amend` - コミット修正
- `git add` - ステージング
- `git checkout -b` / `git switch -c` - ブランチ作成
- `git checkout` / `git switch` - ブランチ切り替え
- `git branch -d` / `git branch -D` - ブランチ削除
- `git merge` - マージ
- `git rebase` - リベース
- `git reset` - リセット
- `git revert` - リバート
- `git push` - プッシュ
- `git pull` - プル
- `git stash` - スタッシュ
- `git cherry-pick` - チェリーピック
- `git tag` - タグ作成
- `git clean` - 未追跡ファイル削除

**書き込み操作が必要な場合:** コマンドを直接実行せず、ユーザーに「このコマンドを実行してください」とコマンドを提示してください。

## ブランチ操作

```bash
# ブランチ一覧
git branch           # ローカル
git branch -r        # リモート
git branch -a        # すべて

# ブランチ作成
git branch <branch-name>

# ブランチ作成して切り替え
git checkout -b <branch-name>
git switch -c <branch-name>  # 新しい方法

# ブランチ切り替え
git checkout <branch-name>
git switch <branch-name>

# ブランチ削除
git branch -d <branch-name>   # マージ済みのみ
git branch -D <branch-name>   # 強制削除

# リモートブランチを追跡
git checkout -b <local> origin/<remote>
git switch -c <local> --track origin/<remote>

# ブランチ名変更
git branch -m <old-name> <new-name>
```

## コミット操作

### 基本

```bash
# ステージング
git add <file>
git add .
git add -p          # 対話的に選択

# コミット
git commit -m "message"
git commit -am "message"  # 追跡済みファイルを add + commit

# 直前のコミットを修正
git commit --amend -m "new message"
git commit --amend --no-edit  # メッセージ変更なし
```

### コミットメッセージ規約 (Conventional Commits)

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメントのみ
- `style`: コードの意味に影響しない変更
- `refactor`: リファクタリング
- `perf`: パフォーマンス改善
- `test`: テスト追加・修正
- `chore`: ビルドプロセスやツールの変更

**例:**
```bash
git commit -m "feat(auth): add OAuth2 login support"
git commit -m "fix(api): handle null response from server"
```

## マージとリベース

### マージ

```bash
# マージ
git merge <branch>

# マージ（コミットを作成）
git merge --no-ff <branch>

# マージ中止
git merge --abort

# マージコンフリクト解決後
git add <resolved-files>
git merge --continue
```

### リベース

```bash
# リベース
git rebase <branch>

# 対話的リベース（直近3コミット）
git rebase -i HEAD~3

# リベース中止
git rebase --abort

# コンフリクト解決後
git add <resolved-files>
git rebase --continue
```

**対話的リベースのコマンド:**
- `pick`: そのまま使用
- `reword`: メッセージ変更
- `edit`: コミット修正
- `squash`: 前のコミットに統合
- `fixup`: squash + メッセージ破棄
- `drop`: コミット削除

## 履歴・差分確認

```bash
# ログ表示
git log
git log --oneline
git log --graph --oneline --all
git log -p                    # 差分も表示
git log --stat               # 変更ファイル統計
git log --author="name"
git log --since="2024-01-01"
git log -- <file>            # 特定ファイルの履歴

# 差分
git diff                     # ワーキングツリー vs ステージ
git diff --staged            # ステージ vs HEAD
git diff HEAD                # ワーキングツリー vs HEAD
git diff <commit1> <commit2>
git diff <branch1>..<branch2>

# ファイルの変更履歴
git blame <file>
git log -p -- <file>

# コミット内容表示
git show <commit>
git show <commit>:<file>
```

## 変更の取り消し

### ワーキングツリーの変更を取り消し

```bash
git checkout -- <file>
git restore <file>           # 新しい方法
git restore .                # すべて
```

### ステージングを取り消し

```bash
git reset HEAD <file>
git restore --staged <file>  # 新しい方法
```

### コミットの取り消し

```bash
# 直前のコミットを取り消し（変更は保持）
git reset --soft HEAD~1

# 直前のコミットを取り消し（変更はステージング解除）
git reset HEAD~1
git reset --mixed HEAD~1

# 直前のコミットを取り消し（変更も破棄）
git reset --hard HEAD~1

# 特定コミットを打ち消すコミット作成
git revert <commit>
git revert HEAD              # 直前を打ち消し
```

## スタッシュ

```bash
# 変更を退避
git stash
git stash -m "message"
git stash -u                 # 未追跡ファイルも含む

# スタッシュ一覧
git stash list

# 復元
git stash pop                # 最新を適用して削除
git stash apply              # 最新を適用
git stash apply stash@{1}    # 指定して適用

# 削除
git stash drop
git stash clear              # すべて削除

# 内容確認
git stash show
git stash show -p            # 差分表示
```

## チェリーピック

```bash
# 特定コミットを現在のブランチに適用
git cherry-pick <commit>

# 複数コミット
git cherry-pick <commit1> <commit2>

# コミットせずに適用
git cherry-pick -n <commit>

# 中止
git cherry-pick --abort
```

## リモート操作

```bash
# リモート一覧
git remote -v

# リモート追加
git remote add <name> <url>

# フェッチ
git fetch origin
git fetch --all
git fetch --prune            # 削除されたリモートブランチを反映

# プル
git pull
git pull --rebase            # リベースでプル
git pull origin <branch>

# プッシュ
git push
git push -u origin <branch>  # 上流ブランチ設定
git push --force-with-lease  # 安全な強制プッシュ

# リモートブランチ削除
git push origin --delete <branch>
```

## タグ

```bash
# タグ一覧
git tag
git tag -l "v1.*"

# 軽量タグ作成
git tag <tag-name>

# 注釈付きタグ作成
git tag -a <tag-name> -m "message"

# 特定コミットにタグ
git tag -a <tag-name> <commit>

# タグをプッシュ
git push origin <tag-name>
git push origin --tags       # すべてのタグ

# タグ削除
git tag -d <tag-name>
git push origin --delete <tag-name>
```

## その他便利なコマンド

```bash
# 追跡されていないファイルを削除
git clean -fd
git clean -fdn               # プレビュー

# ファイル名変更を追跡
git mv <old> <new>

# コミットを探す
git bisect start
git bisect bad
git bisect good <commit>

# ワークツリーの状態確認
git status
git status -s                # 短縮形式

# 設定確認
git config --list
git config user.name
git config user.email
```
