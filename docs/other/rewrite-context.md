# Rewrite Context

このドキュメントは、`src`ディレクトリ以下のプログラムの書き直しに関するコンテキストと要件を記載します。

## 概要

mimikun.shプロジェクトの`src`ディレクトリ以下のBashスクリプトを書き直すためのガイドラインです。

## 書き直しの目的

**同じ処理が bash / PowerShell / fish に分かれて別々に管理されており、中身が少しずつ食い違っている。**
これを1実装に畳み、置き場所も1つにする。

## 要件

- **移管先は `mimikun/mimikun.scripts` の `src/**`。** このリポジトリには新しい実装を書かない
- **言語は TypeScript、実行は bun。** 当初は deno-dax を想定していたが、実行速度から bun にした
- **OS 差はライブラリ1箇所に閉じる。** パッケージリストのファイル名（`linux_*` / `windows_*`）や
  ホームディレクトリの取り方をスクリプト本体に散らさない
- **`--no-pueue` は維持する。** 加えて `--dry-run` を持たせ、移管の前後で
  「積まれるコマンド集合が変わっていないこと」を差分で確認できるようにする
- **移管したら、このリポジトリの `src/*.sh` と対応する `powershell/*.ps1` を削除する。**
  残すと4箇所目になる

## 注意: このリポジトリのファイルは動いていない

`src/**` と `powershell/**` は、どこからも読み込まれていない死んだコピー。実際に動くのは:

- **Linux**: chezmoi が配備する `~/.local/bin/*`（`private_dot_local/bin/executable_*`）
- **Windows**: chezmoi の `dot_config/powershell/Microsoft.PowerShell_profile.ps1.tmpl` 内の関数定義

このリポジトリは 2026-02 以降動いておらず、chezmoi 側と乖離している。
**移管時は chezmoi 側を正として読むこと。** 移管を「完了」にするには、その2箇所も
新実装を呼ぶように書き換える必要がある。

## 対象ファイル

### generate/
- archlinux-package-list.sh
- cargo-package-list.sh
- pip-package-list.sh
- pipx-package-list.sh
- uv-tool-list.sh

### install/
- arch-packages.sh
- cargo-packages.sh
- gh-extensions.sh
- pip-packages.sh
- pipx-packages.sh
- uv-tools.sh

### misc/
- cpat.sh
- editorconfig.sh
- numeronym.sh
- pcd.sh
- re-boot.sh
- read-confirm.sh
- shut-down.sh

### update/
- brew.sh
- cargo-packages.sh
- chromedriver.sh
- docker-compose.sh
- fish-completions.sh
- geckodriver.sh
- mise.sh
- pip-packages.sh
- twitch-cli.sh
- various.sh

## 進捗状況

進捗状況は`docs/other/rewrite-progress.md`に記載します。

