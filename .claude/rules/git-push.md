## GitHub Push ルール

GitHub へ push する際は、環境変数 `GITHUB_PERSONAL_ACCESS_TOKEN` を使用すること。

```sh
# リモート URL とブランチを動的に取得して push する
REMOTE_URL=$(git remote get-url origin)
BRANCH=$(git symbolic-ref --short HEAD)
AUTH_URL=$(echo "$REMOTE_URL" | sed "s|https://github.com|https://MakotoUwaya:${GITHUB_PERSONAL_ACCESS_TOKEN}@github.com|")
git push "$AUTH_URL" "$BRANCH"
```

- PAT は `.envrc` で direnv 経由で管理されている
- push 前に `eval "$(direnv export bash)"` で環境変数を読み込むこと
