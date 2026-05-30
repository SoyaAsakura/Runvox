# Runvox — プロジェクト固有の Claude Code 指示書

このファイルは Claude Code が Runvox プロジェクトで作業する際の
**プロジェクト固有のコンテキスト** を提供します。

ユーザー全体の規約は `~/.claude/CLAUDE.md` を参照。ここでは
**Runvox 固有のアーキテクチャ・規約・落とし穴** だけを記述します。

---

## 🎯 プロジェクト概要

| 項目 | 内容 |
|---|---|
| 名称 | Runvox |
| 概要 | マラソン・ジョギング特化型 Q&A プラットフォーム |
| プラットフォーム | iOS 16+（Phase 1 は iOS のみ） |
| 状態 | MVP 開発中。Mock 駆動 → Firebase 統合予定 |
| Repo | https://github.com/SoyaAsakura/Runvox（Public） |
| 開発体制 | ソロ + Claude Code |

---

## ⚡ クイックリファレンス（一番よく使う）

### 🎯 スラッシュコマンド（`.claude/commands/`）

| Command | 用途 |
|---|---|
| `/verify` | xcodegen + SwiftLint + Test を一気実行 |
| `/regen` | XcodeGen 再生成だけ（新ファイル追加後に必須） |
| `/feature <name>` | main 同期 → 新ブランチ作成 |
| `/pr [タイトル]` | commit + push + PR 作成 |
| `/merge [PR番号]` | CI 確認 → squash マージ → クリーンアップ |
| `/sync` | main 同期 + merged ブランチ整理 |
| `/ship [タイトル]` | verify → pr → CI 待ち → merge までフルコース |

→ 詳細は `.claude/commands/<name>.md` を参照。

### 🔓 権限 allowlist（`.claude/settings.json`）

xcodegen / swiftlint / xcodebuild / git / gh の安全なコマンドは
**確認ダイアログなしで実行可能**に設定済み。

破壊的操作（`git push --force` / `rm -rf` / `git reset --hard` /
`gh repo delete`）は **deny で明示ブロック**。

→ ファイルは `.claude/settings.json`。コマンドを追加したくなったら
`allow` 配列に `Bash(コマンド:*)` 形式で追記。

### 🪝 Hooks（`.claude/hooks/`）

| Hook | トリガー | 動作 |
|---|---|---|
| `swiftlint-on-edit.sh` | `.swift` を Edit/Write/MultiEdit した後 | そのファイルだけ SwiftLint。違反があれば警告を返す（自動修正なし） |

- PostToolUse フックとして `settings.json` に登録済み
- swiftlint 未インストール環境では静かにスキップ（exit 0）
- **注意**: `settings.json` を編集したセッションでは即反映されない。
  `/hooks` メニューを一度開く or 再起動で有効化（新セッションは自動で有効）

### プロジェクト再生成（必須・新ファイル追加時は毎回）
```bash
cd ~/project/Runvox && xcodegen generate
```

### ビルド + テスト
```bash
cd ~/project/Runvox && \
  xcodebuild test -project Runvox.xcodeproj -scheme Runvox \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 \
  | grep -E "(error:|Executed|TEST SUC|TEST FAIL)" | tail -10
```

### Lint
```bash
cd ~/project/Runvox && swiftlint lint 2>&1 | tail -3
```

### 検証ワンセット（Lint → Build → Test）
PR を出す前に **必ずローカルで通す**：
```bash
cd ~/project/Runvox && \
  xcodegen generate && \
  swiftlint lint && \
  xcodebuild test -project Runvox.xcodeproj -scheme Runvox \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

---

## 🏗 アーキテクチャ

### レイヤ構成
```
Features/<feature>/
   ├─ <Feature>View.swift          ← SwiftUI View
   ├─ <Feature>ViewModel.swift     ← @MainActor ObservableObject
   └─ <Component>.swift            ← Feature 内部のサブ View

Services/<feature>/
   ├─ <Feature>Repository.swift           ← protocol（Sendable）
   ├─ Mock<Feature>Repository.swift       ← 開発用モック
   └─ Firestore<Feature>Repository.swift  ← 本番（未実装）

Models/
   └─ ドメインモデル（純粋 Swift・@MainActor 不要）

DesignSystem/
   └─ Color / Typography / 再利用可能なコンポーネント
```

### Repository パターン（必須）
**外部データに触れるすべての機能**は以下の 3 点セットで作る：

1. **Protocol** （`<X>Repository: Sendable`）
2. **Mock 実装** （`Mock<X>Repository`、サンプルデータ + 遅延シミュレーション）
3. **ViewModel** が protocol を依存注入で受け取る

```swift
@MainActor
final class FooViewModel: ObservableObject {
    private let repository: FooRepository
    init(repository: FooRepository = MockFooRepository()) {
        self.repository = repository
    }
}
```

→ これにより：
- テストで Mock を差し替え可能
- Firebase 統合時は `FirestoreFooRepository` を作って差し替えるだけ
- UI 層は無変更で本番化できる

### 既存の Repository 一覧

| Protocol | 用途 | Mock 場所 |
|---|---|---|
| `AuthBackend` | 認証（メール/Apple） | `MockAuthBackend` |
| `QuestionRepository` | 質問 CRUD | `MockQuestionRepository` |
| `AnswerRepository` | 回答取得・投稿 | `MockAnswerRepository` |
| `RatingRepository` | ★評価送信 | `MockRatingRepository` |
| `PointRepository` | ポイント残高・履歴 | `MockPointRepository` |
| `UserRepository` | 回答者プロフィール | `MockUserRepository` |
| `ReviewerApplicationRepository` | 審査申請 | `MockReviewerApplicationRepository` |

新しい Repository を追加するときも **同じパターン** を踏襲すること。

---

## 🎨 デザインシステム

### カラートークン（**RunvoxColors を使う、生 Color 禁止**）
```swift
RunvoxColors.primary       // #00C2CC (シアン)
RunvoxColors.primaryDark   // #009AA3 (CTA / WCAG AA 確保)
RunvoxColors.accentLime    // #7ED957 (★・成功)
RunvoxColors.ink           // #0D1F22 (text)
RunvoxColors.subtext       // #6B8A8E (二次 text)
RunvoxColors.border        // #D8ECEE
RunvoxColors.bgPage        // #F4FBFC
RunvoxColors.bgTint        // #E0F9FA
RunvoxColors.success       // #00B85C
RunvoxColors.danger        // #E63946
```

### 再利用可能コンポーネント
| Component | 用途 |
|---|---|
| `RankBadge(rank:size:)` | S/A/B ランクバッジ |
| `StarRating(rating:size:)` | ★評価**表示** |
| `StarPicker(rating:)` | ★評価**入力**（インタラクティブ）|
| `Avatar(initial:size:rank:)` | 円形アバター |
| `CategoryChip(label:style:)` | カテゴリタグ |
| `StatusPill(status:)` | 質問ステータス（待ち/済/ラリー）|
| `SectionHeader(title:count:systemIcon:)` | セクション見出し |
| `SettingsRow(icon:title:...)` | 設定行 |
| `SettingsGroup("...") { ... }` | 設定セクション |
| `RunvoxTextField(title:placeholder:text:)` | フォーム入力 |
| `RunvoxPrimaryButtonStyle()` | プライマリ CTA ボタン |
| `RunvoxOutlineDarkButtonStyle()` | ダーク背景の outline |
| `RunvoxOutlineLightButtonStyle()` | ライト背景の outline |
| `ApplicationStepper(status:)` | 4 ステップ進捗バー |
| `FlowLayout { ... }` | 折り返し配置 |

→ **新しいコンポーネントを作る前に、まず既存に該当があるか必ず確認**。

### ポイント計算式（仕様）
```
獲得pt = 評価ポイント × ランク歩率
評価ポイント: ★1=10 / ★2=50 / ★3=100 / ★4=150 / ★5=250
ランク歩率:   S=2.0  / A=1.5  / B=1.0
```
→ 必ず `PointCalculator.calculate(stars:rank:)` を使用。直接計算しない。

---

## 📐 コード規約

### Swift 全般
- 不変性優先（`let` をデフォルト、`var` は本当に必要なときだけ）
- イミュータブル更新は `with(rating:)` 形式の helper を使う
- 200〜400 行 / ファイル目安、最大 800 行
- `@MainActor` は ViewModel と AuthService に付与済み
- `Sendable` は Repository protocol に付与

### SwiftUI
- **iOS 16+ 互換性必須**
  - `@Previewable` ❌（iOS 17+）→ 別 struct でラップして Preview
  - `Text(...).foregroundStyle()` の `+` 連結 ❌（iOS 17+）→ `foregroundColor()` を使う
  - `@Observable` macro ❌（iOS 17+）→ `ObservableObject` を使う
  - `navigationDestination(item:)` ❌（iOS 17+）→ `(for:)` + NavigationLink(value:) パターン
- **タップ系の落とし穴**
  - カードコンポーネントに内側 Button を入れない（NavigationLink の tap を奪う）
  - `.contentShape(Rectangle())` で全面タップ可能に
- **Default 引数で @MainActor 隔離違反**
  - `init(viewModel: ViewModel = ViewModel())` だと non-isolated context で @MainActor 違反
  - `@StateObject private var vm = ViewModel()` の property initializer 形式を使う

### ファイル組織
- `Features/<feature>/` … 機能ごとに 1 フォルダ
- `Models/` … 純粋 Swift モデル（依存なし）
- `Services/<feature>/` … Repository とその実装
- `DesignSystem/` … 再利用可能 UI
- `App/` … `@main` と `ContentView` だけ

### XcodeGen
- 新規ファイルを追加したら **必ず `xcodegen generate`**
- `project.yml` を編集したら **必ず `xcodegen generate`**
- `.xcodeproj` を直接編集しない（再生成で消える）

---

## 🔄 PR ワークフロー

### ブランチ命名
```
feature/<name>     新機能
fix/<name>         バグ修正
chore/<name>       タスク（設定変更など）
docs/<name>        ドキュメント
ci/<name>          CI 変更
refactor/<name>    リファクタ
```

### コミットメッセージ（Conventional Commits）
```
feat(<scope>): <概要>     新機能
fix(<scope>): <概要>      バグ修正
chore(<scope>): <概要>    タスク
docs(<scope>): <概要>     ドキュメント
ci(<scope>): <概要>       CI 変更
refactor(<scope>): <概要> リファクタ

(<scope> は機能名・ファイル名カテゴリ)

詳細を本文に箇条書きで:
- 何を変えたか
- なぜ変えたか
- 注意点

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

### PR 作成
- **常にローカルで Lint + テスト緑にしてから push**
- PR 本文に **動作確認手順** を必ず書く
- **含まれないもの** を明示（スコープ外を分かりやすく）
- 関連 mockup あれば ASCII 図で

### マージ
- `--squash --delete-branch` で履歴を整理（このプロジェクトの慣習）
- マージ後はローカル `main` を pull + 不要ブランチを削除

### CI（GitHub Actions）
- `Build & Test`（macOS 17 Pro Simulator）+ `SwiftLint` が走る
- main への push と PR で発火
- Public リポジトリなので macOS 分は無制限
- 5 秒で失敗する場合は GitHub 側のランナー/支払い問題（コードではない）

### Claude Code Review（手動トリガー）
- PR コメントで `@claude レビューお願い` と書くと起動
- モデル: Sonnet 4.5（コスト最適化済み）
- 1 件あたり $0.03〜$0.40 程度

---

## 🧪 テスト

### 方針
- **ViewModel と純粋ロジックは必ずテストを書く**
- 80% 以上のカバレッジ目標
- View 自体の snapshot テストはまだ無し（必要になったら追加）

### 命名規約
```swift
func test_<対象>_<条件>_<期待結果>() async {
    // arrange
    // act
    // assert
}
```

### deterministic なテスト
- `@MainActor` 必須
- Mock の遅延は `simulatedLatency: .milliseconds(0)` で消す
- `AuthService` などは `autoRestore: false` で init 時の副作用を抑制
- 並列実行で flake する設計を作らない

### 既存テストカウント
現状 **122 件全 PASS**。新機能追加時は最低でも ViewModel のテストを追加する。

---

## ⚠️ 既知の落とし穴（過去にハマった）

| 罠 | 回避方法 |
|---|---|
| 静的 let プロパティ初期化での `Self.foo()` 参照 | `ClassName.foo()` と明示 |
| Card 内に Button + 外側 NavigationLink で tap 効かない | Card から内側 Button を外す |
| `@Previewable` で iOS 17+ 必須エラー | 別 PreviewHost struct でラップ |
| `Text.foregroundStyle()` 連結で iOS 17+ 必須エラー | `foregroundColor()` を使う |
| `XCTUnwrap(await ...)` で async autoclosure エラー | `let x = await ...; XCTUnwrap(x)` |
| 並列テスト実行で `AuthServiceTests` が flake | `autoRestore: false` で deterministic に |
| init の default パラメータで `@MainActor` 違反 | `@StateObject` のプロパティ初期化を使う |
| User が Hashable じゃないので AnswererProfile が Hashable できない | navigation には `<X>Route` struct を別途用意 |
| Stacked PR のスカッシュマージで履歴ズレ | 各 PR を `rebase origin/main` で再構築 |
| 親ブランチ削除で PR が自動 close | 削除前に `gh pr edit <n> --base main` |
| SwiftLint `large_tuple` (3 要素以上) | `private struct` で名前付き |
| SwiftLint `type_body_length` | View 大きい場合は `// swiftlint:disable type_body_length` を spot で |

---

## 🔥 Firebase 統合方針

### ✅ 完了

1. SPM で Firebase SDK 追加済み（`FirebaseAuth` / `FirebaseFirestore`、SDK 11.x）
2. `GoogleService-Info.plist` は `Runvox/Resources/` に配置（**.gitignore 済み・絶対にコミットしない**。PUBLIC リポジトリ）
3. `FirebaseBootstrap.configureIfAvailable()` で plist がある時だけ `FirebaseApp.configure()`
4. **ファクトリで Mock ↔ Firestore を自動切替**（plist の有無で判定）
   - `BackendFactory.makeAuthBackend()`：`FirebaseAuthBackend` ↔ `MockAuthBackend`
   - `RepositoryFactory.makeQuestionRepository()`：`FirestoreQuestionRepository` ↔ `MockQuestionRepository`
   - → CI / Preview / ユニットテストは plist なしで Mock 動作、実機/シミュレータは plist ありで Firebase 動作
   - ⚠️ テストは必ず明示的に Mock を注入すること（ローカルでは plist が同梱されファクトリが Firestore を返すため）
5. `FirebaseAuthBackend`：Auth（メール/パスワード）+ Firestore `users/{uid}` でプロフィール管理
6. `FirestoreQuestionRepository`：`questions` コレクション（fetch/create/search）。`QuestionStatus` は
   `status` 文字列 + `rallyUsed`/`rallyMax` にフラット化して保存。search は直近 200 件のクライアント側フィルタ（MVP）
7. `firestore.rules`：`users` / `questions` のルール記述済み
8. `firestore.indexes.json`：`questions` の `category`(ASC)+`createdAt`(DESC) 複合インデックス

### ⬜ 残タスク

- 残 Repository を順次 Firestore 実装に差し替え（answers / ratings / points / reports / notifications / reviewerApplications）
- 各コレクションの `firestore.rules` 追記
- Apple Sign In（ASAuthorizationController + nonce）— 現状 `FirebaseAuthBackend.signInWithApple()` は未対応エラー
- FirebaseStorage（画像添付）/ FirebaseMessaging（FCM）/ Cloud Functions（ポイント計算・通知送信）

### 🔧 友達側（Firebase コンソール）でやること

- Email/Password 認証を有効化
- Firestore Database を作成
- `firebase deploy --only firestore:rules,firestore:indexes` でルールとインデックスをデプロイ

---

## 📊 完成度の把握

実装済み画面：
- ✅ 登録/ログイン / Welcome
- ✅ ホーム（質問一覧）
- ✅ 質問詳細
- ✅ 質問投稿
- ✅ ★評価モーダル
- ✅ 回答投稿
- ✅ 回答者プロフィール
- ✅ マイページ / Settings
- ✅ ポイントダッシュボード
- ✅ 回答者審査申請

未実装画面：
- ⬜ 通知一覧
- ⬜ 検索画面
- ⬜ プロフィール編集
- ⬜ 通知設定（OS 連携）

未着手領域：
- 🔄 Firebase 統合（Auth + users Firestore は完了 / 他 Repository は Mock のまま）
- ⬜ FCM プッシュ通知
- ⬜ 通報モーダル
- ⬜ ラリー機能（追加質問）
- ⬜ 質問画像添付
- ⬜ App Store 申請素材

---

## 🛠 デバッグ便利コマンド

```bash
# CI ステータスをサクッと確認
gh pr view <n> --json statusCheckRollup -q '[.statusCheckRollup[] | {name, conclusion}]'

# CI 失敗ログを見る
gh run view <run-id> --log-failed

# Mock の動作確認用メールアドレス
#  - taken@example.com    → emailAlreadyInUse
#  - notfound@example.com → userNotFound
#  - wrong@example.com    → wrongPassword
#  - network@example.com  → networkError
```

---

## 🎯 Claude Code への期待動作

このプロジェクトで作業するときは：

1. **新機能着手時**
   - まず branch を切る（feature/xxx）
   - Repository pattern を踏襲
   - ViewModel テストを書く
   - ローカルで Lint + Test 緑を確認してから push
   - 適切な PR 本文（動作確認手順 + 含まないもの）を書く

2. **モデル変更時**
   - 既存テストが落ちないか確認
   - 必要なら `with(...)` 形式の helper を追加

3. **新しい依存・SDK 追加時**
   - 必ず承認を取る（XcodeGen の `dependencies` に追加）

4. **「やらないこと」を明確に**
   - スコープを超えて作業しない
   - 「ついでに」リファクタしない（別 PR にする）
   - .xcodeproj を直接いじらない

5. **困ったら**
   - この CLAUDE.md の「既知の落とし穴」セクションをまず見る
