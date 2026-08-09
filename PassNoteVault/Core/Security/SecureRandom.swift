//
//  SecureRandom.swift
//  PassNoteVault
//
//  Created by siddharth lenka on 08/08/26.
//

import Foundation
import Security

enum SecureRandomError: Error {
    case generationFailed(OSStatus)
}

enum SecureRandom {

    static func data(count: Int) throws -> Data {

        var bytes = [UInt8](
            repeating: 0,
            count: count
        )

        let status = SecRandomCopyBytes(
            kSecRandomDefault,
            bytes.count,
            &bytes
        )

        guard status == errSecSuccess else {
            throw SecureRandomError.generationFailed(status)
        }

        return Data(bytes)
    }
}
