#!/bin/bash

#=======================
# 変数定義
#=======================

readonly PRODUCT_VERSION="1.11.1"
PRODUCT_NAME="$(basename "${0}")"
OS_INFO=$(os_info -t)

readonly UBUNTU_OS="OS type: Ubuntu"
readonly ARCH_OS="OS type: Arch Linux"
readonly MAC_OS="OS type: Mac OS"
readonly W_NAME="TanakaPC"
HOST_NAME=$(cat /etc/hostname)

USE_PUEUE=true
SKIP_OS_PKG_UPDATE=false

#=======================
# 関数定義
#=======================

# 使い方、ヘルプメッセージ
usage() {
    cat <<EOF
$PRODUCT_NAME v$PRODUCT_VERSION
Tools to update various packages and commands. (for mimikun)

Usage:
    $PRODUCT_NAME

Options:
    --skip-update             Skip OS package update
    --no-pueue                Run without pueue
    --version, -v, version    Print $PRODUCT_NAME version
    --help, -h, help          Print this help
EOF
}

# バージョン情報出力
version() {
    echo "$PRODUCT_NAME v$PRODUCT_VERSION"
}

# magic
before_sudo() {
    if ! test "$(
        sudo uname >>/dev/null
        echo $?
    )" -eq 0; then
        exit 1
    fi
}

# Ubuntu
ubuntu() {
    # Upgrade APT repogitory list
    sudo apt update
    # Upgrade APT packages
    sudo apt upgrade -y
    # Cleaning APT caches
    sudo apt autoremove -y
    sudo apt-get clean
}

# Arch Linux
arch() {
    paru -Syu
}

# Mac
mac() {
    brew_update
}

# OSごとで処理を分岐
os_pkg_update() {
    # スキップフラグがtrueの場合は処理をスキップ
    if $SKIP_OS_PKG_UPDATE; then
        return 0
    fi
    case "$OS_INFO" in
    "$UBUNTU_OS") ubuntu ;;
    "$MAC_OS") mac ;;
    "$ARCH_OS") arch ;;
    *) echo "This distro NOT support." ;;
    esac
}

# HACK: tabiew can't build
update_cargo_tabiew() {
    echo "compiling \"tabiew\" takes a SO LONG time"
    echo "can't install it from crates.io"
}

use_pueue() {
    echo "rustup update"
    rust_task_id=$(pueue add -p -- "rustup update")

    echo "deno upgrade"
    pueue add -- "deno upgrade"

    echo "bun upgrade"
    pueue add -- "bun upgrade"

    echo "mise upgrade"
    mise_task_id=$(pueue add -p -- "mise upgrade")

    echo "tldr --update"
    pueue add -- "tldr --update"

    echo "gh extensions upgrade --all"
    pueue add -- "gh extensions upgrade --all"

    echo "flyctl version upgrade"
    pueue add -- "flyctl version upgrade"

    echo "update_pnpm"
    pueue add -- "update_pnpm"

    echo "update mise tools"
    pvim_task_id=$(pueue add -p --after "$mise_task_id" -- "update_mise paleovim-master --use-pueue")
    pueue add --after "$pvim_task_id" -- "update_mise paleovim-latest --use-pueue"
    pueue add --after "$mise_task_id" -- "update_mise zig-master --use-pueue"

    echo "update neovim managed by bob"
    bob_task_id=$(pueue add -p -- "bob use latest")
    bob_task_id=$(pueue add -p --after "$bob_task_id" -- "bob update nightly")
    bob_task_id=$(pueue add -p --after "$bob_task_id" -- "bob use nightly")
    bob_task_id=$(pueue add -p --after "$bob_task_id" -- "bob update stable")
    bob_task_id=$(pueue add -p --after "$bob_task_id" -- "bob update latest")
    pueue add --after "$bob_task_id" -- "bob install head"

    echo "fisher update"
    fish -c 'fisher update'

    echo "update_cargo_packages"
    cargo_outdated_pkgs=$(cargo install-update -l | grep "Yes" | cut -d " " -f 1)
    echo "Update these packages:"
    echo "$cargo_outdated_pkgs"
    for i in $cargo_outdated_pkgs; do
        case "$i" in
        "tabiew") update_cargo_tabiew ;;
        *) task_id=$(pueue add -p --after "$rust_task_id" -- "cargo install $i") ;;
        esac
    done

    echo "generate_cargo_package_list"
    if [ -n "$task_id" ]; then
        pueue add --after "$task_id" -- "generate_cargo_package_list"
    else
        pueue add -- "generate_cargo_package_list"
    fi

    echo "update_fish_completions"
    update_fish_completions

    echo "gup update"
    task_id=$(pueue add -p -- "gup update")

    echo "gup export"
    pueue add --after "$task_id" -- "gup export"

    echo "update aqua"
    aqua_task_id=$(pueue add -p -- "aqua update-aqua")
    aqua_task_id=$(pueue add --after "$aqua_task_id" -p -- "aqua install --all")
    aqua_task_id=$(pueue add --after "$aqua_task_id" -p -- "aqua update")
    aqua_task_id=$(pueue add --after "$aqua_task_id" -p -- "aqua install --all")
    pueue add --after "$aqua_task_id" -- "aqua vacuum"

    echo "sunbeam extension upgrade --all"
    pueue add -- "sunbeam extension upgrade --all"
}

no_pueue() {
    echo "rustup update"
    rustup update

    echo "deno upgrade"
    deno upgrade

    echo "bun upgrade"
    bun upgrade

    echo "mise upgrade"
    mise upgrade

    echo "tldr --update"
    tldr --update

    echo "gh extensions upgrade --all"
    gh extensions upgrade --all

    echo "flyctl version upgrade"
    flyctl version upgrade

    echo "update_pnpm"
    update_pnpm

    echo "update mise tools"
    update_mise paleovim-master
    update_mise paleovim-latest
    update_mise zig-master

    echo "update neovim managed by bob"
    bob use latest
    bob update nightly
    bob use nightly
    bob update stable
    bob update latest
    bob install head

    echo "fisher update"
    fish -c 'fisher update'

    echo "update_cargo_packages"
    update_cargo_packages

    echo "generate_cargo_package_list"
    generate_cargo_package_list

    echo "update_fish_completions"
    update_fish_completions

    echo "gup update"
    gup update

    echo "gup export"
    gup export

    echo "update aqua"
    aqua update-aqua
    aqua install --all
    aqua update
    aqua install --all
    aqua vacuum

    echo "sunbeam extension upgrade --all"
    sunbeam extension upgrade --all
}

other() {
    echo "update_docker_compose"
    update_docker_compose

    echo "update_chromedriver"
    update_chromedriver

    echo "update_geckodriver"
    update_geckodriver

    echo "update_twitch_cli"
    update_twitch_cli
}

reboot_check() {
    # ファイルがあれば再起動を促す
    if test -e /var/run/reboot-required; then
        # WSL かチェックする
        if test ! -e /proc/sys/fs/binfmt_misc/WSLInterop; then
            echo "\"/var/run/reboot-required\" exists. Reboot the system?(recommend)"
            re_boot
        fi
    fi
}

main() {

    # オプション解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
        -h | --help | help)
            usage
            exit 0
            ;;
        -v | --version | version)
            version
            exit 0
            ;;
        --no-pueue)
            USE_PUEUE=false
            shift
            ;;
        --skip-update)
            SKIP_OS_PKG_UPDATE=true
            shift
            ;;
        *)
            break
            ;;
        esac
    done

    # 共通処理
    os_pkg_update

    # pueueフラグに基づく処理
    if $USE_PUEUE; then
        use_pueue
    else
        no_pueue
    fi

    # 残りの共通処理
    other

    if [ "$HOST_NAME" == $W_NAME ]; then
        echo "This is Work-PC!!!"
        echo "Run Work-PC only update tasks"
        deps_update
    fi

    reboot_check
}

#=======================
# メイン処理
#=======================
before_sudo

main "$@"
