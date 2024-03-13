// SPDX-FileCopyrightText: 2024 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: Apache-2.0

import Foundation
import Network

final class SKKServProtocol: NWProtocolFramerImplementation {
    static let label: String = "skkserv"
    static let definition = NWProtocolFramer.Definition(implementation: SKKServProtocol.self)

    required init(framer: NWProtocolFramer.Instance) {}

    func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult {
        .ready
    }

    func handleInput(framer: NWProtocolFramer.Instance) -> Int {
        while true {
            var received: Data? = nil
            let result = framer.parseInput(minimumIncompleteLength: 4, maximumLength: 1024 * 1024) { buffer, isComplete -> Int in
                // TODO: 直前のリクエストがサーバーのバージョン要求、サーバーのホスト名とIPアドレスのリスト要求の場合はスペースが終端記号となる
                if let buffer, let index = buffer.firstIndex(of: 0x0a) {
                    printErr("Found LF at \(index)")
                    buffer[0..<index].withUnsafeBytes { pointer in
                        received = Data(pointer)
                    }
                }
                return 0
            }
            guard let received else {
                return 0
            }
            let message = NWProtocolFramer.Message(response: received)
            _ = framer.deliverInputNoCopy(length: received.count + 1, message: message, isComplete: true)
        }
    }

    func handleOutput(framer: NWProtocolFramer.Instance, message: NWProtocolFramer.Message, messageLength: Int, isComplete: Bool) {
        guard let request = message.request else {
            fatalError("request is not set")
        }
        framer.writeOutput(data: request.data)
    }

    func wakeup(framer: NWProtocolFramer.Instance) {}

    func stop(framer: NWProtocolFramer.Instance) -> Bool {
        //framer.writeOutput(data: <#T##Data#>)
        return true
    }

    func cleanup(framer: NWProtocolFramer.Instance) {}
}
