//
//  value.swift
//  slox
//
//  Created by Aneel Nazareth on 5/3/20.
//  Copyright © 2020 Aneel Nazareth. All rights reserved.
//

import Foundation

enum Value : CustomStringConvertible {
    case valBool(Bool), valNil(Void), valNumber(Double)
    
    var description: String {
        switch self {
        case .valBool(let value):
            return value.description
        case .valNil():
            return "nil"
        case .valNumber(let value):
            return String.init(format: "%g", value)
            
        }
    }
    
    var boolean: Bool? {
        switch self {
        case .valBool(let value):
            return value
        default:
            return nil
        }
    }
    
    var number: Double? {
        switch self {
        case .valNumber(let value):
            return value
        default:
            return nil
        }
    }
}

func +(a: Value, b: Value) -> Value {
    switch (a, b) {
    case (.valNumber(let dA), .valNumber(let dB)):
        return .valNumber(dA + dB)
    default:
        return .valNumber(Double.nan)
    }
}


func -(a: Value, b: Value) -> Value {
    switch (a, b) {
    case (.valNumber(let dA), .valNumber(let dB)):
        return .valNumber(dA - dB)
    default:
        return .valNumber(Double.nan)
    }
}

func *(a: Value, b: Value) -> Value {
    switch (a, b) {
    case (.valNumber(let dA), .valNumber(let dB)):
        return .valNumber(dA * dB)
    default:
        return .valNumber(Double.nan)
    }
}


func /(a: Value, b: Value) -> Value {
    switch (a, b) {
    case (.valNumber(let dA), .valNumber(let dB)):
        return .valNumber(dA / dB)
    default:
        return .valNumber(Double.nan)
    }
}

prefix func -(a: Value) -> Value {
    switch a {
    case .valNumber(let dA):
        return .valNumber(-dA)
    default:
        return .valNumber(Double.nan)
    }
}

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
