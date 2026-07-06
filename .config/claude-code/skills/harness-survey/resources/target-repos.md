# リポジトリ固有事情と調査状態

このファイルの役割は 3 つ。**種別ごとの汎用的な読み替えはここには書かない**
（`survey-prompts.md` の「リポジトリ種別ごとの読み替え」を参照）。

1. #4228 の対象スコープ定義（es-account 配下の調査対象一覧）
2. コードから読み取れないリポジトリ固有事情（調査範囲の限定・移設予定等）
3. 調査状態の記録（調査済み日付・手順書の所在）

未掲載のリポジトリ（他グループ・他プロジェクト等）も調査可能。
その場合は survey-prompts.md の種別判定に従って実行し、手順書には
「#4228 スコープ外・編入可否は要確認」の注記を付ける（SKILL.md 参照）。
繰り返し調査するリポジトリはこの表に追加する。

## #4228 対象リポジトリ（es-account）

| リポジトリ | 種別 | 固有事情 | 調査状態 |
|---|---|---|---|
| esa-apps | コード（TypeScript + Rust モノレポ） | なし | 2026-07-04 調査済み。手順書は #4228 コメント参照（H1〜H12、テスト拡充 7 順、ルール運用 3 層構成） |
| es-account-provisioning | IaC（Terraform + GCP） | なし | 未調査 |
| esa-master | コード（Rust + Node.js） | なし | 未調査 |
| account-service | コード（Node.js） | **調査範囲を packages/auth0 + deploy-auth0-settings CI ジョブ + 関連シークレットに限定**。#4228 で packages/auth0 を es-account-provisioning へ移設後にアーカイブ予定のため、他パッケージは調査しない | 未調査 |
| esa-docs | 文書（リリース・メンテナンス手順書） | #4228 で es-account-governance へ移設予定。棚卸しの重点はスキル（es-account-release, procedure-writer 等）・テンプレート・条件付きルール | 2026-07-06 調査済み。仮スコア 1/18（#4228 初回値と一致）。手順書はスクラッチパッド生成（H1〜H13、移設順序 7 段階） |
| es-account-governance | 文書（統治文書・新設予定） | 新設後に追加。CONSTITUTION.md / ADR / scorecard / ci-templates の整備状況を調査対象とする | 未作成 |

## スコープ外リポジトリの調査記録

| リポジトリ | 種別 | 固有事情 | 調査状態 |
|---|---|---|---|
| squareWeb（es-square） | コード（TypeScript pnpm + Turborepo モノレポ） | #4228 スコープ外（編入可否は要確認） | 2026-07-06 調査済み。仮スコア 2/18 |

## 状態メモ

- 6 次元スコアカードの初回スコアリング値は #4228 本文の表を正とする
