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

    /// 評価リポジトリ
    static func makeRatingRepository() -> RatingRepository {
        if FirebaseBootstrap.isAvailable {
            return FirestoreRatingRepository()
        }
        return MockRatingRepository()
    }

    /// ポイントリポジトリ
    static func makePointRepository() -> PointRepository {
        if FirebaseBootstrap.isAvailable {
            return FirestorePointRepository()
        }
        return MockPointRepository()
    }

    /// 通知リポジトリ
    ///
    /// Mock はホームのバッジと一覧で既読状態を共有するため `.shared` を返す。
    static func makeNotificationRepository() -> NotificationRepository {
        if FirebaseBootstrap.isAvailable {
            return FirestoreNotificationRepository()
        }
        return MockNotificationRepository.shared
    }

    /// 通報リポジトリ
    static func makeReportRepository() -> ReportRepository {
        if FirebaseBootstrap.isAvailable {
            return FirestoreReportRepository()
        }
        return MockReportRepository()
    }

    /// 回答者審査申請リポジトリ
    static func makeReviewerApplicationRepository() -> ReviewerApplicationRepository {
        if FirebaseBootstrap.isAvailable {
            return FirestoreReviewerApplicationRepository()
        }
        return MockReviewerApplicationRepository()
    }
}
