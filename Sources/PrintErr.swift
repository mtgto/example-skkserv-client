// SPDX-FileCopyrightText: 2024 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: Apache-2.0

import Foundation

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        guard let data = string.data(using: .utf8) else {
          return
        }
        try? write(contentsOf: data)
    }
}

public func printErr(_ value: String, separator: String = " ", terminator: String = "\n") {
    var standardError = FileHandle.standardError
    print(value, separator: separator, terminator: terminator, to: &standardError)
}
