# mimikun.sh

> **このリポジトリは `mimikun/mimikun.scripts` へ移管中。ここに新しい実装を書かないこと。**
> 統合先は `mimikun.scripts` の `src/**`（bun + TypeScript）。
> ランタイムは当初の deno-dax から bun に変更した（実行速度のため）。

## Roadmap

`mimikun.scripts` へ1つずつ移し、移し終えたらこのリポジトリをアーカイブする。

- [x] cargo 系 → `mimikun.scripts` の `src/{generate,install,update}/cargo-*.ts`
    - [x] generate_cargo_package_list ← `src/generate/cargo-package-list.sh` + `powershell/Invoke-GenerateCargoPackageList.ps1`
    - [x] install_cargo_packages ← `src/install/cargo-packages.sh` + `powershell/Invoke-InstallCargoPackage.ps1`
    - [x] update_cargo_packages ← `src/update/cargo-packages.sh` + `powershell/Invoke-UpdateCargoPackage.ps1`
- [ ] `editorconfig`
    - [ ] `src/misc/editorconfig.sh`
    - [ ] `powershell/Invoke-GenerateEditorConfig.ps1`

### 移管するときの注意

- **`src/**` と `powershell/**` は、どこからも読み込まれていない死んだコピー。**
  Linux で実際に動くのは chezmoi が配備する `~/.local/bin/*`、Windows で動くのは chezmoi の
  `dot_config/powershell/Microsoft.PowerShell_profile.ps1.tmpl` 内の関数定義。
  移管を「完了」にするには、その2箇所も新実装を呼ぶよう書き換える必要がある。
- ここのコピーは chezmoi 側と既に乖離している（2026-02 以降このリポジトリは動いていない）。
  移管時は**このリポジトリではなく chezmoi 側を正**として読むこと。

## Directory Structure

```text
.
├── docs
│   ├── design
│   │   └── README.md
│   ├── idea
│   │   └── README.md
│   ├── other
│   │   ├── rewrite-context.md
│   │   └── rewrite-progress.md
│   ├── plan
│   │   └── README.md
│   └── README.md
├── powershell
│   ├── Enter-GhqRepository.ps1
│   ├── Enter-ParentDirectory.ps1
│   ├── Invoke-ChezmoiApply.ps1
│   ├── Invoke-ChezmoiCd.ps1
│   ├── Invoke-EzaLa.ps1
│   ├── Invoke-EzaTree.ps1
│   ├── Invoke-GenerateEditorConfig.ps1
│   ├── Invoke-PueueClean.ps1
│   ├── Invoke-PueueCleanSuccessfulOnly.ps1
│   ├── Invoke-PueueFollow.ps1
│   ├── Invoke-PueueLog.ps1
│   ├── Invoke-RebootSecondMonitor.ps1
│   ├── Invoke-RunAfterChezmoiApply.ps1
│   └── Invoke-RunBeforeChezmoiApply.ps1
├── scripts
│   └── pssa.ps1
├── src
│   ├── chezmoi
│   │   ├── post-apply-hook.sh
│   │   └── pre-apply-hook.sh
│   ├── generate
│   │   ├── archlinux-package-list.sh
│   │   ├── pip-package-list.sh
│   │   ├── pipx-package-list.sh
│   │   ├── pnpm-package-list.sh
│   │   └── uv-tool-list.sh
│   ├── install
│   │   ├── arch-packages.sh
│   │   ├── gh-extensions.sh
│   │   ├── pip-packages.sh
│   │   ├── pipx-packages.sh
│   │   ├── pnpm-package.sh
│   │   └── uv-tools.sh
│   ├── misc
│   │   ├── cpat.sh
│   │   ├── editorconfig.sh
│   │   ├── numeronym.sh
│   │   ├── pcd.sh
│   │   ├── re-boot.sh
│   │   ├── read-confirm.sh
│   │   └── shut-down.sh
│   └── update
│       ├── apt-packages.sh
│       ├── arch-packages.sh
│       ├── brew.sh
│       ├── chromedriver.sh
│       ├── docker-compose.sh
│       ├── fish-completions.sh
│       ├── geckodriver.sh
│       ├── mise.sh
│       ├── pip-packages.sh
│       ├── pnpm-packages.sh
│       ├── twitch-cli.sh
│       └── various.sh
├── lefthook.yml
├── LICENSE.txt
├── Makefile
├── maskfile.md
├── package.json
├── PSScriptAnalyzerSettings.psd1
├── README.md
└── renovate.json5
```

