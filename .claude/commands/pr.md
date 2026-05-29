---
description: コミット + push + PR 作成を Runvox 標準フォーマットで一気にやる
argument-hint: <PR タイトル> (省略可。staged 内容から推測)
---

# PR 作成

ローカル検証済みの変更を PR にする。

## 事前チェック（必須）

1. **ローカル検証が緑か** 確認
   - 直前で `/verify` を通してれば OK
   - 通してない場合は **先に `/verify` を実行** （勝手に進めない）

2. **`git status` と `git diff --cached --stat`** を見る
   - 何を変えたか把握
   - 不要なファイルが入ってないか（.DS_Store / xcuserdata 等）

3. **シークレットスキャン**（簡易）
   - `GoogleService-Info.plist` / `.env` / `sk-...` / `AIza...` が混入してないか grep

## やること

### Step 1: コミット

タイトル（$ARGUMENTS）が指定されてればそれを使う。
未指定なら、変更内容から Conventional Commits 形式で生成：

```
feat(<scope>): <概要>
fix(<scope>): <概要>
chore(<scope>): <概要>
docs(<scope>): <概要>
ci(<scope>): <概要>
refactor(<scope>): <概要>
```

本文には以下を含める：
- 何を変えたか（箇条書き 3〜10 行）
- なぜ変えたか（必要なら）
- 注意点（あれば）
- 末尾に `🤖 Generated with [Claude Code](https://claude.com/claude-code)`

### Step 2: push

```bash
git push -u origin <現在のブランチ>
```

### Step 3: PR 作成

```bash
gh pr create --base main --head <現在のブランチ> \
  --title "<タイトル>" \
  --body "<本文>"
```

PR 本文の構成（**必ずこの順**）：

```markdown
## 概要

(1〜3 文で何を達成したか)

## スクリーン構成 (UI 変更がある場合のみ)

ASCII で。なければ省略。

## 変更内容

### ドメイン / データ層 / UI / ナビゲーション / 他
- 箇条書き

## 動作確認

- [x] iOS 17 Pro シミュレータで build SUCCEEDED
- [x] SwiftLint 0 violations
- [x] テスト N/N PASS

## 含まれないもの（後続 PR）

- 後回しにした項目を明示

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

### Step 4: 報告

- PR URL を表示
- 次は `/merge` で取り込む or CI 待ちを案内
