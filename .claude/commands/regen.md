---
description: XcodeGen で project を再生成（新ファイル追加 or project.yml 変更後に必須）
---

# XcodeGen 再生成

新しい .swift ファイル追加 or `project.yml` 変更後に必須。
忘れると「cannot find type in scope」エラーで詰まる。

## やること

```bash
cd ~/project/Runvox && xcodegen generate 2>&1 | tail -3
```

出力に `Created project at .../Runvox.xcodeproj` があれば成功。

## いつ呼ぶか

- 新規 Swift ファイル追加直後
- `project.yml` 編集後
- ブランチ切替後にビルドが通らないとき（雑に試す）
- テスト実行で「cannot find type」が出るとき
