import FirebaseAuth
import FirebaseFirestore
import Foundation

/// Firebase Auth + Firestore による本番認証バックエンド
///
/// - 認証は Firebase Auth（メール / パスワード）
/// - プロフィール（nickname / role / rank / bio / isAnonymous）は
///   Firestore の `users/{uid}` ドキュメントに保持
/// - Apple Sign In は後続 PR（ASAuthorizationController + nonce が必要）
final class FirebaseAuthBackend: AuthBackend {
    private var auth: Auth { Auth.auth() }
    private var usersCollection: CollectionReference {
        Firestore.firestore().collection("users")
    }

    // MARK: - Restore

    func restoreSession() async -> User? {
        guard let firebaseUser = auth.currentUser else { return nil }
        return try? await fetchOrCreateUser(from: firebaseUser, fallbackNickname: nil)
    }

    // MARK: - Sign in

    func signInWithEmail(email: String, password: String) async throws -> User {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            return try await fetchOrCreateUser(from: result.user, fallbackNickname: nil)
        } catch {
            throw Self.mapError(error)
        }
    }

    // MARK: - Sign up

    func signUpWithEmail(email: String, password: String, nickname: String) async throws -> User {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let user = User(
                id: result.user.uid,
                email: email,
                nickname: nickname,
                role: .questioner,
                isAnonymous: false,
                createdAt: Date()
            )
            try await usersCollection.document(user.id).setData(Self.encode(user))

            // Firebase Auth の displayName にも反映（任意・失敗しても続行）
            let change = result.user.createProfileChangeRequest()
            change.displayName = nickname
            try? await change.commitChanges()

            return user
        } catch {
            throw Self.mapError(error)
        }
    }

    // MARK: - Apple (後続 PR)

    func signInWithApple() async throws -> User {
        throw AuthError.unknown("Apple サインインは Firebase 版では後続 PR で対応予定です")
    }

    // MARK: - Password reset

    func sendPasswordReset(email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch {
            throw Self.mapError(error)
        }
    }

    // MARK: - Update profile

    func updateProfile(_ user: User) async throws -> User {
        do {
            try await usersCollection
                .document(user.id)
                .setData(Self.encode(user), merge: true)
            return user
        } catch {
            throw Self.mapError(error)
        }
    }

    // MARK: - Sign out

    func signOut() async throws {
        try auth.signOut()
    }

    // MARK: - Firestore mapping

    private func fetchOrCreateUser(
        from firebaseUser: FirebaseAuth.User,
        fallbackNickname: String?
    ) async throws -> User {
        let doc = usersCollection.document(firebaseUser.uid)
        let snapshot = try await doc.getDocument()

        if snapshot.exists, let data = snapshot.data() {
            return Self.decode(data, uid: firebaseUser.uid, email: firebaseUser.email ?? "")
        }

        // ドキュメント未作成（Apple 初回など）→ 最小構成で作る
        let user = User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            nickname: fallbackNickname ?? firebaseUser.displayName ?? "ランナー",
            role: .questioner,
            isAnonymous: false,
            createdAt: Date()
        )
        try await doc.setData(Self.encode(user))
        return user
    }

    /// User → Firestore データ。nil は NSNull() で明示（merge 更新で確実にクリアできる）
    private static func encode(_ user: User) -> [String: Any] {
        [
            "email": user.email,
            "nickname": user.nickname,
            "realName": user.realName ?? NSNull(),
            "bio": user.bio ?? NSNull(),
            "avatarURL": user.avatarURL ?? NSNull(),
            "role": user.role.rawValue,
            "rank": user.rank?.rawValue ?? NSNull(),
            "isAnonymous": user.isAnonymous,
            "createdAt": Timestamp(date: user.createdAt),
        ]
    }

    private static func decode(_ data: [String: Any], uid: String, email: String) -> User {
        User(
            id: uid,
            email: data["email"] as? String ?? email,
            nickname: data["nickname"] as? String ?? "ランナー",
            realName: data["realName"] as? String,
            bio: data["bio"] as? String,
            avatarURL: data["avatarURL"] as? String,
            role: (data["role"] as? String).flatMap(UserRole.init(rawValue:)) ?? .questioner,
            rank: (data["rank"] as? String).flatMap(Rank.init(rawValue:)),
            isAnonymous: data["isAnonymous"] as? Bool ?? false,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    // MARK: - Error mapping

    private static func mapError(_ error: Error) -> AuthError {
        let nsError = error as NSError
        guard nsError.domain == AuthErrorDomain,
              let code = AuthErrorCode(rawValue: nsError.code) else {
            return .unknown(nsError.localizedDescription)
        }
        switch code {
        case .invalidEmail:
            return .invalidEmail
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .userNotFound:
            return .userNotFound
        case .wrongPassword, .invalidCredential:
            return .wrongPassword
        case .weakPassword:
            return .weakPassword("パスワードは 8 文字以上にしてください")
        case .networkError:
            return .networkError
        default:
            return .unknown(nsError.localizedDescription)
        }
    }
}
