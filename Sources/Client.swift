// SPDX-FileCopyrightText: 2024 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: Apache-2.0

import ArgumentParser
import Foundation
import Network

enum ResponseEncoding: String, EnumerableFlag {
    case eucJp
    case utf8

    var encoding: String.Encoding {
        switch self {
        case .eucJp:
            return .japaneseEUC
        case .utf8:
            return .utf8
        }
    }
}

@main
struct Client: AsyncParsableCommand {
    @Argument var host: String
    @Argument var port: UInt16 = 1178
    @Flag var responseEncoding: ResponseEncoding

    mutating func run() async throws {
        guard let port = NWEndpoint.Port(rawValue: port) else {
            fatalError("Error: Invalid port")
        }
        guard let conn = try await connect(host: NWEndpoint.Host(host), port: port) else {
            fatalError("Cancelled")
        }
        var data = Data()
        while let line = readLine(strippingNewline: true) {
            let message: NWProtocolFramer.Message
            if line == "version" { // サーバーのバージョンを取得する
                message = NWProtocolFramer.Message(request: .version)
            } else if line == "end" {
                message = NWProtocolFramer.Message(request: .end)
            } else {
                guard let encoded = line.data(using: .utf8) else { fatalError("Fail to encode string") }
                message = NWProtocolFramer.Message(request: .request(encoded))
            }
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
            if let receive, let string = String(data: receive, encoding: responseEncoding.encoding) {
                printErr("Received: \(string)")
            } else if let receive, let string = String(data: receive, encoding: .japaneseEUC) {
                // エントリが見つからなかったとき、yaskkserv2は "--midashi-utf8" で起動してても必ずEUC-JPで返す
                printErr("Received: \(string)")
            } else {
                printErr("Invalid response (Decode Error): \(receive)")
            }
        }
    }

    func connect(host: NWEndpoint.Host, port: NWEndpoint.Port) async throws -> NWConnection? {
        let conn = NWConnection(host: host, port: port, using: .skkserv)
        return try await withCheckedThrowingContinuation { cont in
            conn.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    printErr("Ready")
                    cont.resume(returning: conn)
                case .waiting(let error):
                    // 接続先がbind + listenされてない場合には "POSIXErrorCode(rawValue: 61): Connection refused" が発生する
                    // listenされているがacceptされない場合は "POSIXErrorCode(rawValue: 60): Operation timed out" が発生する
                    // (NWProtocolTCP.OptionsでTCPのconnectionTimeoutが設定されていた場合。設定されてない場合は永久に待つっぽい)
                    printErr("Waiting: \(error)")
                    cont.resume(throwing: error)
                case .failed(let error):
                    cont.resume(throwing: error)
                case .setup:
                    printErr("Setup")
                case .preparing:
                    printErr("Prepating")
                case .cancelled:
                    printErr("Cancelled")
                    cont.resume(returning: nil)
                @unknown default:
                    fatalError("Unknown status")
                }
            }
            conn.start(queue: .main)
        }
    }
}
