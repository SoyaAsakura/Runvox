import Foundation

/// データアクセス層のファクトリ。
///
/// `FirebaseBootstrap.isAvailable`（= GoogleService-Info.plist の有無）で
/// Firestore 実装と Mock 実装を切り替える。
/// - 実機 / シミュレータ（plist あり）→ Firestore 実装
/// - CI / Preview / ユニットテスト（plist なし）→ Mock 実装
///
/// 各リポジトリを Firestore 化するたびにここへ `make...Repository()` を追加していく。
enum RepositoryFactory {
    /// 質問リポジトリ
    static func makeQuestionRepository() -> QuestionRepository {
        if FirebaseBootstrap.isAvailable {
            return FirestoreQuestionRepository()
        }
        return MockQuestionRepository()
    }

    /// 回答リポジトリ
    static func makeAnswerRepository() -> AnswerRepository {
        if FirebaseBootstrap.isAvailable {
            return FirestoreAnswerRepository()
        }
        return MockAnswerRepository()
    }
}
