## クリップボード操作

ユーザーが「クリップボードにコピーして」と依頼した場合、実行中の OS に応じて使い分けること。
エイリアス (`clip`) は非対話シェルで読まれないため、いずれもコマンドを直接使う。

**WSL2**（`/mnt/c/Windows` が存在する場合）— Windows 側のクリップボードへ:

```sh
echo "コピーしたい内容" | iconv -t utf-16le | /mnt/c/Windows/System32/clip.exe
```

**ネイティブ Linux** — X11 / Wayland のクリップボードへ:

```sh
echo "コピーしたい内容" | xclip -selection clipboard   # X11
echo "コピーしたい内容" | wl-copy                       # Wayland
```

判定に迷う場合は `[ -d /mnt/c/Windows ]` で WSL2 かを確認してから選ぶこと。
