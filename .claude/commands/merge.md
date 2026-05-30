---
description: 現在の PR を squash マージ + ローカル/リモートのブランチをクリーンアップ
argument-hint: [PR 番号] (省略時は現在のブランチに紐づく PR)
---

# PR マージ + クリーンアップ

CI 緑を確認してから squash マージし、ローカル/リモートを片付ける。

## やること

### Step 1: PR 番号の特定

- $ARGUMENTS で指定されてればそれを使う
- 未指定なら：
  ```bash
  gh pr view --json number,headRefName -q '{n: .number, branch: .headRefName}'
  ```
  で現在のブランチに紐づく PR 番号を取得

### Step 2: CI ステータス確認

```bash
gh pr view <n> --json statusCheckRollup -q '[.statusCheckRollup[] | {name, conclusion, status}]'
```

判定：
- **全 SUCCESS** → Step 3 へ
- **進行中（IN_PROGRESS / QUEUED）** → 最大 10 分まで待つ。`sleep 30` で polling
- **FAILURE** → **中止**。原因表示して報告

### Step 3: マージ

```bash
gh pr merge <n> --squash --delete-branch
```

`--delete-branch` でリモートブランチも自動削除される。

### Step 4: ローカル同期

```bash
cd ~/project/Runvox
git checkout develop
git pull --ff-only
```

### Step 5: ローカルブランチ削除

```bash
# マージ済みブランチを検出
git branch --merged develop | grep -v "develop$" | grep -v "main$" | xargs -r git branch -d
```

または明示的に：
```bash
git branch -D <feature/branch-name>
```

### Step 6: remote prune

```bash
git remote prune origin
```

### Step 7: 報告

- マージしたコミット SHA
- 最新 develop の git log --oneline (最新 3 件)
- 残ってる open PR があれば一覧表示

## 失敗時の対応

| 状況 | 対応 |
|---|---|
| CI 進行中 | sleep 30 で待つ。10 分超えたら一度報告 |
| CI 失敗 | エラーログを `gh run view --log-failed` で取得して原因表示 |
| マージコンフリクト | rebase が必要。ユーザーに判断委ねる |
| 親ブランチ削除済み | PR が closed になってる可能性。新規 PR 作り直し |
