//
//  Two.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 4/11/18.
//  Copyright © 2018 Thryv. All rights reserved.
//

import UIKit

struct Two<T:Hashable,U:Hashable> : Hashable {
    let values : (T, U)
    
    var hashValue : Int {
        get {
            let (a,b) = values
            return a.hashValue &* 31 &+ b.hashValue
        }
    }
}

func ==<T, U>(lhs: Two<T,U>, rhs: Two<T,U>) -> Bool {
    return lhs.values == rhs.values
}
