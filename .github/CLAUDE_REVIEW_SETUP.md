# Claude Code Review セットアップ / 使い方

PR コメントで `@claude` をメンションすると、Claude が PR をレビューします。

## 仕組み

`.github/workflows/claude-code-review.yml` が PR コメントの `@claude` を検知して起動し、
[anthropics/claude-code-action](https://github.com/anthropics/claude-code-action) 経由で
Claude（Sonnet 4.5）にレビューを依頼 → 結果が PR コメントとして投稿されます。

## 使い方

PR に対してレビューが欲しいタイミングで、コメント欄にこう書いて投稿：

```
@claude レビューお願い
```

数分後（3〜5 分）に Claude のレビューコメントが付きます。

任意の追加指示も可能：

```
@claude セキュリティ観点重視でレビューして
```

```
@claude AuthService.swift だけ詳しく見て
```

```
@claude このパフォーマンスどう？
```

## 初回セットアップ（リポジトリオーナーが 1 回だけ）

### 1. Claude Code GitHub App をインストール

1. [github.com/apps/claude](https://github.com/apps/claude) にアクセス
2. 「Install」→ リポジトリを選択して許可

### 2. Anthropic API キー発行

1. [console.anthropic.com](https://console.anthropic.com) にログイン
2. 「API Keys」→「Create Key」
3. 発行されたキーをコピー（**1 回しか表示されない**）

### 3. GitHub にシークレット登録

```bash
gh secret set ANTHROPIC_API_KEY --repo <owner>/<repo>
# プロンプトで API キーをペースト
```

または Settings → Secrets and variables → Actions から手動で。

### 4. クレジット入金

[Billing ページ](https://console.anthropic.com/settings/billing) で $5 程度入金。

### 5. 動作確認

任意の PR で `@claude review` とコメントして、レビューが返ってくれば完了。

## 料金感（Sonnet 使用時）

| PR 規模 | 1 件あたり |
|---|---|
| 小（100〜300 行・1〜3 ファイル） | $0.03〜$0.06 |
| 中（300〜800 行） | $0.06〜$0.15 |
| 大（800〜2,000 行） | $0.15〜$0.40 |

→ **手動トリガー** なので呼んだ時しか課金されない。
→ 月 10 回呼んでも **$1〜$3** 程度。

## カスタマイズ

| 変えたい | 編集箇所 |
|---|---|
| モデルを Opus に戻す | `claude_args` を `--model claude-opus-4-1` に |
| トリガーワード変更 | `trigger_phrase` を `/review` などに |
| レビュー観点 | `prompt:` を編集 |
| 自動レビューに戻す | `on:` を `pull_request` 付きに戻す |

## 一時的に無効化

- ワークフロー全体: GitHub → Actions → Claude Code Review → Disable workflow
- 個別 PR で呼ばない: 単に `@claude` メンションをしない
