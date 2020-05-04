//
//  common.swift
//  slox
//
//  Created by Aneel Nazareth on 5/3/20.
//  Copyright © 2020 Aneel Nazareth. All rights reserved.
//

import Foundation

enum OpCode: Int8 {
    case Return
}

struct Chunk {
    var count = 0
    var capacity = 0
    var code: [Int8] = []
    
    mutating func write(byte: Int8) {
        if capacity < count + 1 {
            capacity = capacity < 8 ? 8 : 2 * capacity
            code.reserveCapacity(capacity)
        }
        code.append(byte)
        count += 1
    }
    
    mutating func free() {
        code = []
    }
}
