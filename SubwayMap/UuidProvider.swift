//
//  UuidProvider.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 6/17/18.
//  Copyright © 2018 Thryv. All rights reserved.
//

import UIKit

class UuidProvider: NSObject {
    static func fetch() -> String {
        if let uuid = UserDefaults.standard.string(forKey: "uuid") {
            return uuid
        } else {
            let uuid = UUID.init().uuidString
            UserDefaults.standard.set(uuid, forKey: "uuid")
            UserDefaults.standard.synchronize()
            return uuid
        }
    }
}
