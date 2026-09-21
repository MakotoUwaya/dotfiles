# Infinite Image Browsing (IIB) カスタマイズ設定

Stability Matrix 環境において、WebUI Forge Neo を起動せずに ComfyUI の生成画像をスタンドアロンで軽量閲覧・解析するための設定および拡張プラグインです。

## 構成

- `plugins/comfyui_extended/main.py`:
  - IIB 公式のプラグイン機構（`plugins/`）を利用した ComfyUI 拡張パーサー。
  - **対応機能**:
    - `ClownsharKSampler_Beta` などのカスタムサンプラーの自動認識
    - サブグラフや Conditioning（`KreaSeedVarianceEnhancer` 等）を経由したノードからポジティブ/ネガティブプロンプトを再帰的に抽出
    - LoRA・UNETLoader を遡って使用モデル名（`ckpt_name` / `unet_name`）を抽出
    - ステップ数、サンプラー名、CFG、シード値の抽出
- `run_iib_standalone.bat`:
  - GPU/VRAM を消費せず、FastAPI サーバー単体を立ち上げるバッチファイル。
  - Stability Matrix の `Images` フォルダ、ComfyUI の `output` フォルダを自動読み込み。

## 配置先（復元時）

1. **プラグイン**:
   - コピー先: `<Forgeパス>/extensions/sd-webui-infinite-image-browsing/plugins/comfyui_extended/main.py`
   - ※ IIB の公式 `.gitignore` で `plugins/*` は除外されているため、本体を `git pull` しても上書き・衝突しません。
2. **起動バッチ**:
   - コピー先: `<Forgeパス>/run_iib_standalone.bat`
