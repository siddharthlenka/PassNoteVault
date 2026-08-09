//
//  PasswordKeyDeriver.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 08/08/26.
//

import Foundation
import CommonCrypto

enum PasswordKeyDeriverError: Error {
    case invalidPassword
    case derivationFailed
}

enum PasswordKeyDeriver {

    static let defaultIterations: UInt32 = 600_000
    static let keyLength = 32

    static func deriveKey(
        password: String,
        salt: Data,
        iterations: UInt32 = defaultIterations
    ) throws -> Data {

        guard let passwordData = password.data(using: .utf8),
              !passwordData.isEmpty else {
            throw PasswordKeyDeriverError.invalidPassword
        }

        var derivedKey = [UInt8](
            repeating: 0,
            count: keyLength
        )

        let status: Int32 = passwordData.withUnsafeBytes { passwordBytes in
            salt.withUnsafeBytes { saltBytes in

                let passwordBase = passwordBytes
                    .bindMemory(to: Int8.self)
                    .baseAddress

                let saltBase = saltBytes
                    .bindMemory(to: UInt8.self)
                    .baseAddress

                return CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    passwordBase,
                    passwordData.count,
                    saltBase,
                    salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    iterations,
                    &derivedKey,
                    keyLength
                )
            }
        }

        guard status == kCCSuccess else {
            throw PasswordKeyDeriverError.derivationFailed
        }

        return Data(derivedKey)
    }
}
