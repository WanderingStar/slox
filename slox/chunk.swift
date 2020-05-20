//
//  common.swift
//  slox
//
//  Created by Aneel Nazareth on 5/3/20.
//  Copyright © 2020 Aneel Nazareth. All rights reserved.
//

import Foundation

enum OpCode: UInt8 {
    case Constant, Nil, True, False,
    Pop, PopN,
    GetLocal, SetLocal,
    GetGlobal, DefineGlobal, SetGlobal,
    Equal, Greater, Less,
    Add, Subtract, Multiply, Divide,
    Not, Negate,
    Print,
    Jump, JumpIfFalse, JumpIfUnequal, Loop,
    Return 
}

struct Chunk {
    var count = 0
    var capacity = 0
    var code: [UInt8] = []
    var lines = runLengthEncoded<Int>()
    var constants: ValueArray = ValueArray()
    
    mutating func write(op: OpCode, line: Int) {
        write(byte: op.rawValue, line: line)
    }

    mutating func write(byte: UInt8, line: Int) {
        if capacity < count + 1 {
            capacity = capacity < 8 ? 8 : 2 * capacity
            code.reserveCapacity(capacity)
        }
        code.append(byte)
        lines.append(line, at: count)
        count += 1
    }
    
    mutating func free() {
        count = 0
        capacity = 0
        code = []
        lines = runLengthEncoded<Int>()
        constants.free()
    }
    
    mutating func addConstant(value: Value) -> Int {
        if let index = constants.scan(value: value) {
            return index
        }
        constants.write(value: value)
        return constants.count - 1
    }
}
