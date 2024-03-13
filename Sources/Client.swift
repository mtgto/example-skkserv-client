// SPDX-FileCopyrightText: 2024 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: Apache-2.0

import ArgumentParser
import Foundation
import Network

@main
struct Client: AsyncParsableCommand {
    @Argument var host: String
    @Argument var port: UInt16 = 1178

    mutating func run() async throws {
        guard let port = NWEndpoint.Port(rawValue: port) else {
            fatalError("Error: Invalid port")
        }
        guard let conn = try await connect(host: NWEndpoint.Host(host), port: port) else {
            fatalError("Cancelled")
        }
        var data = Data()
        while true {
            guard let line = readLine(strippingNewline: false) else { break }
            print("Send \(line)")
            guard let encoded = line.data(using: .utf8) else { fatalError("Fail to encode string") }
            let message = NWProtocolFramer.Message(request: .request(encoded))
            let context = NWConnection.ContentContext(identifier: "SKKServRequest", metadata: [message])
            try await withCheckedThrowingContinuation { cont in
                conn.send(content: nil, contentContext: context, isComplete: true, completion: .contentProcessed({ error in
                    if let error {
                        cont.resume(throwing: error)
                    } else {
                        cont.resume(returning: ())
                    }
                }))
            } as Void
            print("Receiving")
            let receive: Data? = try await withCheckedThrowingContinuation { cont in
                conn.receiveMessage { content, contentContext, isComplete, error in
                    if let error {
                        cont.resume(throwing: error)
                    } else if let message = contentContext?.protocolMetadata(definition: SKKServProtocol.definition) as? NWProtocolFramer.Message, let response = message.response {
                        cont.resume(returning: response)
                    } else {
                        cont.resume(returning: nil)
                    }
                }
            }
            print("Received \(receive?.count)")
        }
    }

    func connect(host: NWEndpoint.Host, port: NWEndpoint.Port) async throws -> NWConnection? {
        let conn = NWConnection(host: host, port: port, using: .skkserv)
        return try await withCheckedThrowingContinuation { cont in
            conn.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("Ready")
                    cont.resume(returning: conn)
                case .waiting:
                    print("Waiting")
                case .failed(let error):
                    cont.resume(throwing: error)
                case .setup:
                    print("Setup")
                case .preparing:
                    print("Prepating")
                case .cancelled:
                    print("Cancelled")
                    cont.resume(returning: nil)
                @unknown default:
                    fatalError("Unknown status")
                }
            }
            conn.start(queue: .main)
        }
    }
}
