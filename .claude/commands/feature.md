---
description: 新規 feature ブランチを安全に作成 (main 同期 + 切替)
argument-hint: <feature-name> (例: notification-list / search / firebase-auth)
---

# 新規ブランチ作成

Runvox の慣習に従って feature ブランチを切る。

## やること

1. **作業ツリーが綺麗か確認**
   - `git status` で uncommitted な変更を検知
   - 残ってる場合はユーザーに「stash / commit / discard どうしますか？」と確認

2. **main ブランチを最新化**
   ```bash
   cd ~/project/Runvox && git checkout main && git pull --ff-only
   ```

3. **新ブランチを作成**
   ```bash
   git checkout -b feature/$ARGUMENTS
   ```
   - $ARGUMENTS が未指定なら、何の機能か聞いて命名規約に沿わせる
   - prefix は機能なら `feature/`、修正なら `fix/`、設定なら `chore/`、ドキュメントなら `docs/`

4. **次のアクションを提案**
   - 画面追加なら → Features/<name>/View + ViewModel + Repository protocol が必要
   - データだけなら → Models/ + Services/<name>/ から
   - リファクタなら → 影響範囲を `Grep` で先に把握

## 出力

- 現在のブランチ
- 推奨される最初のファイル作成順
- 関連する CLAUDE.md のセクション (落とし穴・参考実装) があれば指摘
