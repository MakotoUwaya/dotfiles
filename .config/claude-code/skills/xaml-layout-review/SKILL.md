---
name: xaml-layout-review
description: WPF の XAML レイアウトをコードレビューする際の観点チェックリスト。StackPanel の間隔不均一、Margin 重複、固定幅によるテキスト切れなど、よくあるレイアウト問題を検出する。MR レビューや XAML 変更時に使用。
user-invocable: false
---

# XAML レイアウトレビュー

## Overview

WPF の XAML コードをレビューする際に、レイアウト上の問題を検出するためのチェックリスト。
MR レビュー（`review-mr`）やコード変更時に、XAML の差分に対して適用する。

## When to Use

- MR レビューで XAML ファイルの変更が含まれるとき
- XAML のレイアウトを新規追加・変更するとき
- UI の間隔やサイズに関する問題が報告されたとき

## Instructions

XAML の差分を確認する際、以下のチェックリストを順に適用する。

### 1. Margin の一貫性

**問題パターン: 兄弟要素間の間隔が不均一になる**

StackPanel の子要素で、あるボタンは `Margin="0,0,10,0"`（右余白）、別のボタンは `Margin="10,0,0,0"`（左余白）を使っていると、隣接する箇所で間隔が倍（20px）になる。

```xml
<!-- NG: 間隔が 10px + 10px = 20px になる -->
<StackPanel Orientation="Horizontal">
    <Button Margin="0,0,10,0" Content="A" />
    <Button Margin="10,0,0,0" Content="B" />  <!-- A-B 間が 20px -->
</StackPanel>

<!-- OK: 一方向（右）に統一して 10px -->
<StackPanel Orientation="Horizontal">
    <Button Margin="0,0,10,0" Content="A" />
    <Button Margin="0,0,10,0" Content="B" />
</StackPanel>
```

**チェック方法:**
- 同じ StackPanel 内の兄弟要素が同じ方向の Margin パターンを使っているか確認する
- ラッパー要素（StackPanel、ContentControl 等）を挟む場合、内部要素の Margin が外部に伝播する点に注意する

### 2. 固定幅とテキスト切れ

**問題パターン: Width を固定した後、テキストが収まらなくなる**

ボタンやラベルの `Width` を変更した場合、表示テキストが切れないか確認する。

```xml
<!-- 要確認: 日本語テキスト「該当なし。新しく作成する」が 196px に収まるか -->
<Button Width="196" Content="該当なし。新しく作成する" />
```

**チェック方法:**
- `Width` が変更された場合、Content のテキスト長と FontSize から表示が収まるか推測する
- 可能であれば Redmine のエビデンス画像や実機スクリーンショットで実際の表示を確認する
- 日本語テキストの場合、1文字あたり約 14px（FontSize=14 の場合）を目安にする

### 3. 等間隔配置のパターン

StackPanel は子要素を等間隔に配置する機能を持たない。等間隔が必要な場合の代替手段:

| パターン | 適用場面 | 注意点 |
|---|---|---|
| `Margin` 統一 | 固定幅ボタンの並び | 最もシンプル。最後の要素の右 Margin が不要なら個別対応 |
| `UniformGrid Rows="1"` | 同幅のセルに均等配置 | 子要素が同じ幅のセルに収まる。Visibility 切り替えがあると空セルが残る |
| `Grid` + `ColumnDefinition` | 柔軟なレイアウト | 列ごとに Auto/Star で幅を制御できるが記述量が増える |
| `ItemsControl` + `WrapPanel` | 動的な要素数 | 要素数が可変の場合に有効 |

### 4. コーチマーク付き要素のレイアウト

コーチマーク（`es:Coachmark.*`）を付与する場合、ラッパー StackPanel が追加されるため、レイアウト上の影響を確認する。

```xml
<!-- コーチマーク用ラッパーが追加されるパターン -->
<StackPanel Orientation="Horizontal"
            es:Coachmark.CoachmarkKey="..."
            es:Coachmark.CoachmarkSetting="{Binding Path=CoachmarkSetting, Mode=OneWay}"
            es:Coachmark.IsOpen="True">
    <es:Coachmark.CoachmarkContent>
        <!-- コーチマーク内容 -->
    </es:Coachmark.CoachmarkContent>
    <Button Content="対象ボタン" />
</StackPanel>
```

**チェック方法:**
- ラッパー StackPanel 自体に Margin が設定されていない場合、内部ボタンの Margin が実質的な外部間隔になる
- コーチマークのポップアップ位置（`CoachmarkPosition`）が他のコントロールと重ならないか確認する

### 5. xmlns 宣言の確認

新しい xmlns 宣言が追加された場合:
- プロジェクトの既存パターンと一致しているか（例: `fa:` = FontAwesome）
- 不要な xmlns が残っていないか

## Guidelines

- XAML の差分だけでなく、親コンテナの構造も確認して判断する
- 既存コードのパターン（Margin、Width 等）を基準にし、新規追加がそれと一致しているか確認する
- 可能であれば Redmine のエビデンス画像で実際の表示を検証してからレビューコメントを投稿する
- 問題を指摘する際は修正案（コード例）を必ず添える
