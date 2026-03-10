# 引継ぎメッセージ（Windows → Ubuntu）

## 依頼事項

### 1. difit スキルを git 管理対象にする

`.gitignore` の36行目で `difit` スキルが除外されている：

```
.config/claude-code/skills/difit
```

この行を削除して、difit スキルを git 追跡対象にしてほしい。

**確認手順:**

```bash
# .gitignore から除外行を削除後
git check-ignore -v .config/claude-code/skills/difit/SKILL.md
# → 無視されていないことを確認
```

### 2. 他にも git 未追跡のスキルがないか確認

Ubuntu 環境のスキルディレクトリ（`~/.claude/skills/` または `~/.config/claude-code/skills/`）に、git で追跡されていないスキルが他にもないか確認してほしい。

```bash
# ローカルにあるスキル一覧
ls ~/.claude/skills/ 2>/dev/null
ls ~/.config/claude-code/skills/ 2>/dev/null

# git で追跡済みのスキル一覧
git ls-files .config/claude-code/skills/
```

差分があれば `.gitignore` を修正して追跡対象にする。

### 3. 変更を commit & push

上記の修正が完了したら commit & push する。

## 背景

- `interaction.md` で `/difit` スキルを使うルールがあるが、スキル実体が git 管理されていないため Windows 環境で利用できない状態だった
- `.gitignore` の除外設定が原因と思われる
- 同様の問題が他のスキルにもないか確認したい

## このファイルについて

作業完了後、この `message.md` は不要なので削除してください。
