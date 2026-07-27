---
name: ffmpeg
description: ffmpeg で動画・音声ファイルを変換・編集するコマンドリファレンス。コンテナ/コーデック変換、CRF・ビットレート指定の圧縮、切り出し・結合、音声の抽出・差し替え・音量調整、解像度/フレームレート変更、GIF・サムネイル生成を扱う。「動画」「音声」「変換」「エンコード」「圧縮」「トリミング」などで自動呼び出し
user-invocable: false
---

# FFmpeg

## Overview

動画・音声ファイルの変換、編集、ストリーミングのためのコマンドリファレンス。

## When to Use

- 動画フォーマット変換（mov→mp4、avi→mkv など）
- 動画の圧縮（CRF / ビットレート指定）
- 動画の切り出し・トリミング
- 複数動画の結合
- 音声の抽出・削除・差し替え・音量調整
- 解像度・フレームレート変更
- GIF 作成
- サムネイル・画像シーケンス生成

## エンコーダー設定

H.264 エンコードにはハードウェアエンコーダーが使える場合はそちらを優先する。まず利用可能なエンコーダーを確認する:

```bash
ffmpeg -hide_banner -encoders | grep V
```

## フォーマット変換

### コンテナ変換

```bash
# 基本的な変換
ffmpeg -i input.mov output.mp4
ffmpeg -i input.avi output.mkv

# コーデックをコピー（再エンコードなし、高速）
ffmpeg -i input.mov -c copy output.mp4
```

### コーデック指定

```bash
# H.264 + AAC
ffmpeg -i input.mov -c:v libx264 -c:a aac output.mp4

# H.265 (HEVC)
ffmpeg -i input.mov -c:v libx265 -c:a aac output.mp4

# VP9 + Opus (WebM)
ffmpeg -i input.mov -c:v libvpx-vp9 -c:a libopus output.webm

# ProRes (編集用)
ffmpeg -i input.mp4 -c:v prores_ks -profile:v 3 -c:a pcm_s16le output.mov
```

## 動画圧縮

### CRF (品質指定)

```bash
# CRF値: 0(無損失) - 51(最低品質)、デフォルト23、推奨18-28
ffmpeg -i input.mp4 -c:v libx264 -crf 23 output.mp4

# H.265はCRF値が同じでも高圧縮
ffmpeg -i input.mp4 -c:v libx265 -crf 28 output.mp4
```

### プリセット (速度 vs 圧縮率)

```bash
# ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow
ffmpeg -i input.mp4 -c:v libx264 -crf 23 -preset slow output.mp4
```

### ビットレート指定

```bash
# 固定ビットレート
ffmpeg -i input.mp4 -c:v libx264 -b:v 5M output.mp4

# 2パスエンコード（より正確なビットレート制御）
ffmpeg -i input.mp4 -c:v libx264 -b:v 5M -pass 1 -f null /dev/null
ffmpeg -i input.mp4 -c:v libx264 -b:v 5M -pass 2 output.mp4
```

## トリミング・切り出し

```bash
# 開始時間から切り出し（-ss を入力の前に置くと高速）
ffmpeg -ss 00:01:00 -i input.mp4 -t 00:00:30 -c copy output.mp4

# 開始・終了時間を指定
ffmpeg -ss 00:01:00 -to 00:01:30 -i input.mp4 -c copy output.mp4

# 秒数でも指定可能
ffmpeg -ss 60 -i input.mp4 -t 30 -c copy output.mp4
```

## 結合 (concat)

```bash
# ファイルリストを作成
# files.txt:
# file 'input1.mp4'
# file 'input2.mp4'
# file 'input3.mp4'

ffmpeg -f concat -safe 0 -i files.txt -c copy output.mp4
```

## 音声操作

### 音声抽出

```bash
# MP3として抽出
ffmpeg -i input.mp4 -vn -c:a libmp3lame -q:a 2 output.mp3

# AACとして抽出
ffmpeg -i input.mp4 -vn -c:a aac -b:a 192k output.m4a

# WAVとして抽出（無圧縮）
ffmpeg -i input.mp4 -vn -c:a pcm_s16le output.wav

# 音声コーデックをコピー
ffmpeg -i input.mp4 -vn -c:a copy output.aac
```

### 音声削除・差し替え

```bash
# 音声を削除
ffmpeg -i input.mp4 -an -c:v copy output.mp4

# 音声を差し替え
ffmpeg -i video.mp4 -i audio.mp3 -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 output.mp4
```

### 音量調整

```bash
# 音量を2倍に
ffmpeg -i input.mp4 -filter:a "volume=2.0" output.mp4

# dBで指定
ffmpeg -i input.mp4 -filter:a "volume=5dB" output.mp4

# 音量を正規化
ffmpeg -i input.mp4 -filter:a loudnorm output.mp4
```

## 解像度・フレームレート

```bash
# 解像度変更
ffmpeg -i input.mp4 -vf "scale=1280:720" output.mp4
ffmpeg -i input.mp4 -vf "scale=1920:-1" output.mp4  # アスペクト比維持

# フレームレート変更
ffmpeg -i input.mp4 -r 30 output.mp4

# 両方変更
ffmpeg -i input.mp4 -vf "scale=1280:720,fps=30" output.mp4
```

## GIF 作成

```bash
# 基本的なGIF作成
ffmpeg -i input.mp4 -vf "fps=10,scale=480:-1" output.gif

# 高品質GIF（パレット使用）
ffmpeg -i input.mp4 -vf "fps=10,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" output.gif

# 特定範囲をGIF化
ffmpeg -ss 5 -t 3 -i input.mp4 -vf "fps=15,scale=320:-1" output.gif
```

## 情報取得 (ffprobe)

```bash
# 基本情報
ffprobe input.mp4

# JSON形式で詳細情報
ffprobe -v quiet -print_format json -show_format -show_streams input.mp4

# 動画の長さを取得
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 input.mp4

# 解像度を取得
ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 input.mp4
```

## その他便利なコマンド

```bash
# サムネイル作成
ffmpeg -i input.mp4 -ss 00:00:05 -vframes 1 thumbnail.jpg

# 複数サムネイル作成（10秒ごと）
ffmpeg -i input.mp4 -vf "fps=1/10" thumbnail_%03d.jpg

# 動画を画像シーケンスに
ffmpeg -i input.mp4 -vf "fps=1" frame_%04d.png

# 画像シーケンスを動画に
ffmpeg -framerate 30 -i frame_%04d.png -c:v libx264 output.mp4

# 回転
ffmpeg -i input.mp4 -vf "transpose=1" output.mp4  # 90度時計回り

# クロップ
ffmpeg -i input.mp4 -vf "crop=640:480:100:50" output.mp4  # width:height:x:y
```

## Guidelines

- `-y`: 出力ファイルを上書き
- `-n`: 出力ファイルが存在する場合は終了
- `-hide_banner`: バナー非表示
- `-v quiet`: 出力を抑制
