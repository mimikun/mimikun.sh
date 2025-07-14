# documents for mimikun.sh

## 開発/実装用ドキュメント作成フロー

**例**: `awesome_feat_1` というアイデアがあるとき

1. 最初に `docs/idea/awesome_feat_1_draft.md` にアイデアを書く
2. 次に `claude` を起動
    - ここ以降はほぼ起動させっぱなしになる
3. `Read @docs/idea/awesome_feat_1_draft.md. これについて話をしたい. アイデアをブラッシュアップする.` と入れる
    - アイデアが固まったら `OK, では固めたアイデアを @docs/idea/awesome_feat_1.md に保存して.` と入れる
3. 次に `@docs/idea/awesome_feat_1.md を元に設計書を作成したい.` と入れる
    - 設計書が固まるまで対話する
4. 設計書が固まったら `OK, では固めた設計書を @docs/design/awesome_feat_1.md に保存して.` と入れる
5. 次に `@docs/design/awesome_feat_1.md を元に実装計画書を作成して` と入れる
    - 実装計画書が固まるまで対話する
    - TODOリスト式でチェックリストもつけてもらう
6. 実装計画書が固まったら `OK, では固めた実装計画書を @docs/plan/awesome_feat_1.md に保存して.` と入れる
7. 最後に `claude` を終了

適宜, `think`, `megathink`, `ultrathink` を挟むこと

## 開発/実装フロー

1. 必要に応じて
    - `container-use` などサンドボックス環境を使えるようになるMCPをインストール
    - 上記の使用を命じる指示を `CLAUDE.md` に追記
2. `claude --dangerously-skip-permissions` を実行
3. `実装計画書が @docs/plan/awesome_feat_1.md にあるから, それを確認しつつ, @docs/design/awesome_feat_1.md を見て実装して.` と入力
4. 実装終わるまで放置

適宜, `think`, `megathink`, `ultrathink` を挟むこと

## 各ディレクトリの説明

### idea

アイデアに関する文書, 下書き段階のものも含まれる

### design

設計書に関する文書

### plan

実装計画に関する文書

### other

他の文書

**MUST**: Ignore this directory

### README.md

This document

