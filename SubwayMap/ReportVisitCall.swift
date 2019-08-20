//
//  ReportVisitCall.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 6/17/18.
//  Copyright © 2018 Thryv. All rights reserved.
//

import UIKit
import FunkyNetwork

class ReportVisitCall: JsonNetworkCall {
    
    init(configuration: ServerConfigurationProtocol = NYCServerConfiguration.current, stubHolder: StubHolderProtocol? = nil, visit: Visit) {
        let data = try? JSONEncoder().encode(visit)
        super.init(configuration: configuration, httpMethod: "POST", endpoint: "visits", postData: data, stubHolder: stubHolder)
    }

}
