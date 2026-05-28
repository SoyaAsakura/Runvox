import Foundation

/// ユーザー情報
struct User: Identifiable, Codable, Equatable {
    let id: String
    var email: String
    var nickname: String
    var realName: String?
    var bio: String?
    var avatarURL: String?
    var role: UserRole
    var rank: Rank?
    var isAnonymous: Bool
    var createdAt: Date

    init(
        id: String,
        email: String,
        nickname: String,
        realName: String? = nil,
        bio: String? = nil,
        avatarURL: String? = nil,
        role: UserRole = .questioner,
        rank: Rank? = nil,
        isAnonymous: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.nickname = nickname
        self.realName = realName
        self.bio = bio
        self.avatarURL = avatarURL
        self.role = role
        self.rank = rank
        self.isAnonymous = isAnonymous
        self.createdAt = createdAt
    }

    /// 表示用の名前（匿名 B ランクなら nickname、それ以外は realName 優先）
    var displayName: String {
        if isAnonymous { return nickname }
        return realName ?? nickname
    }
}
