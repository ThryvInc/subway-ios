//
//  ReportVisitCall.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 6/17/18.
//  Copyright © 2018 Thryv. All rights reserved.
//

import LUX
import FunNet
import Combine
import LithoOperators
import Prelude

func reportVisitCall(_ serverConfig: ServerConfigurationProtocol = NYCServerConfiguration.current, visit: Visit) -> CombineNetCall {
    var endpoint = Endpoint()
    endpoint.path = "visits"
    endpoint /> setToPost
    endpoint /> addJsonHeaders
    endpoint.postData = LUXJsonProvider.encode(VisitWrapper(visit: visit))
    return CombineNetCall(configuration: serverConfig, endpoint)
}

struct VisitWrapper {
    let visit: Visit
}
extension VisitWrapper: Codable {}
