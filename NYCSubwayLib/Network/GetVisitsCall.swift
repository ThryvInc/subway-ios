//
//  GetVisitsCall.swift
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

func getVisitsCall(_ serverConfig: ServerConfigurationProtocol = Current.serverConfig, filters: String) -> CombineNetCall {
    var endpoint = Endpoint()
    endpoint.path = "visits?\(filters)"
    endpoint /> addJsonHeaders
    return CombineNetCall(configuration: serverConfig, endpoint)
}

//class GetVisitsCall: JsonNetworkCall {
//    lazy var visitsSignal = self.dataSignal.skipNil().map(GetVisitsCall.parse).skipNil()
//
//    init(configuration: ServerConfigurationProtocol = NYCServerConfiguration.current, stubHolder: StubHolderProtocol? = nil, filters: String) {
//        super.init(configuration: configuration, httpMethod: "GET", endpoint: "visits?\(filters)", postData: nil, stubHolder: stubHolder)
//    }
//
//    static func parse(data: Data) -> [Visit]? {
//        do {
//            let decoder = JSONDecoder()
//            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Seconds)
//            let result = try decoder.decode(VisitsResponse.self, from: data)
//            return result.visits
//        } catch {
//            print("\(error)")
//            return nil
//        }
//    }
//}
