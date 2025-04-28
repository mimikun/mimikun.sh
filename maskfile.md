# Tasks for dotfiles

Using [mask](https://github.com/jacobdeichert/mask)

## fixgit

> Delete .git\index.lock (Windows Only)

```bash
echo "Linux is not support!"
```

```powershell
if (Test-Path .\.git\index.lock) {
    Remove-Item .\git\index.lock
}
```

## patch

> Create a patch and copy it to windows

```bash
mask clean
mask diff-patch
mask copy2win-patch
```

```powershell
mask clean
mask diff-patch
mask copy2win-patch
```

## diff-patch

> Create a patch

```bash
PRODUCT_NAME="mimikun-sh"
DEFAULT_REMOTE="origin"
DEFAULT_BRANCH="master"
TODAY=$(date +'%Y%m%d')
BRANCH_NAME=$(git branch --show-current)

if [[ "$BRANCH_NAME" = "$DEFAULT_BRANCH" ]] || [[ "$BRANCH_NAME" = "patch-"* ]]; then
    echo "This branch is $DEFAULT_BRANCH or patch branch"

    for p in "$PRODUCT_NAME" "." "$TODAY" "." "patch"; do
        PATCH_NAME+=$p
    done
else
    echo "This branch is uniq feat branch"
    REPLACED_BRANCH_NAME="$(sed -e "s/\//_/g" $BRANCH_NAME)"

    for p in "$PRODUCT_NAME" "_" "$REPLACED_BRANCH_NAME" "." "$TODAY" "." "patch"; do
        PATCH_NAME+=$p
    done
fi

echo "patch file name: $PATCH_NAME"
git diff "$DEFAULT_REMOTE/$DEFAULT_BRANCH" >"$PATCH_NAME"
```

```powershell
$product_name = "mimikun-sh-windows"
$default_remote = "origin"
$default_branch = "master"
$today = Get-Date -UFormat '%Y%m%d'
$branch_name = (git branch --show-current)

if (($branch_name -eq $default_branch) -or ($branch_name -match "^patch-*")) {
    Write-Output "This branch is $default_branch or patch branch"
    $patch_name = "$product_name.$today.patch"
} else {
    $branch_name = $branch_name -replace "/", "-"

    Write-Output "This branch is uniq feat branch"
    $patch_name = "$product_name.$branch_name.$today.patch"
}

$TempMyOutputEncode=[System.Console]::OutputEncoding
[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8

Write-Output "patch file name: $patch_name"
git diff "$default_remote/$default_branch" | Out-File -Encoding default -FilePath $patch_name

[System.Console]::OutputEncoding=$TempMyOutputEncode
```

## patch-branch

> Create a patch branch

```bash
TODAY=$(date +'%Y%m%d')
git switch -c "patch-$TODAY"
```

```powershell
$TODAY = Get-Date -UFormat '%Y%m%d'
git switch -c "patch-$today"
```

## switch-master

> Switch to DEFAULT branch

```bash
DEFAULT_BRANCH="master"
git switch "$DEFAULT_BRANCH"
```

```powershell
$DEFAULT_BRANCH = "master"
git switch $DEFAULT_BRANCH
```

## delete-branch

> Delete patch branch

```bash
mask clean
mask switch-master
git branch --list "patch*" | xargs -n 1 git branch -D
```

```powershell
mask clean
mask switch-master
git branch --list "patch*" | ForEach-Object{ $_ -replace " ", "" } | ForEach-Object { git branch -D $_ }
```

## clean

> Run clean

```bash
# patch
rm -f ./*.patch

# zip file
rm -f ./*.zip
```

```powershell
Remove-Item *.patch
Remove-Item *.zip
```

## copy2win-patch

> Copy patch to Windows

```bash
cp *.patch $WIN_HOME/Downloads/
```

```powershell
$TempMyOutputEncode=[System.Console]::OutputEncoding
[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8

Copy-Item -Path .\*.patch -Destination $env:USERPROFILE\Downloads

[System.Console]::OutputEncoding=$TempMyOutputEncode
```
## commit

> Run commit with commitizen

```bash
pnpm run commit
```

```powershell
pnpm run commit
```

## test

```bash
mask lint
```

```powershell
mask lint
```

## lint

> Run lints

```bash
mask textlint
mask typo-check
mask pwsh-test
mask shell-lint
```

```powershell
mask textlint
mask typo-check
mask pwsh-test
mask shell-lint
```

## textlint

> Run textlint

```bash
pnpm run textlint
```

```powershell
pnpm run textlint
```

## typo-check

> Run typos

```bash
typos .
```

```powershell
typos .
```

## pwsh-test

> Run Invoke-PSScriptAnalyzer

```bash
echo "Run PowerShell ScriptAnalyzer"
pwsh ./scripts/pssa.ps1
```

```powershell
Write-Output "Run PowerShell ScriptAnalyzer"
Get-ChildItem -Recurse |
    Where-Object {
        $_.Name -match "\.ps1$" -and
        $_.FullName -notmatch "\\node_modules\\"
    } |
    ForEach-Object {
        Write-Output $_.FullName
        Invoke-ScriptAnalyzer -Severity Warning $_.FullName
    }
```

## shell-lint

> Run shell lint (Linux only)

```bash
shellcheck --shell=bash --external-sources \
	utils/*

shfmt --language-dialect bash --diff \
	./**/*
```

```powershell
Write-Output "Windows is not support!"
```

## fmt

```bash
mask format
```

```powershell
mask format
```

## format

> Run format

```bash
mask shell-format
```

```powershell
mask shell-format
```

## shell-format

> Run shfmt (Linux only)

```bash
shfmt --language-dialect bash --write \
	./**/*
```

```powershell
Write-Output "Windows is not support!"
```

## changelog

> Add commit message up to `origin/master` to CHANGELOG.md

```bash
TODAY=$(date "+%Y.%m.%d")
RESULT_FILE="CHANGELOG.md"
LATEST_GIT_TAG=$(git tag | head -n 1)
GIT_LOG=$(git log "$LATEST_GIT_TAG..HEAD" --pretty=format:"%B")

function generate_changelog() {
    echo "## [v$TODAY]"
    echo ""
    echo "$GIT_LOG" |
        # Remove renovate commit
        sed -e 's/.*chore(deps): update dependency.*//g' |
        # Remove blank line
        sed -e '/^$/d' |
        # Make list
        sed -e 's/^/- /g'
    echo ""
    echo "### Added - 新機能について"
    echo ""
    echo "なし"
    echo ""
    echo "### Changed - 既存機能の変更について"
    echo ""
    echo "なし"
    echo ""
    echo "### Removed - 今回で削除された機能について"
    echo ""
    echo "なし"
    echo ""
    echo "### Fixed - 不具合修正について"
    echo ""
    echo "なし"
    echo ""
}

generate_changelog >>$RESULT_FILE
```

```powershell
Write-Output "Windows is not support now!"
```

## generate-commit-msg

> Add commit message up to `origin/master` for mask to CHANGELOG.md

```bash
RESULT_FILE="CHANGELOG.md"
LATEST_GIT_TAG=$(git tag | head -n 1)
GIT_LOG=$(git log "$LATEST_GIT_TAG..HEAD" --pretty=format:"%B")
HOSTNAME=$(hostname)

function generate_commit_msg () {
    echo "## run"
    echo ""
    echo '```bash'
    echo 'git commit -m "WIP:--------------------------------------------------------------------------" --allow-empty --no-verify'
    echo "$GIT_LOG" |
        # Remove blank line
        sed -e '/^$/d' |
        # Remove STARTUPTIME.md commit msg
        sed -e 's/.*STARTUPTIME.md.*//g' |
        # Remove DROP commit msg
        sed -e 's/.*DROP.*//g' |
        # Remove renovate commit
        sed -e 's/.*chore(deps): update dependency.*//g' |
        # Remove blank line
        sed -e '/^$/d' |
        sed -e 's/^/git commit -m "WIP:/g' |
        sed -e 's/$/" --allow-empty --no-verify/g'
    echo 'git commit -m "WIP:--------------------------------------------------------------------------" --allow-empty --no-verify'
    echo '```'
}

generate_commit_msg >>$RESULT_FILE
git add "$RESULT_FILE"
git commit -m "docs(changelog): add maskfile msg" --no-verify
```

```powershell
Write-Output "Windows is not support now!"
```

## morning-routine

> Run workday morning routine

```bash
git fetch --all --prune --tags --prune-tags
mask delete-branch
git pull
mask patch-branch
```

```powershell
git cleanfetch
mask delete-branch
git pull
```

## pab

> Create a patch branch (alias)

```bash
mask patch-branch
```

```powershell
mask patch-branch
```

## deleb

> Delete patch branch (alias)

```bash
mask delete-branch
```

```powershell
mask delete-branch
```

## push

> Push to remote repository (Linux Only)

```bash
host_name=$(cat /etc/hostname)

if [ "$host_name" = "TanakaPC" ]; then
    echo "        THIS IS WORK-PC!!!        "
    echo "DON'T PUSH TO REMOTE REPOSITORY!!!"
else
    echo "Pushing to origin..."
    git fetch origin
    git push origin master
    git push origin --tags
    echo "Pushing to codeberg..."
    git fetch codeberg
    git push codeberg master
    git push codeberg --tags
fi
```

```powershell
Write-Output "Windows is not support now!"
```

## install

> Run install

```bash
before_sudo() {
    if ! test "$(
        sudo uname >>/dev/null
        echo $?
    )" -eq 0; then
        exit 1
    fi
}

# Chezmoi
# install -m 755 ./src/chezmoi/post-apply-hook.sh "$HOME/.local/bin/chezmoi-post-apply-hook"
# install -m 755 ./src/chezmoi/pre-apply-hook.sh "$HOME/.local/bin/chezmoi-pre-apply-hook"
# NOTE: Deprecated
install -m 755 ./src/chezmoi/post-apply-hook.sh "$HOME/.local/bin/chezmoi_post_apply_hook"
install -m 755 ./src/chezmoi/pre-apply-hook.sh "$HOME/.local/bin/chezmoi_pre_apply_hook"

# Generate
# install -m 755 ./src/generate/cargo-package-list.sh "$HOME/.local/bin/generate-cargo-package-list"
# install -m 755 ./src/generate/pip-package-list.sh "$HOME/.local/bin/generate-pip-package-list"
# install -m 755 ./src/generate/pipx-package-list.sh "$HOME/.local/bin/generate-pipx-package-list"
# install -m 755 ./src/generate/uv-tool-list.sh "$HOME/.local/bin/generate-uv-tool-list"
# NOTE: Deprecated
install -m 755 ./src/generate/cargo-package-list.sh "$HOME/.local/bin/generate_cargo_package_list"
install -m 755 ./src/generate/pip-package-list.sh "$HOME/.local/bin/generate_pip_package_list"
install -m 755 ./src/generate/pipx-package-list.sh "$HOME/.local/bin/generate_pipx_package_list"
install -m 755 ./src/generate/uv-tool-list.sh "$HOME/.local/bin/generate_uv_tool_list"

# Install
# install -m 755 ./src/install/cargo-packages.sh "$HOME/.local/bin/install-cargo-packages"
# install -m 755 ./src/install/gh-extensions.sh "$HOME/.local/bin/install-gh-extensions"
# install -m 755 ./src/install/pip-packages.sh "$HOME/.local/bin/install-pip-packages"
# install -m 755 ./src/install/pipx-packages.sh "$HOME/.local/bin/install-pipx-packages"
# install -m 755 ./src/install/uv-tools.sh "$HOME/.local/bin/install-uv-tools"
# NOTE: Deprecated
install -m 755 ./src/install/cargo-packages.sh "$HOME/.local/bin/install_cargo_packages"
install -m 755 ./src/install/gh-extensions.sh "$HOME/.local/bin/install_gh_extensions"
install -m 755 ./src/install/pip-packages.sh "$HOME/.local/bin/install_pip_packages"
install -m 755 ./src/install/pipx-packages.sh "$HOME/.local/bin/install_pipx_packages"
install -m 755 ./src/install/uv-tools.sh "$HOME/.local/bin/install_uv_tools"

# Misc
install -m 755 ./src/misc/cpat.sh "$HOME/.local/bin/cpat"
install -m 755 ./src/misc/editorconfig.sh "$HOME/.local/bin/editorconfig"
install -m 755 ./src/misc/numeronym.sh "$HOME/.local/bin/numeronym"
install -m 755 ./src/misc/pcd.sh "$HOME/.local/bin/pcd"
# install -m 755 ./src/misc/read-confirm.sh "$HOME/.local/bin/read-confirm"
# install -m 755 ./src/misc/re-boot.sh "$HOME/.local/bin/re-boot"
# install -m 755 ./src/misc/shut-down.sh "$HOME/.local/bin/shut-down"
# NOTE: Deprecated
install -m 755 ./src/misc/read-confirm.sh "$HOME/.local/bin/read_confirm"
install -m 755 ./src/misc/re-boot.sh "$HOME/.local/bin/re_boot"
install -m 755 ./src/misc/shut-down.sh "$HOME/.local/bin/shut_down"

# Update
# install -m 755 ./src/update/cargo-packages.sh "$HOME/.local/bin/update-cargo-packages"
# install -m 755 ./src/update/pip-packages.sh "$HOME/.local/bin/update-pip-packages"
# install -m 755 ./src/update/brew.sh "$HOME/.local/bin/update-brew"
# install -m 755 ./src/update/mise.sh "$HOME/.local/bin/update-mise"
# install -m 755 ./src/update/chromedriver.sh "$HOME/.local/bin/update-chromedriver"
# install -m 755 ./src/update/geckodriver.sh "$HOME/.local/bin/update-geckodriver"
# install -m 755 ./src/update/docker-compose.sh "$HOME/.local/bin/update-docker-compose"
# install -m 755 ./src/update/twitch-cli.sh "$HOME/.local/bin/update-twitch-cli"
# install -m 755 ./src/update/fish-completions.sh "$HOME/.local/bin/update-fish-completions"
# install -m 755 ./src/update/various.sh "$HOME/.local/bin/update-various"
# NOTE: Deprecated
install -m 755 ./src/update/cargo-packages.sh "$HOME/.local/bin/update_cargo_packages"
install -m 755 ./src/update/pip-packages.sh "$HOME/.local/bin/update_pip_packages"
install -m 755 ./src/update/brew.sh "$HOME/.local/bin/update_brew"
install -m 755 ./src/update/mise.sh "$HOME/.local/bin/update_mise"
install -m 755 ./src/update/chromedriver.sh "$HOME/.local/bin/update_chromedriver"
install -m 755 ./src/update/geckodriver.sh "$HOME/.local/bin/update_geckodriver"
install -m 755 ./src/update/twitch-cli.sh "$HOME/.local/bin/update_docker_compose"
install -m 755 ./src/update/docker-compose.sh "$HOME/.local/bin/update_twitch_cli"
install -m 755 ./src/update/fish-completions.sh "$HOME/.local/bin/update_fish_completions"
install -m 755 ./src/update/various.sh "$HOME/.local/bin/vup"
```


```powershell
Copy-Item -Path .\powershell\* -Destination "$env:USERPROFILE\Tools\"
```
