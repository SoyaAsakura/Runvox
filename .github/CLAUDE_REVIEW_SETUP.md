# Claude Code Review セットアップ手順

PR 作成時に Claude が自動でコードレビューを行います。

## 仕組み

`.github/workflows/claude-code-review.yml` が PR の `opened` / `synchronize` で起動し、
[anthropics/claude-code-action](https://github.com/anthropics/claude-code-action) を経由して
Claude API にレビューを依頼 → 結果が PR コメントとして投稿されます。

## 初回セットアップ（リポジトリオーナーが 1 回だけ）

### ステップ 1: Anthropic API キーを取得

1. [console.anthropic.com](https://console.anthropic.com) にログイン
2. 「API Keys」→ 「Create Key」
3. キー名: `runvox-github-actions` 推奨
4. 発行されたキーをコピー（**1 回しか表示されないので注意**）

### ステップ 2: GitHub にシークレットを登録

1. GitHub リポジトリ → Settings → Secrets and variables → Actions
2. 「New repository secret」
3. Name: `ANTHROPIC_API_KEY`
4. Value: ステップ 1 でコピーしたキー
5. 「Add secret」

### ステップ 3: 動作確認

任意の PR を作成、または既存 PR で「Re-run workflow」を実行。
数分後に Claude のレビューコメントが付けば成功。

## 代替: 公式 Claude GitHub App を使う

ワークフローを使わず、Anthropic 公式の GitHub App をインストールする方法もあります：

1. [github.com/apps/claude](https://github.com/apps/claude) にアクセス
2. 「Install」→ Runvox リポジトリを選択
3. App 側で OAuth または API キーを設定
4. PR コメントで `@claude review` と書くと手動レビュー実行

→ **このリポジトリではワークフロー方式を採用**（自動レビュー + 設定の透明性）。

## 料金

| 項目 | 目安 |
|---|---|
| PR 1 件のレビュー（小〜中規模） | $0.05 〜 $0.30 |
| PR 1 件のレビュー（大規模・複数ファイル） | $0.50 〜 $2.00 |
| 月 20 PR × 中規模想定 | $1 〜 $6 |

→ 個人プロジェクトなら **月 $5 以内** に収まる想定。
不安なら [Anthropic Console](https://console.anthropic.com) で使用量上限（月額）を設定可能。

## カスタマイズ

レビュー観点を変えたい場合は `.github/workflows/claude-code-review.yml` の `prompt:` を編集。
特定ファイルを除外したい場合は `if:` 条件や `paths-ignore` を活用。

## 一時的に無効化

- ワークフロー全体: GitHub → Actions → 該当ワークフロー → Disable workflow
- 特定 PR のみ: PR タイトルに `[skip claude]` を含めて、ワークフローの `if:` 条件で除外
