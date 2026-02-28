---
name: gitlab-ci
description: GitLab CI の rules/changes 設定を調査・修正する際の進め方。修正方針の策定、影響調査、ドキュメント作成のプロセスを定義
user-invocable: false
---

# GitLab CI Rules 修正ガイド

## Overview

GitLab CI の rules や changes 条件を修正する際の調査プロセスと進め方を定義するスキル。
CI パイプラインの実行条件最適化、ジョブの実行タイミング制御、changes 条件の追加・変更時に使用する。

## When to Use

- CI パイプラインの実行条件を変更したい
- 特定のジョブの実行タイミングを最適化したい
- changes 条件を追加・変更したい
- 新しいルールを追加したい

## Instructions

### Phase 1: 現状調査

1. **対象ジョブの特定**
   - どのジョブを修正するか明確にする
   - ジョブの目的と役割を理解する

2. **現在のルール確認**
   ```bash
   # ジョブ定義を確認
   grep -A 10 'job-name:' .gitlab-ci.yml

   # ルール定義を確認
   grep -A 10 '.rule-name:' .gitlab/ci/rule.yml

   # テンプレート定義を確認
   grep -A 10 '.template-name:' .gitlab/ci/job-template.yml
   ```

3. **テンプレートの依存関係調査**
   ```bash
   # テンプレートを extends しているジョブを検索
   grep -r "extends:" .gitlab-ci.yml .gitlab/ci/*.yml | grep "template-name"
   ```

### Phase 2: 修正方針策定

1. **実行条件の整理**
   - どの条件で実行すべきか
   - どの条件でスキップすべきか
   - changes 条件が必要か

2. **影響範囲の特定**
   - 直接影響するジョブ
   - テンプレート経由で影響するジョブ
   - 他のルールとの相互作用

3. **方針案の作成**
   - 複数の選択肢を提示
   - 各案のメリット・デメリットを整理

### Phase 3: 実装

1. **ルール定義の変更** (.gitlab/ci/rule.yml)
2. **テンプレートの変更** (.gitlab/ci/job-template.yml)
3. **ジョブ定義の変更** (.gitlab-ci.yml)

### Phase 4: ドキュメント更新

- パイプライン動作表の更新
- 変更履歴の追記

## Examples

### Example 1: パッケージテストを MR 時のみ実行に変更

**Input (ユーザー要望):**
> test:packages:core を feature push では実行せず、MR オープン時のみ実行したい

**調査結果:**
```yaml
# 現状の .rule-test-packages-core
.rule-test-packages-core:
  rules:
    - <<: *if-commit-feature        # ← これを削除
      <<: *if-changes-packages-core
      when: on_success
    - <<: *if-create-mr-event
      <<: *if-changes-packages-core
      when: on_success
    - when: never
```

**Output (修正後):**
```yaml
.rule-test-packages-core:
  rules:
    - <<: *if-commit-open-mr-feature  # MR オープン時のみ
      <<: *if-changes-packages-core
      when: on_success
    - <<: *if-create-mr-event
      <<: *if-changes-packages-core
      when: on_success
    - when: never
```

### Example 2: Storybook テストに changes 条件を追加

**Input (ユーザー要望):**
> test:storybook を Storybook 関連ファイルの変更時のみ実行したい（develop は常に実行）

**Output (修正):**

1. rule.yml に changes 条件を追加:
```yaml
.if-changes-storybook-related: &if-changes-storybook-related
  changes:
    - "apps/sale-bukken/src/**/*.stories.@(ts|tsx)"
    - "apps/sale-bukken/src/Components/**/*"
    - "packages/ui/src/**/*"
```

2. ルールを作成:
```yaml
.rule-storybook-related:
  rules:
    - <<: *if-commit-feature
      <<: *if-changes-storybook-related
      when: on_success
    - <<: *if-commit-develop
      when: on_success  # develop は changes なし
    - when: never
```

## Reference

### if 条件アンカー

| アンカー | 説明 | 用途 |
|:---|:---|:---|
| `*if-commit-feature` | feature ブランチへの push | 開発中のテスト |
| `*if-commit-open-mr-feature` | MR がオープンされた feature ブランチ | MR レビュー時のテスト |
| `*if-create-mr-event` | MR イベント (merge_request_event) | MR 作成・更新時 |
| `*if-commit-develop` | develop ブランチへの push | 統合テスト |
| `*if-schedule-develop` | develop の定期実行 | 定期的な検証 |
| `*if-commit-release` | release ブランチへの push | リリース準備 |
| `*if-commit-hotfix` | hotfix ブランチへの push | 緊急修正 |

### when の値

| 値 | 説明 |
|:---|:---|
| `on_success` | 前のステージが成功したら実行 |
| `always` | 常に実行 |
| `manual` | 手動実行 |
| `delayed` | 遅延実行 |
| `never` | 実行しない |

### ルール設計パターン

#### パターン1: 常に実行（changes なし）

```yaml
.rule-always-run:
  rules:
    - <<: *if-commit-feature
    - <<: *if-commit-open-mr-feature
    - <<: *if-create-mr-event
    - <<: *if-commit-develop
```

**用途:** lint, build など軽量で常に実行すべきジョブ

#### パターン2: MR のみ + changes 条件

```yaml
.rule-mr-only-with-changes:
  rules:
    - <<: *if-commit-open-mr-feature
      <<: *if-changes-xxx
      when: on_success
    - <<: *if-create-mr-event
      <<: *if-changes-xxx
      when: on_success
    - when: never
```

**用途:** パッケージテストなど MR 時のみ実行すれば十分なジョブ

#### パターン3: develop は常に + 他は changes 条件

```yaml
.rule-develop-always-others-changes:
  rules:
    - <<: *if-commit-feature
      <<: *if-changes-xxx
      when: on_success
    - <<: *if-commit-open-mr-feature
      <<: *if-changes-xxx
      when: on_success
    - <<: *if-create-mr-event
      <<: *if-changes-xxx
      when: on_success
    - <<: *if-commit-develop
      when: on_success  # changes なし
    - when: never
```

**用途:** Storybook テストなど develop では常に検証すべきジョブ

### テンプレート経由での設定

#### 推奨: テンプレートで rules を定義

```yaml
# job-template.yml
.test-job-template:
  rules:
    - !reference [ '.rule-test', rules ]

# gitlab-ci.yml
test-job:
  extends:
    - .test-job-template
  script:
    - pnpm test
```

#### 非推奨: ジョブで直接 rules を定義

```yaml
# 避けるべきパターン
test-job:
  extends:
    - .test-job-template
  rules:  # テンプレートの rules を上書きしてしまう
    - !reference [ '.rule-xxx', rules ]
  script:
    - pnpm test
```

### 影響調査チェックリスト

修正前に以下を確認:

- [ ] 対象ルールを使用しているジョブを全て特定したか
- [ ] テンプレートを extends しているジョブを確認したか
- [ ] セキュリティ関連ジョブ (trivy 等) への影響がないか
- [ ] develop ブランチでの動作に問題がないか
- [ ] 他のルールとの競合がないか

### パイプライン動作表フォーマット

```markdown
| ジョブ名 | feature push<br>(MR未作成) | feature push<br>(MR オープン) | MR イベント | develop push |
|:---|:---:|:---:|:---:|:---:|
| test:xxx | ❌ | 🔄 | 🔄 | ✅ |
```

**凡例:**
- ✅ 常に実行
- 🔄 changes 条件付きで実行
- ❌ 実行しない

### ファイル構成

```
.gitlab-ci.yml          # ジョブ定義
.gitlab/ci/
  ├── rule.yml          # ルール定義（if条件、changes条件）
  ├── job-template.yml  # ジョブテンプレート
  └── base.yml          # ベース設定
```

## Guidelines

1. **セキュリティジョブの changes 制御は慎重に**
   - trivy などのセキュリティスキャンは基本的に常に実行
   - changes 条件を追加すると脆弱性を見逃す可能性

2. **turbo との併用**
   - lint 系は turbo --affected で最適化済みの場合が多い
   - changes 条件は不要な場合がある

3. **テンプレートの変更は影響範囲が大きい**
   - 必ず依存関係を調査してから変更
   - 予期しないジョブに影響する可能性

4. **MR 未作成時の考慮**
   - MR 作成前にテストが実行されないとローカルテストが必須
   - 開発者への周知が必要

5. **ドキュメント更新を忘れない**
   - パイプライン動作表の更新
   - 変更履歴の追記

6. **ドキュメント出力ルール**
   - 出力先: `docs/<話題_yyyy_mm_dd>/<内容のショートターム>.md`
   - ディレクトリ名・ファイル名は日本語を使用
   - 例: `docs/ci_rules_分割案_2026_02_05/案A_役割ベース分割.md`
   - 複数案がある場合はファイルを分けて出力
