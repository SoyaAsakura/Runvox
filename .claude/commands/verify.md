---
description: Runvox のローカル検証セット (xcodegen + SwiftLint + Test) を一気に実行
---

# Runvox ローカル検証

PR を出す前に必ず通すべき検証を一気に実行する。

## やること

以下の 3 ステップを順に実行：

1. **XcodeGen でプロジェクト再生成**
   ```bash
   cd ~/project/Runvox && xcodegen generate 2>&1 | tail -2
   ```

2. **SwiftLint**
   ```bash
   cd ~/project/Runvox && swiftlint lint 2>&1 | tail -5
   ```

3. **ビルド + テスト** （iPhone 17 Pro Simulator）
   ```bash
   cd ~/project/Runvox && xcodebuild test \
     -project Runvox.xcodeproj \
     -scheme Runvox \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 \
     | grep -E "(error:|Executed.*test|TEST SUC|TEST FAIL)" | tail -10
   ```

## 結果サマリ

以下の形式で報告：

```
✅/❌ XcodeGen     : success / error message
✅/❌ SwiftLint    : 0 violations / N violations (1 行ごとに行番号付き)
✅/❌ Build & Test : N/N PASS / 失敗ファイル + 行
```

## 失敗時

- エラー行を最大 5 件表示
- 想定される修正方法を 1〜2 文で提案
- 修正は **行わない**（ユーザーが判断する）
