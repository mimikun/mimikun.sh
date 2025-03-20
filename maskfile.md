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
