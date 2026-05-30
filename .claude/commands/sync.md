---
description: ローカル develop を origin と同期し、merged ブランチを整理
---

# develop 同期 + ブランチ掃除

別作業の後や、長期間放置したリポジトリを最新状態にする。

## やること

1. **現在の状態を保存** （uncommitted があれば確認）
   ```bash
   git status --short
   ```
   - 未コミットがあれば「stash する？」と確認。勝手に捨てない

2. **develop へ切替 + 最新化**
   ```bash
   cd ~/project/Runvox && git checkout develop && git pull --ff-only
   ```

3. **リモート消滅ブランチを ローカルから除去**
   ```bash
   git remote prune origin
   ```

4. **既にマージ済みのローカルブランチを表示** （削除候補）
   ```bash
   git branch --merged develop | grep -v "develop$" | grep -v "main$"
   ```
   - リストを表示
   - 「全部削除する？」とユーザーに確認してから実行
   - 確認なしでは削除しない

5. **状態レポート**
   - 現在のブランチ
   - develop の最新 3 commit
   - open PR が残ってれば数を表示
