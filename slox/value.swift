//
//  value.swift
//  slox
//
//  Created by Aneel Nazareth on 5/3/20.
//  Copyright © 2020 Aneel Nazareth. All rights reserved.
//

import Foundation

enum Value : CustomStringConvertible, Comparable, Equatable {
    
    case valBool(Bool), valNil(Void), valNumber(Double), valObj(UnsafeMutablePointer<Obj>)
    
    var description: String {
        switch self {
        case .valBool(let value):
            return value.description
        case .valNil():
            return "nil"
        case .valNumber(let value):
            return String.init(format: "%g", value)
        case .valObj(let obj):
            switch obj.pointee.type {
            case .String: return asString ?? "<bad Obj>"
            case .Function:
                if let function = asObjFunction {
                    if let name = function.name {
                        return "<fn \(String(objString: name.pointee))>"
                    } else {
                        return "<script>"
                    }
                } else {
                    return "<bad Obj>"
                }
            }
        }
    }
    
    var isFalsey: Bool {
        switch self {
        case .valBool(let value):
            return !value
        case .valNil:
            return true
        default:
            return false
        }
    }
    
    func isObjType(_ type: ObjType) -> Bool {
        if case let .valObj(ptr) = self {
            return ptr.pointee.type == type
        }
        return false
    }
    
    var asObjString: ObjString? {
        if case let .valObj(ptr) = self {
            return ptr.withMemoryRebound(to: ObjString.self, capacity: 1) {
                (ptr) -> ObjString in
                return ptr.pointee
            }
        }
        return nil
    }
    
    var asString: String? {
        guard let objString = asObjString else { return nil }
        return String(bytesNoCopy: objString.chars, length: objString.length, encoding: .ascii, freeWhenDone: false) ?? "<bad ObjString>"
    }
    
    var asObjFunction: ObjFunction? {
        if case let .valObj(ptr) = self {
            return ptr.withMemoryRebound(to: ObjFunction.self, capacity: 1) {
                (ptr) -> ObjFunction in
                return ptr.pointee
            }
        }
        return nil
    }
    
    static func from(objStringPtr: UnsafeMutablePointer<ObjString>) -> Value {
        return objStringPtr.withMemoryRebound(to: Obj.self, capacity: 1) {
            (ptr) -> Value in
            return .valObj(ptr)
        }
    }
    
    static func from(objFunctionPtr: UnsafeMutablePointer<ObjFunction>) -> Value {
        return objFunctionPtr.withMemoryRebound(to: Obj.self, capacity: 1) {
            (ptr) -> Value in
            return .valObj(ptr)
        }
    }
    
    static func < (lhs: Value, rhs: Value) -> Bool {
        switch (lhs, rhs) {
        case (.valNumber(let a), .valNumber(let b)):
            return a < b
        default:
            return false
        }
    }
}

func +(a: Value, b: Value) -> Value {
    switch (a, b) {
    case (.valNumber(let dA), .valNumber(let dB)):
        return .valNumber(dA + dB)
    default:
        assert(false, "Can only add numbers.")
        return .valNumber(Double.nan)
    }
}

func -(a: Value, b: Value) -> Value {
    switch (a, b) {
    case (.valNumber(let dA), .valNumber(let dB)):
        return .valNumber(dA - dB)
    default:
        assert(false, "Can only subtract numbers.")
        return .valNumber(Double.nan)
    }
}

func *(a: Value, b: Value) -> Value {
    switch (a, b) {
    case (.valNumber(let dA), .valNumber(let dB)):
        return .valNumber(dA * dB)
    default:
        assert(false, "Can only multiply numbers.")
        return .valNumber(Double.nan)
    }
}

func /(a: Value, b: Value) -> Value {
    switch (a, b) {
    case (.valNumber(let dA), .valNumber(let dB)):
        return .valNumber(dA / dB)
    default:
        assert(false, "Can only divide numbers.")
        return .valNumber(Double.nan)
    }
}

prefix func -(a: Value) -> Value {
    switch a {
    case .valNumber(let dA):
        return .valNumber(-dA)
    default:
        assert(false, "Can only negate numbers.")
        return .valNumber(Double.nan)
    }
}

func >(a: Value, b: Value) -> Value {
    switch (a, b) {
    case (.valNumber(let dA), .valNumber(let dB)):
        return .valBool(dA > dB)
    default:
        assert(false, "Can only compare numbers.")
        return .valBool(false)
    }
}

func <(a: Value, b: Value) -> Value {
    switch (a, b) {
    case (.valNumber(let dA), .valNumber(let dB)):
        return .valBool(dA < dB)
    default:
        assert(false, "Can only compare numbers.")
        return .valBool(false)
    }
}

func ==(a: Value, b: Value) -> Bool {
    switch (a, b) {
    case (.valBool(let vA), .valBool(let vB)):
        return vA == vB
    case (.valNil, .valNil):
        return true
    case (.valNumber(let vA), .valNumber(let vB)):
        return vA == vB
    case (.valObj(let oA), .valObj(let oB)):
        let equal = oA == oB
        return equal
    default:
        return false
    }
}

func growCapacity(_ capacity: Int) -> Int {
    return capacity < 8 ? 8 : 2 * capacity
}

struct ValueArray {
    var count = 0
    var capacity = 0
    var values: [Value] = []
    
    func scan(value: Value) -> Int? {
        let index = values.firstIndex(of: value)
        return index
    }
    
    mutating func write(value: Value) {
        if capacity < count + 1 {
            capacity = growCapacity(capacity)
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
