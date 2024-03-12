// SPDX-FileCopyrightText: 2024 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: Apache-2.0

import Foundation

// 以下の資料を参考にしています
// https://github.com/jj1bdx/dbskkd-cdb/blob/master/skk-server-protocol.md
enum SKKServRequest {
    case end
    case request(Data) // 見出し語をエンコードしたもの
    case version
    case host

    var data: Data {
        let lf: UInt8 = 0x0a
        let space: UInt8 = 0x20

        switch self {
        case .end:
            return Data([0x30, space, lf]) // '0' + space + LF
        case .request(let key):
            var data = Data([0x31]) // '1' + key + space + LF
            data.append(key)
            data.append(contentsOf: [space, lf])
            return data
        case .version:
            return Data([0x32, space, lf]) // '2' + space + LF
        case .host:
            return Data([0x33, space, lf]) // '3' + space + LF
        }
    }
}
