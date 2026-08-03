# mimikun.sh

> **このリポジトリは役目を終えた。実装は `mimikun/mimikun.scripts`（bun + TypeScript）にある。**
> ここに新しいものを書かないこと。読むなら `mimikun.scripts` の `AGENTS.md` から。

`src/**` と `powershell/**` は 2026-08-03 に削除した。統合は完了している。

## どこへ行ったか

Linux で実際に動くのは chezmoi が配備する `~/.local/bin/*`、Windows で動くのは chezmoi の
`dot_config/powershell/Microsoft.PowerShell_profile.ps1.tmpl` 内の関数定義。
どちらも実装を持たず、`mimikun.scripts` を呼ぶ薄いシムになっている。

| ここにあったもの | 行き先 |
|---|---|
| cargo の生成 / 導入 / 更新 | `mimikun.scripts` の `src/{generate,install,update}/` |
| fish 補完 | `src/update/fish-completions.ts` |
| docker compose プラグイン | `src/update/docker-compose.ts` |
| mise の `ref:` ピン（`mise.sh`） | `src/update/mise-refs.ts` |
| `various.sh`（vup 本体） | `src/update/all.ts` |
| `editorconfig` | `src/misc/editorconfig.ts` |
| apt / arch / brew のパッケージ更新 | `src/update/all.ts` の `OS_PACKAGES` |
| `misc/*`（cpat, numeronym, pcd, re-boot, read-confirm, shut-down） | chezmoi の `private_dot_local/bin/executable_*` |
| chezmoi の apply hook | chezmoi の `executable_chezmoi_{pre,post}_apply_hook` |

**パッケージマネージャに移したもの**（コードとしては消えた）:

| | |
|---|---|
| chromedriver | mise の `http:` backend（Chrome for Testing の `LATEST_RELEASE_STABLE`） |
| geckodriver | mise の `github:` backend |
| twitch-cli | aqua 標準レジストリ |
| `pnpm-packages.sh` | `pnpm self-update` |

## 移さずに捨てたもの

削除前に1ファイルずつ行き先を確認し、対応物が無かった3本は本人の判断で捨てた。
**必要になったらこのリポジトリの git 履歴から拾える。**

- `powershell/Invoke-RunBeforeChezmoiApply.ps1` — `Write-Output` と TODO だけのスタブ。
  Linux 側の pre-apply hook も同じくスタブ
- `powershell/Invoke-RunAfterChezmoiApply.ps1` — Windows の post-apply hook。
  PowerShell プロファイルを Documents へコピーし、`%LOCALAPPDATA%\nvim` と `vimfiles` を
  chezmoi のソースから作り直す。`.chezmoi.toml.tmpl` で**コメントアウトされたまま**で、
  `NOTE: Neovim setting is broken` と註記されていた
- `powershell/Invoke-RebootSecondMonitor.ps1` — BenQ EX3210U をデバイスの無効化と
  有効化で再起動する。プロファイルに無いので `rsm` は元から使えず、
  モニターの型番とデバイス ID がハードコードされている

## 経緯

deno-dax で書き始め、実行速度のため bun に変えた。その後、同じ処理が
bash / PowerShell / chezmoi の3箇所に散っている状態を `mimikun.scripts` へ1本化した。
このリポジトリの `src/**` と `powershell/**` は 2026-02 以降どこからも読み込まれておらず、
chezmoi 側と乖離した死んだコピーだった。
