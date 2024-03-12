// SPDX-FileCopyrightText: 2024 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: Apache-2.0

import Network

extension NWParameters {
    static var skkserv: NWParameters {
        let parameters = NWParameters.tcp
        let options = NWProtocolFramer.Options(definition: SKKServProtocol.definition)
        parameters.defaultProtocolStack.applicationProtocols.insert(options, at: 0)
        // parameters.acceptLocalOnly = true
        return parameters
    }
}
