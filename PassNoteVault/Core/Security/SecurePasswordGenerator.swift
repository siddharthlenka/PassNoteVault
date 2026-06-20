//
//  SecurePasswordGenerator.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 20/06/26.
//

import Foundation
import Security

enum GeneratedPasswordLength: Int, CaseIterable, Identifiable {
    case sixteen = 16
    case thirtyTwo = 32
    case sixtyFour = 64

    var id: Int {
        rawValue
    }

    var title: String {
        "\(rawValue)"
    }
}

enum SecurePasswordGenerator {
    private static let uppercase = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    private static let lowercase = Array("abcdefghijklmnopqrstuvwxyz")
    private static let numbers = Array("0123456789")

    // Web/app friendly special characters.
    // Avoiding quotes, backslash, spaces for fewer website compatibility issues.
    private static let specialCharacters = Array("!@#$%^&*()-_=+[]{};:,.?/")

    private static var allCharacters: [Character] {
        uppercase + lowercase + numbers + specialCharacters
    }

    static func generate(length: GeneratedPasswordLength) -> String {
        var password: [Character] = []

        password.append(randomCharacter(from: uppercase))
        password.append(randomCharacter(from: lowercase))
        password.append(randomCharacter(from: numbers))
        password.append(randomCharacter(from: specialCharacters))

        let remainingCount = length.rawValue - password.count

        for _ in 0..<remainingCount {
            password.append(randomCharacter(from: allCharacters))
        }

        return secureShuffle(password)
            .map(String.init)
            .joined()
    }

    private static func randomCharacter(from characters: [Character]) -> Character {
        let index = secureRandomInt(upperBound: characters.count)
        return characters[index]
    }

    private static func secureShuffle(_ characters: [Character]) -> [Character] {
        guard characters.count > 1 else {
            return characters
        }

        var result = characters

        for index in stride(from: result.count - 1, through: 1, by: -1) {
            let randomIndex = secureRandomInt(upperBound: index + 1)
            result.swapAt(index, randomIndex)
        }

        return result
    }

    private static func secureRandomInt(upperBound: Int) -> Int {
        guard upperBound > 0 else {
            return 0
        }

        let upperBoundUInt32 = UInt32(upperBound)
        let threshold = UInt32.max - UInt32.max % upperBoundUInt32

        while true {
            var randomNumber: UInt32 = 0

            let status = withUnsafeMutableBytes(of: &randomNumber) { buffer in
                SecRandomCopyBytes(
                    kSecRandomDefault,
                    MemoryLayout<UInt32>.size,
                    buffer.baseAddress!
                )
            }

            if status == errSecSuccess, randomNumber < threshold {
                return Int(randomNumber % upperBoundUInt32)
            }

            return Int.random(in: 0..<upperBound)
        }
    }
}
