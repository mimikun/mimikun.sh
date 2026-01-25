# Mastodonバックアップスクリプト実装計画書

## ドキュメント情報

- **作成日**: 2025-12-29
- **プロジェクト**: mimikun.sh
- **対象ブランチ**: feat/mastodon-backup-script
- **要件ドキュメント**: `docs/add-mastodon-backup-scripts.md`
- **ステータス**: 計画段階

## 目次

1. [概要](#概要)
2. [アーキテクチャ設計](#アーキテクチャ設計)
3. [ファイル構成](#ファイル構成)
4. [詳細設計](#詳細設計)
5. [環境変数仕様](#環境変数仕様)
6. [実装ステップ](#実装ステップ)
7. [セキュリティ](#セキュリティ)
8. [テスト計画](#テスト計画)
9. [運用手順](#運用手順)

## 概要

### 目的

Mastodonサーバーの安定運用に必要なバックアップおよびメンテナンス機能を提供する統合スクリプトシステムを構築します。

### 主要機能

1. **日次データベースバックアップ**
   - PostgreSQLデータベースの日次自動バックアップ
   - BackBlaze B2クラウドストレージへの自動アップロード
   - 30日間の保持期間管理（古いバックアップの自動削除）
   - systemd.timer による毎日午前3:00の自動実行

2. **月次完全バックアップ**
   - PostgreSQL全データベースの月次フルバックアップ（pg_dumpall）
   - 12ヶ月（365日）の長期保持
   - 毎月1日午前4:00の自動実行

3. **ソフトウェア自動更新**
   - システムパッケージ更新（apt update/upgrade）
   - 開発ツール更新（mise self-update）
   - オプションでsystemd timer統合（週次実行）

4. **Mastodon更新ガイド**
   - バージョンアップ手順のクイックリファレンス表示
   - 実行はせず、手順のプリントのみ

### 設計原則

- **既存コードベース準拠**: `src/update/various.sh` のコーディングスタイルとパターンに従う
- **柔軟性**: 手動実行とsystemd自動実行の両方をサポート
- **セキュリティファースト**: 認証情報の安全な管理（600パーミッション、.gitignore）
- **保守性**: モジュラー設計により、各機能を独立してテスト・保守可能
- **ログと監視**: 統一的なログ出力とsystemd journald統合

### 確定済み設計判断

| 項目 | 決定内容 | 理由 |
|------|---------|------|
| スクリプト保存場所 | `src/mastodon/` | 既存の `src/update/`, `src/install/` と一貫性を保つ |
| DB名設定方法 | 環境変数 `DB_NAME` | 柔軟性と再利用性の向上 |
| B2バケット構成 | 日次と月次で別バケット | 保持期間ポリシーの独立管理 |
| 認証方法 | 環境変数ファイル (`/etc/mastodon/backup.env`) | systemd統合とセキュリティのバランス |
| 保持期間 | 日次30日、月次365日 | コストと復元可能性のバランス |
| 日次圧縮形式 | `pg_dump -Fc` (カスタムフォーマット) | 既に圧縮されており、pg_restore で柔軟に復元可能 |
| 月次圧縮形式 | `pg_dumpall` + gzip | 全データベースのSQL形式、可読性と移植性 |

## アーキテクチャ設計

### システム構成図

```
┌─────────────────────────────────────────────────────────────┐
│                      systemd Timers                          │
│  ┌──────────────┐  ┌───────────────┐  ┌──────────────┐     │
│  │ daily.timer  │  │ monthly.timer │  │ update.timer │     │
│  │  (3:00 AM)   │  │  (4:00 AM/1st)│  │  (weekly)    │     │
│  └──────┬───────┘  └───────┬───────┘  └──────┬───────┘     │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│                    Main Scripts                              │
│  ┌───────────────┐  ┌────────────────┐  ┌───────────────┐  │
│  │backup-db-     │  │backup-db-      │  │update-        │  │
│  │daily.sh       │  │monthly.sh      │  │software.sh    │  │
│  └───────┬───────┘  └────────┬───────┘  └───────────────┘  │
└──────────┼──────────────────┼──────────────────────────────┘
           │                  │
           └────────┬─────────┘
                    ▼
┌─────────────────────────────────────────────────────────────┐
│                 Shared Libraries                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ common.sh    │  │ backup-      │  │ b2-upload.sh │      │
│  │ (logging,    │  │ core.sh      │  │ (B2 upload,  │      │
│  │  error,env)  │  │ (pg_dump)    │  │  cleanup)    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                    ▼                  ▼
┌──────────────────────┐  ┌──────────────────────────────────┐
│   PostgreSQL DB      │  │    BackBlaze B2 Storage          │
│  (Mastodon data)     │  │  ┌────────────┐ ┌────────────┐   │
│                      │  │  │ daily/     │ │ monthly/   │   │
│                      │  │  │ (30 days)  │ │ (365 days) │   │
└──────────────────────┘  └──┴────────────┴─┴────────────┴───┘
```

### データフロー

**日次バックアップフロー:**
```
1. Timer trigger (3:00 AM)
   ↓
2. backup-db-daily.sh 起動
   ↓
3. 環境変数検証 (common.sh)
   ↓
4. PostgreSQL接続・バックアップ (backup-core.sh)
   pg_dump -Fc → /var/tmp/mastodon-backup-daily/daily_*.sql
   ↓
5. gzip圧縮 (backup-core.sh)
   → daily_*.sql.gz
   ↓
6. B2アップロード (b2-upload.sh)
   → B2_BUCKET_DAILY
   ↓
7. 古いバックアップ削除 (b2-upload.sh)
   30日以上前のファイルを削除
   ↓
8. ローカルファイル削除
   ↓
9. ログ出力・完了
```

## ファイル構成

### ディレクトリ構造

```
src/mastodon/                          # 新規作成ディレクトリ
├── lib/                               # 共通ライブラリ
│   ├── common.sh                      # 共通関数（ログ、エラー処理、環境変数検証）
│   ├── backup-core.sh                 # PostgreSQLバックアップコア処理
│   └── b2-upload.sh                   # BackBlaze B2アップロード・削除処理
│
├── backup-db-daily.sh                 # 日次バックアップメインスクリプト
├── backup-db-monthly.sh               # 月次バックアップメインスクリプト
├── update-software.sh                 # ソフトウェア更新スクリプト
├── print-upgrade-guide.sh             # Mastodon更新ガイド表示
│
└── systemd/                           # systemd設定ファイル
    ├── mastodon-backup-daily.service
    ├── mastodon-backup-daily.timer
    ├── mastodon-backup-monthly.service
    ├── mastodon-backup-monthly.timer
    ├── mastodon-update.service
    ├── mastodon-update.timer
    └── mastodon-backup.env.example    # 環境変数テンプレート
```

### ファイルサイズ見積もり

| ファイル | 想定行数 | 複雑度 | 説明 |
|---------|---------|--------|------|
| `lib/common.sh` | ~80行 | 低 | 基本的なユーティリティ関数 |
| `lib/backup-core.sh` | ~120行 | 中 | PostgreSQLバックアップロジック |
| `lib/b2-upload.sh` | ~150行 | 中 | B2アップロード・クリーンアップ |
| `backup-db-daily.sh` | ~100行 | 中 | メインスクリプト（共通パターン） |
| `backup-db-monthly.sh` | ~100行 | 中 | メインスクリプト（共通パターン） |
| `update-software.sh` | ~80行 | 低 | apt/mise更新 |
| `print-upgrade-guide.sh` | ~150行 | 低 | テキスト出力のみ |

## 詳細設計

### 1. 共通ライブラリ: `lib/common.sh`

#### 役割
全スクリプトで共有する基盤機能を提供します。

#### 主要関数

**ログ出力:**
```bash
log_info(message)     # 情報ログ
log_error(message)    # エラーログ
log_success(message)  # 成功ログ
```

**コマンドチェック:**
```bash
check_command(cmd_name) → 0 (成功) | 1 (失敗)
```

**環境変数検証:**
```bash
validate_env(var1, var2, ...) → 0 (全て設定済み) | 1 (未設定あり)
```

**ディレクトリ管理:**
```bash
ensure_directory(path) → 0 (成功) | 1 (失敗)
```

**初期化:**
```bash
init_script()  # ログディレクトリ作成など
```

#### グローバル変数

```bash
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_DIR="/var/log/mastodon-backup"
readonly TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
```

#### 依存関係
- なし（純粋なBash関数のみ）

### 2. バックアップコア: `lib/backup-core.sh`

#### 役割
PostgreSQLデータベースのバックアップ処理を実装します。

#### 主要関数

**PostgreSQLバックアップ:**
```bash
backup_postgresql(backup_type, output_file)
  - backup_type: "daily" | "monthly"
  - output_file: 出力先パス
  → 0 (成功) | 1 (失敗)
```

**実装詳細:**
- **日次**: `pg_dump -Fc -v` (カスタムフォーマット、既に圧縮済み)
- **月次**: `pg_dumpall -v` (全データベース、SQL形式)

**圧縮処理:**
```bash
compress_backup(input_file, output_file)
  → 0 (成功) | 1 (失敗)
```

**ファイル名生成:**
```bash
generate_backup_filename(prefix)
  - prefix: "daily" | "monthly"
  → "{prefix}_{db_name}_{hostname}_{YYYYMMDD_HHMMSS}.sql"
```

#### 使用する環境変数

```bash
DB_NAME="${DB_NAME:-mastodon_production}"
PG_USER="${PG_USER:-mastodon}"
PG_HOST="${PG_HOST:-localhost}"
PG_PORT="${PG_PORT:-5432}"
PG_PASSWORD  # 必須、デフォルトなし
```

#### 依存関係
- PostgreSQL client tools: `pg_dump`, `pg_dumpall`
- Compression tool: `gzip`
- `lib/common.sh`

### 3. B2アップロード: `lib/b2-upload.sh`

#### 役割
BackBlaze B2クラウドストレージへのアップロードと保持期間管理を実装します。

#### 主要関数

**アップロード:**
```bash
upload_to_b2(local_file, bucket_name)
  → 0 (成功) | 1 (失敗)
```

**実装戦略:**
- b2 CLI利用可能時: `b2 upload-file`
- rclone利用可能時: `rclone copy`
- どちらも不可: エラー

**内部実装関数:**
```bash
_upload_with_b2_cli(local_file, bucket_name, remote_filename)
_upload_with_rclone(local_file, bucket_name, remote_filename)
```

**古いバックアップ削除:**
```bash
cleanup_old_backups(bucket_name, retention_days)
  - retention_days: 30 (日次) | 365 (月次)
  → 0 (成功) | 1 (失敗)
```

**削除ロジック:**
- ファイル名から日付を抽出（YYYYMMDD部分）
- cutoff_date = 現在日時 - retention_days
- cutoff_date より古いファイルを削除

#### 使用する環境変数

```bash
B2_APPLICATION_KEY_ID  # 必須
B2_APPLICATION_KEY     # 必須
B2_BUCKET_DAILY        # 日次バックアップ用
B2_BUCKET_MONTHLY      # 月次バックアップ用
```

#### 依存関係
- `b2` CLI または `rclone` (いずれか必須)
- `lib/common.sh`

### 4. メインスクリプト: `backup-db-daily.sh`

#### 役割
日次バックアップ処理のオーケストレーション（実行制御）を行います。

#### 処理フロー

1. **初期化**
   - 共通ライブラリ読み込み
   - オプション解析
   - ログ初期化

2. **環境変数検証**
   - 必須変数チェック（PG_PASSWORD, B2_*, など）
   - 未設定の場合はエラーで終了

3. **作業ディレクトリ準備**
   - `/var/tmp/mastodon-backup-daily/` 作成

4. **バックアップ実行**
   - `backup_postgresql("daily", backup_file)`
   - 失敗時は即座に終了

5. **圧縮**
   - `compress_backup(backup_file, compressed_file)`

6. **B2アップロード** (--no-upload 時はスキップ)
   - `upload_to_b2(compressed_file, B2_BUCKET_DAILY)`
   - 成功後、ローカルファイル削除

7. **古いバックアップ削除** (--no-cleanup 時はスキップ)
   - `cleanup_old_backups(B2_BUCKET_DAILY, 30)`

8. **完了ログ出力**

#### オプション

```bash
--no-upload      # B2アップロードをスキップ（ローカル保存のみ）
--no-cleanup     # 古いバックアップ削除をスキップ
--help, -h       # ヘルプメッセージ表示
--version, -v    # バージョン表示
```

#### 既存パターン準拠

```bash
#!/bin/bash

readonly PRODUCT_VERSION="1.0.0"
PRODUCT_NAME="$(basename "${0}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 共通ライブラリ読み込み
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/backup-core.sh"
source "$SCRIPT_DIR/lib/b2-upload.sh"

usage() { ... }
version() { ... }
run_daily_backup() { ... }

init_script
run_daily_backup "$@"
```

### 5. systemd統合

#### タイマーファイル: `mastodon-backup-daily.timer`

```ini
[Unit]
Description=Mastodon Daily Database Backup Timer
Requires=mastodon-backup-daily.service

[Timer]
# 毎日午前3:00に実行
OnCalendar=*-*-* 03:00:00
Persistent=true      # システム停止中に実行予定時刻を過ぎた場合、起動後すぐ実行
AccuracySec=1min     # 1分以内の精度

[Install]
WantedBy=timers.target
```

#### サービスファイル: `mastodon-backup-daily.service`

```ini
[Unit]
Description=Mastodon Daily Database Backup
After=postgresql.service
Requires=postgresql.service

[Service]
Type=oneshot
User=mastodon
Group=mastodon
EnvironmentFile=/etc/mastodon/backup.env
ExecStart=/home/mimikun/ghq/github.com/mimikun/mimikun.sh/src/mastodon/backup-db-daily.sh
StandardOutput=journal
StandardError=journal
SyslogIdentifier=mastodon-backup-daily

# セキュリティ設定
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log/mastodon-backup /var/tmp/mastodon-backup-daily

# タイムアウト（大きなDBに備えて）
TimeoutStartSec=3600

[Install]
WantedBy=multi-user.target
```

#### セキュリティ設定の説明

| 設定 | 意味 | 効果 |
|------|------|------|
| `NoNewPrivileges=true` | 権限昇格を禁止 | setuidバイナリ実行を防ぐ |
| `PrivateTmp=true` | 独立した/tmp使用 | 他プロセスとの干渉防止 |
| `ProtectSystem=strict` | システムディレクトリ読み取り専用 | /usr, /boot などへの書き込み禁止 |
| `ProtectHome=true` | ホームディレクトリ保護 | 意図しないホーム書き込み防止 |
| `ReadWritePaths=...` | 書き込み許可パス明示 | 必要最小限のパスのみ許可 |

## 環境変数仕様

### 配置と管理

**配置場所:** `/etc/mastodon/backup.env`

**パーミッション:**
```bash
chmod 600 /etc/mastodon/backup.env
chown mastodon:mastodon /etc/mastodon/backup.env
```

**バージョン管理:**
- `.example` ファイルのみGit管理
- 実際の設定ファイルは `.gitignore` に追加

### 必須変数一覧

#### PostgreSQL接続設定

```bash
# データベース名（デフォルト: mastodon_production）
DB_NAME=mastodon_production

# PostgreSQLユーザー（デフォルト: mastodon）
PG_USER=mastodon

# PostgreSQLパスワード（必須、デフォルトなし）
PG_PASSWORD=your_secure_password_here

# PostgreSQLホスト（デフォルト: localhost）
PG_HOST=localhost

# PostgreSQLポート（デフォルト: 5432）
PG_PORT=5432
```

#### BackBlaze B2認証設定

```bash
# B2 Application Key ID（必須）
B2_APPLICATION_KEY_ID=001abc123def456789

# B2 Application Key（必須）
B2_APPLICATION_KEY=K001xyz789abcdef012345
```

#### B2バケット設定

```bash
# 日次バックアップ用バケット（必須）
B2_BUCKET_DAILY=mastodon-backup-daily

# 月次バックアップ用バケット（必須）
B2_BUCKET_MONTHLY=mastodon-backup-monthly
```

### 環境変数テンプレート

`systemd/mastodon-backup.env.example`:
```bash
# PostgreSQL接続情報
DB_NAME=mastodon_production
PG_USER=mastodon
PG_PASSWORD=CHANGE_ME_TO_SECURE_PASSWORD
PG_HOST=localhost
PG_PORT=5432

# BackBlaze B2認証情報
# B2コンソールで Application Key を作成: https://secure.backblaze.com/app_keys.htm
B2_APPLICATION_KEY_ID=CHANGE_ME_TO_YOUR_KEY_ID
B2_APPLICATION_KEY=CHANGE_ME_TO_YOUR_APPLICATION_KEY

# B2バケット名
# 事前にB2コンソールでバケットを作成しておくこと
B2_BUCKET_DAILY=mastodon-backup-daily
B2_BUCKET_MONTHLY=mastodon-backup-monthly
```

## 実装ステップ

### Phase 1: 基盤構築（優先度: 最高）

**目標:** 共通ライブラリとディレクトリ構造を確立

#### 1.1 ディレクトリ作成

```bash
# スクリプトディレクトリ
mkdir -p src/mastodon/{lib,systemd}

# ランタイムディレクトリ（本番環境）
sudo mkdir -p /var/log/mastodon-backup
sudo mkdir -p /var/tmp/mastodon-backup-{daily,monthly}
sudo chown -R mastodon:mastodon /var/log/mastodon-backup /var/tmp/mastodon-backup-*
sudo chmod 755 /var/log/mastodon-backup
sudo chmod 700 /var/tmp/mastodon-backup-*
```

#### 1.2 共通ライブラリ実装

**作成順序:**
1. `lib/common.sh` - 基盤関数（ログ、エラー処理）
2. `lib/backup-core.sh` - PostgreSQLバックアップロジック
3. `lib/b2-upload.sh` - B2アップロード・削除ロジック

**テスト方法:**
```bash
# common.sh テスト
source src/mastodon/lib/common.sh
init_script
log_info "Test message"
check_command "pg_dump"
validate_env "HOME" "USER"
```

#### 1.3 依存ツール確認

```bash
# PostgreSQL client tools
sudo apt install -y postgresql-client

# 圧縮ツール（通常は既にインストール済み）
which gzip

# BackBlaze B2 CLI (オプション1)
pip3 install b2

# または rclone (オプション2)
sudo apt install -y rclone
rclone config  # B2リモート設定
```

**検証:**
```bash
pg_dump --version
pg_dumpall --version
gzip --version
b2 version  # または rclone version
```

### Phase 2: バックアップスクリプト（優先度: 高）

**目標:** コアバックアップ機能の実装とテスト

#### 2.1 日次バックアップスクリプト

**実装:**
```bash
# ファイル作成
touch src/mastodon/backup-db-daily.sh
chmod +x src/mastodon/backup-db-daily.sh
```

**手動テスト（ローカルのみ）:**
```bash
# 環境変数設定
export DB_NAME=mastodon_production
export PG_USER=mastodon
export PG_PASSWORD='your_password'
export PG_HOST=localhost
export PG_PORT=5432

# ローカルバックアップテスト（B2アップロードなし）
./src/mastodon/backup-db-daily.sh --no-upload

# バックアップファイル確認
ls -lh /var/tmp/mastodon-backup-daily/
file /var/tmp/mastodon-backup-daily/*.sql.gz
```

**B2アップロードテスト:**
```bash
# B2環境変数追加
export B2_APPLICATION_KEY_ID='your_key_id'
export B2_APPLICATION_KEY='your_key'
export B2_BUCKET_DAILY='mastodon-backup-daily'

# フルテスト（アップロード含む）
./src/mastodon/backup-db-daily.sh

# B2バケット確認
b2 ls mastodon-backup-daily
```

#### 2.2 月次バックアップスクリプト

**実装:**
```bash
# ファイル作成
touch src/mastodon/backup-db-monthly.sh
chmod +x src/mastodon/backup-db-monthly.sh
```

**手動テスト:**
```bash
# 月次バックアップはpg_dumpallを使用（全データベース）
export B2_BUCKET_MONTHLY='mastodon-backup-monthly'

./src/mastodon/backup-db-monthly.sh --no-upload
ls -lh /var/tmp/mastodon-backup-monthly/
```

**注意点:**
- pg_dumpall は通常、postgres スーパーユーザー権限が必要
- PG_USER を postgres に変更する必要があるかもしれない

### Phase 3: systemd統合（優先度: 高）

**目標:** 自動実行の仕組みを構築

#### 3.1 systemdファイル作成

```bash
# service/timerファイル作成
touch src/mastodon/systemd/mastodon-backup-{daily,monthly}.{service,timer}
touch src/mastodon/systemd/mastodon-update.{service,timer}
touch src/mastodon/systemd/mastodon-backup.env.example
```

#### 3.2 環境変数ファイル配置

```bash
# 環境変数ディレクトリ作成
sudo mkdir -p /etc/mastodon

# テンプレートをコピーして編集
sudo cp src/mastodon/systemd/mastodon-backup.env.example /etc/mastodon/backup.env
sudo nano /etc/mastodon/backup.env  # 実際の値を入力

# パーミッション設定（重要！）
sudo chmod 600 /etc/mastodon/backup.env
sudo chown mastodon:mastodon /etc/mastodon/backup.env
```

#### 3.3 systemdファイル配置

```bash
# systemdディレクトリにコピー
sudo cp src/mastodon/systemd/*.service /etc/systemd/system/
sudo cp src/mastodon/systemd/*.timer /etc/systemd/system/

# デーモンリロード
sudo systemctl daemon-reload
```

#### 3.4 systemd有効化とテスト

**サービス単体テスト:**
```bash
# 日次バックアップサービス手動実行
sudo systemctl start mastodon-backup-daily.service

# ステータス確認
sudo systemctl status mastodon-backup-daily.service

# ログ確認
sudo journalctl -u mastodon-backup-daily.service -n 50
sudo journalctl -u mastodon-backup-daily.service -f  # リアルタイム監視
```

**タイマー有効化:**
```bash
# タイマー有効化と起動
sudo systemctl enable mastodon-backup-daily.timer
sudo systemctl start mastodon-backup-daily.timer

sudo systemctl enable mastodon-backup-monthly.timer
sudo systemctl start mastodon-backup-monthly.timer

# タイマー一覧確認
sudo systemctl list-timers | grep mastodon

# タイマー詳細確認
sudo systemctl status mastodon-backup-daily.timer
```

### Phase 4: 補助スクリプト（優先度: 中）

**目標:** メンテナンス機能の追加

#### 4.1 ソフトウェア更新スクリプト

**実装:**
```bash
# ファイル作成
touch src/mastodon/update-software.sh
chmod +x src/mastodon/update-software.sh
```

**手動テスト:**
```bash
# apt更新のみ
sudo ./src/mastodon/update-software.sh --skip-mise

# mise更新のみ
./src/mastodon/update-software.sh --skip-apt

# 全て実行
sudo ./src/mastodon/update-software.sh
```

#### 4.2 Mastodon更新ガイド

**実装:**
```bash
# ファイル作成
touch src/mastodon/print-upgrade-guide.sh
chmod +x src/mastodon/print-upgrade-guide.sh
```

**テスト:**
```bash
./src/mastodon/print-upgrade-guide.sh
```

### Phase 5: テスト・検証（優先度: 最高）

**目標:** 本番運用前の最終確認

#### 5.1 統合テスト

**全体フロー確認:**
```bash
# 1. 日次バックアップ実行
sudo systemctl start mastodon-backup-daily.service

# 2. ログ確認
sudo journalctl -u mastodon-backup-daily.service -n 100

# 3. B2バケット確認
b2 ls mastodon-backup-daily

# 4. ローカルログ確認
tail -f /var/log/mastodon-backup/backup.log
```

#### 5.2 復元テスト（最重要！）

**テストデータベース作成:**
```bash
# テスト用DBを作成
sudo -u postgres psql
CREATE DATABASE mastodon_test OWNER mastodon;
\q
```

**復元手順:**
```bash
# 1. B2から最新バックアップをダウンロード
b2 download-file-by-name mastodon-backup-daily \
  "daily_mastodon_production_hostname_20250129_030000.sql.gz" \
  ./test-restore.sql.gz

# 2. 解凍
gunzip test-restore.sql.gz

# 3. テストDBに復元
PGPASSWORD='your_password' pg_restore \
  -h localhost \
  -U mastodon \
  -d mastodon_test \
  -v \
  test-restore.sql

# 4. 復元確認
PGPASSWORD='your_password' psql -h localhost -U mastodon -d mastodon_test -c "\dt"
```

**検証項目:**
- [ ] テーブルが正常に復元されているか
- [ ] レコード数が元のDBと一致するか
- [ ] インデックスが正常に作成されているか
- [ ] 外部キー制約が維持されているか

#### 5.3 エラーケーステスト

**PostgreSQL停止時の動作:**
```bash
# PostgreSQL停止
sudo systemctl stop postgresql

# バックアップ実行（失敗するはず）
sudo systemctl start mastodon-backup-daily.service

# エラーログ確認
sudo journalctl -u mastodon-backup-daily.service -n 50

# PostgreSQL再起動
sudo systemctl start postgresql
```

**B2認証失敗時の動作:**
```bash
# 一時的に環境変数を間違った値に変更
sudo nano /etc/mastodon/backup.env
# B2_APPLICATION_KEY を無効な値に変更

# バックアップ実行（アップロード失敗するはず）
sudo systemctl start mastodon-backup-daily.service

# エラーログ確認
sudo journalctl -u mastodon-backup-daily.service -n 50

# 環境変数を正しい値に戻す
```

## セキュリティ

### 認証情報保護

#### 環境変数ファイルのセキュリティ

**パーミッション設定:**
```bash
# /etc/mastodon/backup.env のパーミッション
-rw------- 1 mastodon mastodon 512 Dec 29 10:00 /etc/mastodon/backup.env

# 設定コマンド
sudo chmod 600 /etc/mastodon/backup.env
sudo chown mastodon:mastodon /etc/mastodon/backup.env
```

**Gitバージョン管理:**
```gitignore
# .gitignore に追加
/etc/mastodon/backup.env
src/mastodon/systemd/mastodon-backup.env

# .example ファイルのみバージョン管理
!src/mastodon/systemd/mastodon-backup.env.example
```

#### BackBlaze B2認証の最小権限設定

**Application Keyの権限:**
- **許可する操作**:
  - `writeFiles` (ファイルアップロード)
  - `deleteFiles` (古いバックアップ削除)
  - `listFiles` (ファイル一覧取得)
- **制限する操作**:
  - `readFiles` (必要に応じて許可)
  - その他の管理操作は全て拒否

**バケットごとにKeyを分離:**
```bash
# 日次バックアップ用Key
B2_DAILY_KEY_ID=001abc...
B2_DAILY_KEY=K001xyz...

# 月次バックアップ用Key
B2_MONTHLY_KEY_ID=002def...
B2_MONTHLY_KEY=K002uvw...
```

#### PostgreSQLパスワード管理

**代替認証方法（.pgpass）:**
```bash
# ~/.pgpass ファイル作成（オプション）
# ホスト:ポート:データベース:ユーザー:パスワード
localhost:5432:mastodon_production:mastodon:your_password

# パーミッション設定
chmod 600 ~/.pgpass
```

### 実行権限管理

#### systemdサービスのユーザー設定

| スクリプト | 実行ユーザー | 理由 |
|-----------|-------------|------|
| `backup-db-daily.sh` | `mastodon` | PostgreSQLアクセス、B2アップロードのみ |
| `backup-db-monthly.sh` | `mastodon` (または `postgres`) | pg_dumpall にはスーパーユーザー権限が必要な場合あり |
| `update-software.sh` | `root` | apt upgrade, system-wide更新が必要 |

#### ファイルシステム権限

**ログディレクトリ:**
```bash
drwxr-xr-x 2 mastodon mastodon 4096 Dec 29 10:00 /var/log/mastodon-backup/
```

**作業ディレクトリ:**
```bash
drwx------ 2 mastodon mastodon 4096 Dec 29 03:00 /var/tmp/mastodon-backup-daily/
drwx------ 2 mastodon mastodon 4096 Dec 01 04:00 /var/tmp/mastodon-backup-monthly/
```

### systemdセキュリティ強化

#### サンドボックス設定の詳細

```ini
[Service]
# 権限昇格防止
NoNewPrivileges=true

# プライベート/tmp使用
PrivateTmp=true

# システムディレクトリ保護
ProtectSystem=strict     # /usr, /boot, /efi を読み取り専用に
ProtectHome=true         # /home, /root, /run/user を隠す

# 書き込み許可パス（必要最小限）
ReadWritePaths=/var/log/mastodon-backup /var/tmp/mastodon-backup-daily

# ネットワーク制限（オプション）
# PrivateNetwork=false   # B2アップロードのためネットワーク必要

# デバイスアクセス制限
PrivateDevices=true

# カーネル機能制限
CapabilityBoundingSet=~CAP_SYS_ADMIN
```

### ネットワークセキュリティ

#### PostgreSQL接続のTLS化

**推奨設定（postgresql.conf）:**
```conf
ssl = on
ssl_cert_file = '/path/to/server.crt'
ssl_key_file = '/path/to/server.key'
```

**クライアント側設定:**
```bash
# 環境変数
export PGSSLMODE=require  # または prefer, verify-ca, verify-full

# または接続文字列
pg_dump "host=localhost sslmode=require ..."
```

#### BackBlaze B2接続

- b2 CLIとrcloneは両方ともHTTPSを強制使用
- 追加設定は不要

### セキュリティチェックリスト

実装完了後、以下を確認してください：

- [ ] `/etc/mastodon/backup.env` のパーミッションが600
- [ ] 環境変数ファイルが `.gitignore` に追加されている
- [ ] B2 Application Keyが最小権限設定
- [ ] systemdサービスが適切なユーザーで実行
- [ ] systemdサンドボックス設定が有効
- [ ] ログディレクトリのパーミッションが適切
- [ ] 作業ディレクトリのパーミッションが700
- [ ] PostgreSQL接続でTLSが使用されている（推奨）
- [ ] バックアップファイルが暗号化されている（オプション）

## テスト計画

### 単体テスト

#### 共通ライブラリテスト

**lib/common.sh:**
```bash
#!/bin/bash
source src/mastodon/lib/common.sh

# ログ関数テスト
init_script
log_info "Info message test"
log_error "Error message test"
log_success "Success message test"

# コマンド存在確認テスト
check_command "ls" && echo "ls: OK"
check_command "nonexistent_command" || echo "nonexistent: NG (expected)"

# 環境変数検証テスト
export TEST_VAR1="value1"
validate_env "TEST_VAR1" "HOME" && echo "Env validation: OK"
validate_env "NONEXISTENT_VAR" || echo "Missing var detection: OK (expected)"

# ディレクトリ作成テスト
ensure_directory "/tmp/test-backup-dir" && echo "Directory creation: OK"
ls -ld /tmp/test-backup-dir
```

**lib/backup-core.sh:**
```bash
#!/bin/bash
source src/mastodon/lib/common.sh
source src/mastodon/lib/backup-core.sh

# ファイル名生成テスト
filename=$(generate_backup_filename "daily")
echo "Generated filename: $filename"
[[ "$filename" =~ ^daily_.*_.*_[0-9]{8}_[0-9]{6}\.sql$ ]] && echo "Filename format: OK"

# バックアップ実行テスト（テストDB必要）
# export DB_NAME=test_db
# export PG_USER=postgres
# export PG_PASSWORD=password
# backup_postgresql "daily" "/tmp/test-backup.sql"
```

### 統合テスト

#### エンドツーエンドテスト

**テストシナリオ1: 日次バックアップ全体フロー**

```bash
#!/bin/bash
# E2E test for daily backup

echo "=== E2E Test: Daily Backup ==="

# 1. 環境変数設定
export DB_NAME=mastodon_production
export PG_USER=mastodon
export PG_PASSWORD='test_password'
export B2_BUCKET_DAILY=mastodon-backup-daily-test
export B2_APPLICATION_KEY_ID='test_key_id'
export B2_APPLICATION_KEY='test_key'

# 2. バックアップ実行（ローカルのみ）
echo "Step 1: Running local backup..."
./src/mastodon/backup-db-daily.sh --no-upload

# 3. 結果確認
if [ -f /var/tmp/mastodon-backup-daily/*.sql.gz ]; then
    echo "✓ Backup file created"
else
    echo "✗ Backup file NOT found"
    exit 1
fi

# 4. ファイルサイズ確認
backup_file=$(ls -1 /var/tmp/mastodon-backup-daily/*.sql.gz | head -1)
file_size=$(stat -c%s "$backup_file")
if [ "$file_size" -gt 1024 ]; then
    echo "✓ Backup file size: $file_size bytes (OK)"
else
    echo "✗ Backup file too small: $file_size bytes"
    exit 1
fi

# 5. gzip形式確認
if file "$backup_file" | grep -q "gzip compressed"; then
    echo "✓ File format: gzip compressed (OK)"
else
    echo "✗ File format invalid"
    exit 1
fi

echo "=== E2E Test: PASSED ==="
```

**テストシナリオ2: systemdタイマーからの実行**

```bash
#!/bin/bash
# Test systemd integration

echo "=== Systemd Integration Test ==="

# 1. サービス実行
echo "Step 1: Starting systemd service..."
sudo systemctl start mastodon-backup-daily.service

# 2. 完了待機
sleep 5

# 3. ステータス確認
if systemctl is-active --quiet mastodon-backup-daily.service; then
    echo "✗ Service still running (should be oneshot)"
else
    echo "✓ Service completed"
fi

# 4. 終了コード確認
exit_code=$(systemctl show -p ExecMainStatus --value mastodon-backup-daily.service)
if [ "$exit_code" -eq 0 ]; then
    echo "✓ Service exit code: 0 (success)"
else
    echo "✗ Service exit code: $exit_code (failure)"
    exit 1
fi

# 5. ログ確認
echo "Step 2: Checking logs..."
log_output=$(sudo journalctl -u mastodon-backup-daily.service -n 20 --no-pager)
if echo "$log_output" | grep -q "backup completed successfully"; then
    echo "✓ Success message found in logs"
else
    echo "✗ Success message NOT found"
    echo "$log_output"
    exit 1
fi

echo "=== Systemd Integration Test: PASSED ==="
```

### パフォーマンステスト

#### バックアップ時間測定

```bash
#!/bin/bash
# Performance test

echo "=== Performance Test ==="

# データベースサイズ取得
db_size=$(PGPASSWORD='password' psql -h localhost -U mastodon -d mastodon_production -t -c "SELECT pg_size_pretty(pg_database_size('mastodon_production'));")
echo "Database size: $db_size"

# バックアップ時間測定
start_time=$(date +%s)
./src/mastodon/backup-db-daily.sh --no-upload
end_time=$(date +%s)

elapsed=$((end_time - start_time))
echo "Backup elapsed time: ${elapsed}s"

# 圧縮率計算
backup_file=$(ls -1 /var/tmp/mastodon-backup-daily/*.sql.gz | head -1)
compressed_size=$(stat -c%s "$backup_file")
echo "Compressed backup size: $(numfmt --to=iec-i --suffix=B $compressed_size)"
```

**期待値:**
- 小規模DB（< 1GB）: 1-2分
- 中規模DB（1-10GB）: 5-15分
- 大規模DB（> 10GB）: 15分以上

### 復元テスト

#### 復元手順の検証

```bash
#!/bin/bash
# Restore test

echo "=== Restore Test ==="

# 1. テストDB作成
echo "Step 1: Creating test database..."
sudo -u postgres psql -c "DROP DATABASE IF EXISTS mastodon_restore_test;"
sudo -u postgres psql -c "CREATE DATABASE mastodon_restore_test OWNER mastodon;"

# 2. バックアップファイル取得
backup_file=$(ls -1t /var/tmp/mastodon-backup-daily/*.sql.gz | head -1)
echo "Using backup: $backup_file"

# 3. 解凍
echo "Step 2: Decompressing backup..."
temp_sql="/tmp/restore-test.sql"
gunzip -c "$backup_file" > "$temp_sql"

# 4. 復元
echo "Step 3: Restoring to test database..."
PGPASSWORD='password' pg_restore \
    -h localhost \
    -U mastodon \
    -d mastodon_restore_test \
    -v \
    "$temp_sql" 2>&1 | tee /tmp/restore-log.txt

# 5. 復元確認
echo "Step 4: Verifying restore..."
table_count=$(PGPASSWORD='password' psql -h localhost -U mastodon -d mastodon_restore_test -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
echo "Restored tables: $table_count"

if [ "$table_count" -gt 0 ]; then
    echo "✓ Restore successful ($table_count tables)"
else
    echo "✗ Restore failed (no tables)"
    exit 1
fi

# 6. クリーンアップ
rm -f "$temp_sql"
sudo -u postgres psql -c "DROP DATABASE mastodon_restore_test;"

echo "=== Restore Test: PASSED ==="
```

## 運用手順

### 初回セットアップ

#### 1. 依存パッケージインストール

```bash
# PostgreSQL client tools
sudo apt update
sudo apt install -y postgresql-client gzip

# BackBlaze B2 CLI (推奨)
pip3 install b2

# または rclone (代替)
sudo apt install -y rclone
```

#### 2. BackBlaze B2設定

**バケット作成:**
1. BackBlaze管理画面にログイン: https://secure.backblaze.com/
2. "Buckets" → "Create a Bucket"
3. バケット名入力:
   - `mastodon-backup-daily`
   - `mastodon-backup-monthly`
4. ライフサイクル設定:
   - 日次: "Keep only the last 30 versions"
   - 月次: "Keep only the last 12 versions"

**Application Key作成:**
1. "App Keys" → "Add a New Application Key"
2. 設定:
   - Name: `mastodon-backup-key`
   - Permissions: `Read and Write`
   - Bucket: `mastodon-backup-daily` (後で月次用にも別Key作成)
3. Key IDとKeyをメモ（一度しか表示されない！）

#### 3. ディレクトリとファイル作成

```bash
# ランタイムディレクトリ
sudo mkdir -p /var/log/mastodon-backup
sudo mkdir -p /var/tmp/mastodon-backup-{daily,monthly}
sudo mkdir -p /etc/mastodon

# パーミッション設定
sudo chown -R mastodon:mastodon /var/log/mastodon-backup /var/tmp/mastodon-backup-*
sudo chmod 755 /var/log/mastodon-backup
sudo chmod 700 /var/tmp/mastodon-backup-*
```

#### 4. 環境変数設定

```bash
# テンプレートコピー
sudo cp src/mastodon/systemd/mastodon-backup.env.example /etc/mastodon/backup.env

# 実際の値を入力
sudo nano /etc/mastodon/backup.env

# パーミッション設定
sudo chmod 600 /etc/mastodon/backup.env
sudo chown mastodon:mastodon /etc/mastodon/backup.env
```

#### 5. 手動テスト

```bash
# ローカルバックアップテスト
cd /home/mimikun/ghq/github.com/mimikun/mimikun.sh
source /etc/mastodon/backup.env
sudo -u mastodon ./src/mastodon/backup-db-daily.sh --no-upload

# バックアップファイル確認
ls -lh /var/tmp/mastodon-backup-daily/

# B2アップロードテスト
sudo -u mastodon ./src/mastodon/backup-db-daily.sh

# B2バケット確認
b2 ls mastodon-backup-daily
```

#### 6. systemd設定

```bash
# systemdファイルコピー
sudo cp src/mastodon/systemd/*.service /etc/systemd/system/
sudo cp src/mastodon/systemd/*.timer /etc/systemd/system/

# デーモンリロード
sudo systemctl daemon-reload

# タイマー有効化
sudo systemctl enable mastodon-backup-daily.timer
sudo systemctl enable mastodon-backup-monthly.timer
sudo systemctl start mastodon-backup-daily.timer
sudo systemctl start mastodon-backup-monthly.timer

# 確認
sudo systemctl list-timers | grep mastodon
```

### 日常運用

#### バックアップステータス確認

```bash
# タイマー次回実行時刻確認
sudo systemctl list-timers | grep mastodon

# 最新バックアップログ確認
sudo journalctl -u mastodon-backup-daily.service -n 50
sudo journalctl -u mastodon-backup-monthly.service -n 50

# ローカルログ確認
tail -f /var/log/mastodon-backup/backup.log

# B2バケット確認
b2 ls mastodon-backup-daily
b2 ls mastodon-backup-monthly
```

#### 手動バックアップ実行

```bash
# 日次バックアップを手動実行
sudo systemctl start mastodon-backup-daily.service

# 月次バックアップを手動実行
sudo systemctl start mastodon-backup-monthly.service

# 実行状況確認
sudo systemctl status mastodon-backup-daily.service
```

#### バックアップファイルのダウンロード

```bash
# バケット内ファイル一覧
b2 ls --long mastodon-backup-daily

# 特定ファイルのダウンロード
b2 download-file-by-name mastodon-backup-daily \
  "daily_mastodon_production_hostname_20250129_030000.sql.gz" \
  ./backup-20250129.sql.gz

# 最新バックアップのダウンロード
latest_file=$(b2 ls mastodon-backup-daily | tail -1 | awk '{print $NF}')
b2 download-file-by-name mastodon-backup-daily "$latest_file" ./latest-backup.sql.gz
```

### データベース復元手順

#### 完全復元（日次バックアップから）

```bash
# 1. Mastodonサービス停止
sudo systemctl stop mastodon-web mastodon-sidekiq mastodon-streaming

# 2. バックアップダウンロード
b2 download-file-by-name mastodon-backup-daily \
  "daily_mastodon_production_hostname_20250129_030000.sql.gz" \
  ./restore.sql.gz

# 3. 解凍
gunzip restore.sql.gz

# 4. 既存データベース削除・再作成
sudo -u postgres psql <<EOF
DROP DATABASE mastodon_production;
CREATE DATABASE mastodon_production OWNER mastodon;
\q
EOF

# 5. 復元実行
PGPASSWORD='your_password' pg_restore \
    -h localhost \
    -U mastodon \
    -d mastodon_production \
    -v \
    restore.sql

# 6. サービス再起動
sudo systemctl start mastodon-web mastodon-sidekiq mastodon-streaming

# 7. 動作確認
sudo systemctl status mastodon-*
curl -I https://your-mastodon-instance.com/
```

#### 部分復元（特定テーブルのみ）

```bash
# 1. バックアップダウンロード・解凍
b2 download-file-by-name mastodon-backup-daily "backup.sql.gz" ./backup.sql.gz
gunzip backup.sql.gz

# 2. 特定テーブルのみ復元
PGPASSWORD='password' pg_restore \
    -h localhost \
    -U mastodon \
    -d mastodon_production \
    -t accounts \
    -t statuses \
    -v \
    backup.sql

# 注: -t オプションで復元するテーブルを指定
```

### トラブルシューティング

#### バックアップが実行されない

**症状チェック:**
```bash
# タイマーが有効か確認
sudo systemctl is-enabled mastodon-backup-daily.timer
sudo systemctl is-active mastodon-backup-daily.timer

# タイマースケジュール確認
sudo systemctl list-timers | grep mastodon

# サービスステータス確認
sudo systemctl status mastodon-backup-daily.service
```

**解決方法:**
```bash
# タイマー再起動
sudo systemctl restart mastodon-backup-daily.timer

# 手動実行でエラー確認
sudo systemctl start mastodon-backup-daily.service
sudo journalctl -u mastodon-backup-daily.service -n 100
```

#### PostgreSQL接続エラー

**症状:**
```
[ERROR] PostgreSQL backup failed with exit code: 1
pg_dump: error: connection to server at "localhost", port 5432 failed
```

**確認項目:**
```bash
# PostgreSQL稼働確認
sudo systemctl status postgresql

# 接続テスト
PGPASSWORD='password' psql -h localhost -U mastodon -d mastodon_production -c "SELECT 1;"

# 環境変数確認
sudo cat /etc/mastodon/backup.env
```

**解決方法:**
- PostgreSQLが起動しているか確認
- `/etc/mastodon/backup.env` の認証情報が正しいか確認
- `pg_hba.conf` でローカル接続が許可されているか確認

#### B2アップロードエラー

**症状:**
```
[ERROR] B2 upload failed: backup.sql.gz
Unauthorized
```

**確認項目:**
```bash
# b2 CLI認証テスト
b2 authorize-account "$B2_APPLICATION_KEY_ID" "$B2_APPLICATION_KEY"

# バケット存在確認
b2 list-buckets | grep mastodon-backup-daily
```

**解決方法:**
- B2 Application KeyとKey IDが正しいか確認
- Keyの有効期限が切れていないか確認
- バケット名が正しいか確認
- ネットワーク接続確認

#### ディスク容量不足

**症状:**
```
[ERROR] Failed to create backup: No space left on device
```

**確認:**
```bash
# ディスク使用量確認
df -h /var/tmp
df -h /var/log

# 古いバックアップファイル確認
ls -lh /var/tmp/mastodon-backup-*
```

**解決方法:**
```bash
# 古いローカルバックアップ削除
sudo rm -f /var/tmp/mastodon-backup-daily/*.sql.gz
sudo rm -f /var/tmp/mastodon-backup-monthly/*.sql.gz

# ログローテーション設定
sudo nano /etc/logrotate.d/mastodon-backup
```

**logrotate設定例:**
```
/var/log/mastodon-backup/*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 mastodon mastodon
}
```

### メンテナンス

#### B2バケットの手動クリーンアップ

```bash
# 30日以上前のファイルを手動削除
cutoff_date=$(date -d "30 days ago" +%Y%m%d)

b2 ls mastodon-backup-daily | while read -r line; do
    filename=$(echo "$line" | awk '{print $NF}')
    if [[ "$filename" =~ ([0-9]{8})_[0-9]{6} ]]; then
        file_date="${BASH_REMATCH[1]}"
        if [ "$file_date" -lt "$cutoff_date" ]; then
            echo "Deleting old backup: $filename"
            # b2 delete-file-version mastodon-backup-daily "$filename"
        fi
    fi
done
```

#### ログのアーカイブ

```bash
# 古いログを圧縮・アーカイブ
sudo gzip /var/log/mastodon-backup/backup.log.1
sudo mv /var/log/mastodon-backup/backup.log.1.gz /var/log/mastodon-backup/archive/
```

#### バックアップ整合性チェック

```bash
#!/bin/bash
# 週次で実行するバックアップ整合性チェック

echo "=== Backup Integrity Check ==="

# 1. 最新バックアップをダウンロード
latest=$(b2 ls mastodon-backup-daily | tail -1 | awk '{print $NF}')
b2 download-file-by-name mastodon-backup-daily "$latest" /tmp/check-backup.sql.gz

# 2. gzip整合性チェック
if gzip -t /tmp/check-backup.sql.gz; then
    echo "✓ Backup file integrity: OK"
else
    echo "✗ Backup file corrupted!"
    # アラート送信処理
fi

# 3. クリーンアップ
rm -f /tmp/check-backup.sql.gz
```

### モニタリングとアラート

#### systemdメール通知設定

```bash
# systemd-mail スクリプト作成
sudo nano /usr/local/bin/systemd-email

# 内容:
#!/bin/bash
/usr/bin/mail -s "systemd: $1 failed" admin@example.com <<EOF
Unit: $1
Result: $2
EOF

# 実行権限付与
sudo chmod +x /usr/local/bin/systemd-email
```

**サービスファイルに追加:**
```ini
[Service]
OnFailure=systemd-email@%n.service
```

#### Prometheus/Grafanaダッシュボード（上級）

**node_exporter設定例:**
```yaml
# バックアップ成功/失敗のメトリクス
- job_name: 'mastodon_backup'
  static_configs:
    - targets: ['localhost:9100']
  metric_relabel_configs:
    - source_labels: [__name__]
      regex: 'systemd_unit_state{name="mastodon-backup-daily.service"}'
      target_label: job
```

---

## 付録

### 参考リンク

- [Mastodon公式ドキュメント - Backup](https://docs.joinmastodon.org/admin/backups/)
- [PostgreSQL pg_dump Documentation](https://www.postgresql.org/docs/current/app-pgdump.html)
- [BackBlaze B2 CLI Documentation](https://www.backblaze.com/b2/docs/quick_command_line.html)
- [systemd.timer Manual](https://www.freedesktop.org/software/systemd/man/systemd.timer.html)

### 用語集

| 用語 | 説明 |
|------|------|
| pg_dump | PostgreSQL単一データベースバックアップツール |
| pg_dumpall | PostgreSQL全データベースバックアップツール |
| pg_restore | PostgreSQLバックアップ復元ツール |
| B2 | BackBlaze B2 Cloud Storage |
| systemd.timer | systemdのタイマーユニット（cronの代替） |
| oneshot | 一度だけ実行されるsystemdサービスタイプ |
| EnvironmentFile | systemdで環境変数を読み込むファイル |

### 変更履歴

| 日付 | バージョン | 変更内容 | 担当 |
|------|-----------|---------|------|
| 2025-12-29 | 1.0.0 | 初版作成 | Claude (AI Assistant) |

---

**このドキュメントに関する質問・フィードバックは、GitHubリポジトリのIssueで受け付けています。**
