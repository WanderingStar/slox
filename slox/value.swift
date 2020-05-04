//
//  value.swift
//  slox
//
//  Created by Aneel Nazareth on 5/3/20.
//  Copyright © 2020 Aneel Nazareth. All rights reserved.
//

import Foundation

typealias Value = Double

struct ValueArray {
    var count = 0
    var capacity = 0
    var values: [Value] = []
    
    mutating func write(value: Value) {
        if capacity < count + 1 {
            capacity = capacity < 8 ? 8 : 2 * capacity
            values.reserveCapacity(capacity)
        }
        values.append(value)
        count += 1
    }
    
    mutating func free() {
        count = 0
        capacity = 0
        values = []
    }
}

extension Value {
    func print() {
        Swift.print(String.init(format: "%g", self), terminator: "")
    }
}
