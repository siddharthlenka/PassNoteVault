//
//  RecoveryPassphraseGenerator.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 10/06/26.
//


import Foundation
import Security

enum RecoveryPassphraseGenerator {
    static func generate12DigitPassphrase() -> String {
        var digits: [String] = []

        for _ in 0..<12 {
            digits.append(String(secureRandomDigit()))
        }

        return digits
            .joined()
            .chunked(into: 3)
            .joined(separator: "-")
    }

    private static func secureRandomDigit() -> Int {
        var byte: UInt8 = 0
        let status = SecRandomCopyBytes(kSecRandomDefault, 1, &byte)

        if status == errSecSuccess {
            return Int(byte % 10)
        } else {
            return Int.random(in: 0...9)
        }
    }
}

private extension String {
    func chunked(into size: Int) -> [String] {
        stride(from: 0, to: count, by: size).map { index in
            let start = self.index(startIndex, offsetBy: index)
            let end = self.index(start, offsetBy: size, limitedBy: endIndex) ?? endIndex
            return String(self[start..<end])
        }
    }
}