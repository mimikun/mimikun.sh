# mimikun.sh

## Roadmap

- [ ] deno-daxで書き直し
    - [ ] 一部スクリプトはひとつに統合
        - [ ] update_cargo_packages
            - [ ] `src/update/cargo-packages.sh`
            - [ ] `powershell/Invoke-UpdateCargoPackage.ps1`
        - [ ] install_cargo_packages
            - [ ] `src/install/cargo-packages.sh`
            - [ ] `powershell/Invoke-InstallCargoPackage.ps1`
        - [ ] generate_cargo_package_list
            - [ ] `src/generate/cargo-package-list.sh`
            - [ ] `powershell/Invoke-GenerateCargoPackageList.ps1`
        - [ ] `editorconfig`
            - [ ] `src/misc/editorconfig.sh`
            - [ ] `powershell/Invoke-GenerateEditorConfig.ps1`

## Directory Structure

```text
.
├── powershell
│   ├── Enter-GhqRepository.ps1
│   ├── Enter-ParentDirectory.ps1
│   ├── Invoke-ChezmoiApply.ps1
│   ├── Invoke-ChezmoiCd.ps1
│   ├── Invoke-EzaLa.ps1
│   ├── Invoke-EzaTree.ps1
│   ├── Invoke-GenerateCargoPackageList.ps1
│   ├── Invoke-GenerateEditorConfig.ps1
│   ├── Invoke-InstallCargoPackage.ps1
│   ├── Invoke-PueueClean.ps1
│   ├── Invoke-PueueCleanSuccessfulOnly.ps1
│   ├── Invoke-PueueFollow.ps1
│   ├── Invoke-PueueLog.ps1
│   ├── Invoke-RebootSecondMonitor.ps1
│   ├── Invoke-RunAfterChezmoiApply.ps1
│   ├── Invoke-RunBeforeChezmoiApply.ps1
│   └── Invoke-UpdateCargoPackage.ps1
├── scripts
│   └── pssa.ps1
├── src
│   ├── chezmoi
│   │   ├── post-apply-hook.sh
│   │   └── pre-apply-hook.sh
│   ├── generate
│   │   ├── cargo-package-list.sh
│   │   ├── pip-package-list.sh
│   │   ├── pipx-package-list.sh
│   │   └── uv-tool-list.sh
│   ├── install
│   │   ├── cargo-packages.sh
│   │   ├── gh-extensions.sh
│   │   ├── pip-packages.sh
│   │   ├── pipx-packages.sh
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
│       ├── brew.sh
│       ├── cargo-packages.sh
│       ├── chromedriver.sh
│       ├── docker-compose.sh
│       ├── fish-completions.sh
│       ├── geckodriver.sh
│       ├── mise.sh
│       ├── pip-packages.sh
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

