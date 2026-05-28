@testable import Runvox
import XCTest

final class AuthValidatorTests: XCTestCase {
    // MARK: - Email

    func test_validEmail_returnsTrimmedEmail() throws {
        let result = try AuthValidator.validateEmail("  user@example.com  ").get()
        XCTAssertEqual(result, "user@example.com")
    }

    func test_emailWithoutAtSign_throwsInvalidEmail() {
        XCTAssertThrowsError(try AuthValidator.validateEmail("invalid").get()) { error in
            XCTAssertEqual(error as? AuthError, .invalidEmail)
        }
    }

    func test_emailWithoutDomain_throwsInvalidEmail() {
        XCTAssertThrowsError(try AuthValidator.validateEmail("user@").get()) { error in
            XCTAssertEqual(error as? AuthError, .invalidEmail)
        }
    }

    func test_emailWithoutTLD_throwsInvalidEmail() {
        XCTAssertThrowsError(try AuthValidator.validateEmail("user@example").get()) { error in
            XCTAssertEqual(error as? AuthError, .invalidEmail)
        }
    }

    // MARK: - Password

    func test_validPassword_returnsPassword() throws {
        let result = try AuthValidator.validatePassword("Password123").get()
        XCTAssertEqual(result, "Password123")
    }

    func test_shortPassword_throwsWeakPassword() {
        XCTAssertThrowsError(try AuthValidator.validatePassword("Abc12").get()) { error in
            if case .weakPassword = error as? AuthError {
                // expected
            } else {
                XCTFail("expected weakPassword, got \(error)")
            }
        }
    }

    func test_passwordWithoutDigit_throwsWeakPassword() {
        XCTAssertThrowsError(try AuthValidator.validatePassword("OnlyLetters").get()) { error in
            if case .weakPassword = error as? AuthError {
                // expected
            } else {
                XCTFail("expected weakPassword, got \(error)")
            }
        }
    }

    func test_passwordWithoutLetter_throwsWeakPassword() {
        XCTAssertThrowsError(try AuthValidator.validatePassword("12345678").get()) { error in
            if case .weakPassword = error as? AuthError {
                // expected
            } else {
                XCTFail("expected weakPassword, got \(error)")
            }
        }
    }

    // MARK: - Nickname

    func test_validNickname_returnsTrimmedNickname() throws {
        let result = try AuthValidator.validateNickname("  太郎  ").get()
        XCTAssertEqual(result, "太郎")
    }

    func test_tooShortNickname_throwsInvalidNickname() {
        XCTAssertThrowsError(try AuthValidator.validateNickname("a").get()) { error in
            if case .invalidNickname = error as? AuthError {
                // expected
            } else {
                XCTFail("expected invalidNickname, got \(error)")
            }
        }
    }

    func test_tooLongNickname_throwsInvalidNickname() {
        let long = String(repeating: "あ", count: 21)
        XCTAssertThrowsError(try AuthValidator.validateNickname(long).get()) { error in
            if case .invalidNickname = error as? AuthError {
                // expected
            } else {
                XCTFail("expected invalidNickname, got \(error)")
            }
        }
    }
}
