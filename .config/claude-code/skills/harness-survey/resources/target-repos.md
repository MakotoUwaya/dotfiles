# リポジトリ固有事情と調査状態

このファイルの役割は 2 つ。**種別ごとの汎用的な読み替えはここには書かない**
（`survey-prompts.md` の「リポジトリ種別ごとの読み替え」を参照）。

1. コードから読み取れないリポジトリ固有事情（調査範囲の限定・移設予定等）
2. 調査状態の記録（調査済み日付・初回スコア・手順書の所在）

未掲載のリポジトリも調査可能。その場合は survey-prompts.md の種別判定に従って実行する。
繰り返し調査するリポジトリはこの表に追加し、初回調査の仮スコアを「初回スコア」列に記録する。

## 調査対象リポジトリ

| リポジトリ | 種別 | 固有事情 | 初回スコア | 調査状態 |
|---|---|---|---|---|
| esa-apps | コード（TypeScript + Rust モノレポ） | なし | 2/18 | 2026-07-04 調査済み。手順書は account-service#4228 のコメント参照（H1〜H12、テスト拡充 7 順、ルール運用 3 層構成） |
| es-account-provisioning | IaC（Terraform + GCP） | なし | 2/18 | 未調査 |
| esa-master | コード（Rust + Node.js） | なし | 2/18 | 未調査 |
| account-service | コード（Node.js） | **調査範囲を packages/auth0 + deploy-auth0-settings CI ジョブ + 関連シークレットに限定**。統治再編で packages/auth0 を es-account-provisioning へ移設後にアーカイブ予定のため、他パッケージは調査しない | 2/18 | 未調査 |
| esa-docs | 文書（リリース・メンテナンス手順書） | 統治再編で es-account-governance へ移設予定。棚卸しの重点はスキル（es-account-release, procedure-writer 等）・テンプレート・条件付きルール | 1/18 | 2026-07-06 調査済み。仮スコア 1/18（初回値と一致）。手順書はスクラッチパッド生成（H1〜H13、移設順序 7 段階） |
| es-account-governance | 文書（統治文書・新設予定） | 新設後に追加。CONSTITUTION.md / ADR / scorecard / ci-templates の整備状況を調査対象とする | — | 未作成 |
| squareWeb（es-square） | コード（TypeScript pnpm + Turborepo モノレポ） | なし | 2/18 | 2026-07-06 調査済み。仮スコア 2/18 |

## 状態メモ

- es-account 5 リポジトリ（esa-apps 〜 esa-docs）の初回スコアは 2026-06 の初回スコアリング値
  （es-account の統治設計 Issue: account-service#4228 に記録）。squareWeb は 2026-07-06 の実測値
