# Runvox

[![CI](https://github.com/SoyaAsakura/Runvox/actions/workflows/ci.yml/badge.svg)](https://github.com/SoyaAsakura/Runvox/actions/workflows/ci.yml)

マラソン・ジョギング特化型 Q&A プラットフォーム

> 走る人の知恵が、走る人を強くする

## 📱 プロダクト概要

- **対象**: マラソン・ジョギング愛好家、ランナーコーチ
- **コア機能**: 質問投稿 / 回答 / 5段階★評価 / S/A/B ランク回答者制度 / ポイント獲得
- **プラットフォーム**: iOS 16+
- **配信**: App Store

## 🛠 技術スタック

| 層 | 技術 |
|---|---|
| UI | SwiftUI |
| 認証 | Firebase Auth (Email + Apple Sign In) |
| DB | Cloud Firestore |
| ストレージ | Firebase Storage |
| 通知 | Firebase Cloud Messaging (FCM) |
| サーバーロジック | Cloud Functions (TypeScript) |
| プロジェクト管理 | XcodeGen |

## 📂 プロジェクト構成

```
Runvox/
├── project.yml                  # XcodeGen プロジェクト定義
├── Runvox/                      # アプリ本体
│   ├── App/                     # @main エントリ + ContentView
│   ├── Features/                # 機能別画面
│   ├── Models/                  # Firestore モデル
│   ├── Services/                # Firebase ラッパー・業務ロジック
│   ├── DesignSystem/            # Colors / RankBadge / StarRating など
│   └── Resources/               # Assets.xcassets
└── RunvoxTests/                 # ユニットテスト
```

## 🚀 セットアップ

### 必要なもの

- macOS 14+
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)（`brew install xcodegen`）
- Apple Developer Program アカウント（リリース時）
- Firebase プロジェクト（オーナーから招待）

### 初回セットアップ

```bash
# 1. リポジトリをクローン
git clone <repository-url>
cd Runvox

# 2. Xcode プロジェクトを生成
xcodegen generate

# 3. Firebase 設定ファイルを配置（オーナーから受領）
#    Runvox/Resources/GoogleService-Info.plist を配置

# 4. Xcode で開く
open Runvox.xcodeproj
```

### project.yml を編集した場合

```bash
xcodegen generate
```

## 🎨 デザインシステム

| 用途 | 色 |
|---|---|
| Primary | `#00C2CC` (シアン) |
| Primary Dark (CTA) | `#009AA3` |
| Accent (Star / Success) | `#7ED957` (ライム) |
| Ink (Text) | `#0D1F22` |
| Page BG | `#F4FBFC` |

| ランク | グラデーション |
|---|---|
| S | Gold (`#D9A923` 系) |
| A | Silver (`#8E9CA8` 系) |
| B | Bronze (`#B57341` 系) |

## 💯 ポイント計算式

```
獲得ポイント = 評価ポイント × ランク歩率

評価ポイント: ★1=10 / ★2=50 / ★3=100 / ★4=150 / ★5=250
ランク歩率:   S=2.0  / A=1.5  / B=1.0
```

## 🧪 テスト

```bash
# Xcode から
Cmd + U

# CLI から
xcodebuild test \
  -project Runvox.xcodeproj \
  -scheme Runvox \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 📋 開発スケジュール (8 週間想定 / AI 活用ソロ開発)

| 週 | マイルストーン |
|---|---|
| W1 | 設計・Firebase セットアップ |
| W2 | デザインシステム + 認証 |
| W3 | ホーム + 質問投稿 |
| W4 | 質問詳細 + 回答投稿 |
| W5 | 評価 + ポイント計算 |
| W6 | プロフィール + マイページ |
| W7 | FCM プッシュ通知 + 通報 |
| W8 | テスト + App Store 申請 |

## 🔐 セキュリティ

- `GoogleService-Info.plist` は **git 管理外**（`.gitignore` 済み）
- Firestore セキュリティルールは別途 `firestore.rules` で管理
- 個人情報（身分証画像）は Firebase Storage + KMS で暗号化保存

## 🤖 自動コードレビュー

PR を作成すると Claude が自動でコードレビューを行います。
セットアップ手順: [.github/CLAUDE_REVIEW_SETUP.md](.github/CLAUDE_REVIEW_SETUP.md)

## 📝 ライセンス

Proprietary - 無断複製・再配布禁止
