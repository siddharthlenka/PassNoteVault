//
//  SecureHexPasswordGenerator.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 19/06/26.
//

import Foundation
import Security

enum HexPasswordLength: Int, CaseIterable, Identifiable {
    case eight = 8
    case sixteen = 16
    case thirtyTwo = 32

    var id: Int {
        rawValue
    }

    var title: String {
        "\(rawValue)"
    }
}

enum SecureHexPasswordGenerator {
    private static let characters = Array("0123456789ABCDEF")

    static func generate(length: HexPasswordLength) -> String {
        var result = ""

        for _ in 0..<length.rawValue {
            result.append(randomHexCharacter())
        }

        return result
    }

    private static func randomHexCharacter() -> Character {
        var byte: UInt8 = 0
        let status = SecRandomCopyBytes(kSecRandomDefault, 1, &byte)

        if status == errSecSuccess {
            let index = Int(byte % 16)
            return characters[index]
        } else {
            return characters[Int.random(in: 0..<characters.count)]
        }
    }
}
