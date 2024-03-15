// SPDX-FileCopyrightText: 2024 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: Apache-2.0

import Network

extension NWParameters {
    static var skkserv: NWParameters {
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.connectionTimeout = 5
        let parameters = NWParameters(tls: nil, tcp: tcpOptions)
        let options = NWProtocolFramer.Options(definition: SKKServProtocol.definition)
        parameters.defaultProtocolStack.applicationProtocols = [options]
        // parameters.acceptLocalOnly = true
        return parameters
    }
}
