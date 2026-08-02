# Rewrite Progress

このドキュメントは、`src`ディレクトリ以下のプログラムの書き直し進捗を記録します。

**移管先は `mimikun/mimikun.scripts` の `src/**`（bun + TypeScript）。**
移管が済んだファイルはこのリポジトリから削除する。対応する `powershell/*.ps1` も同時に消す。

## 進捗状況

| ディレクトリ | ファイル名 | 状態 | 完了日 | 備考 |
|------------|-----------|------|--------|------|
| generate/ | archlinux-package-list.sh | 未着手 | - | |
| generate/ | cargo-package-list.sh | 完了 | 2026-08-02 | → `mimikun.scripts` の `src/generate/cargo-package-list.ts`。削除済み |
| generate/ | pip-package-list.sh | 未着手 | - | |
| generate/ | pipx-package-list.sh | 未着手 | - | |
| generate/ | uv-tool-list.sh | 未着手 | - | |
| install/ | arch-packages.sh | 未着手 | - | |
| install/ | cargo-packages.sh | 完了 | 2026-08-02 | → `mimikun.scripts` の `src/install/cargo-packages.ts`。削除済み |
| install/ | gh-extensions.sh | 未着手 | - | |
| install/ | pip-packages.sh | 未着手 | - | |
| install/ | pipx-packages.sh | 未着手 | - | |
| install/ | uv-tools.sh | 未着手 | - | |
| misc/ | cpat.sh | 未着手 | - | |
| misc/ | editorconfig.sh | 未着手 | - | |
| misc/ | numeronym.sh | 未着手 | - | |
| misc/ | pcd.sh | 未着手 | - | |
| misc/ | re-boot.sh | 未着手 | - | |
| misc/ | read-confirm.sh | 未着手 | - | |
| misc/ | shut-down.sh | 未着手 | - | |
| update/ | brew.sh | 未着手 | - | |
| update/ | cargo-packages.sh | 完了 | 2026-08-02 | → `mimikun.scripts` の `src/update/cargo-packages.ts`。削除済み |
| update/ | chromedriver.sh | 未着手 | - | |
| update/ | docker-compose.sh | 未着手 | - | |
| update/ | fish-completions.sh | 完了 | 2026-08-03 | → `mimikun.scripts` の `src/update/fish-completions.ts`。削除済み。`~/scripts` 版を正とし、ここのコピーは破棄 |
| update/ | geckodriver.sh | 未着手 | - | |
| update/ | mise.sh | 未着手 | - | |
| update/ | pip-packages.sh | 未着手 | - | |
| update/ | twitch-cli.sh | 未着手 | - | |
| update/ | various.sh | 未着手 | - | |

## 状態の定義

- **未着手**: まだ作業を開始していない
- **進行中**: 現在作業中
- **レビュー中**: 書き直しが完了し、レビュー待ち
- **完了**: レビューが完了し、マージ済み

