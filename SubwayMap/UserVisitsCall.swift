//
//  UserVisitsCall.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 1/29/20.
//  Copyright © 2020 Thryv. All rights reserved.
//

import LUX
import FunNet
import Combine
import LithoOperators
import Prelude

func getUserVisitsCall(_ serverConfig: ServerConfigurationProtocol = NYCServerConfiguration.current, userId: String? = nil) -> CombineNetCall {
    var endpoint = Endpoint()
    var path = "users"
    if let uuid = userId {
        path = "\(path)/\(uuid)/visits"
    } else {
        path = "\(path)/all_visits"
    }
    endpoint.path = path
    endpoint /> addJsonHeaders
    return CombineNetCall(configuration: serverConfig, endpoint)
}
