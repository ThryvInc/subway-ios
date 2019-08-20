//
//  Functions.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 1/25/19.
//  Copyright © 2019 Thryv. All rights reserved.
//

import Prelude

precedencegroup ForwardApplication {
    associativity: left
}

infix operator <^>: ForwardApplication
func <^><A, B, C>(f: @escaping (A) -> B?, g: @escaping (B) -> C) -> (A) -> C? {
    return { a in
        if let b = f(a) {
            return g(b)
        } else {
            return nil
        }
    }
}

infix operator <>: ForwardApplication
func <><A>(f: @escaping (A) -> Void, g: @escaping (A) -> Void) -> (A) -> Void {
    return { a in
        f(a)
        g(a)
    }
}

infix operator >|>: ForwardApplication
func >|><A, B, C>(a: A, f: @escaping (A, B) -> C) -> (B) -> C {
    return { b in f(a, b) }
}

infix operator >||>: ForwardApplication
func >||><A, B, C>(b: B, f: @escaping (A, B) -> C) -> (A) -> C {
    return { a in f(a, b) }
}

public func map<U, V>(array: [U], f: (U) -> V) -> [V] {
    return array.map(f)
}

public func arrayOfSingleObject<T>(object: T) -> [T] {
    return [object]
}
