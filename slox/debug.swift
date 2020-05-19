//
//  debug.swift
//  slox
//
//  Created by Aneel Nazareth on 5/3/20.
//  Copyright © 2020 Aneel Nazareth. All rights reserved.
//

import Foundation

func disassembleChunk(_ chunk: Chunk, name: String) {
    print("== \(name) ==")
    
    var offset = 0
    while offset < chunk.count {
        offset = disassembleInstruction(chunk, offset: offset)
    }
}

func simpleInstruction(_ name: String, offset: Int) -> Int {
    print(name)
    return offset + 1
}

func constantInstruction(_ name: String, chunk: Chunk, offset: Int) -> Int {
    let constant = chunk.code[offset + 1]
    print(String(format: "%-16@ %4d '\(chunk.constants.values[Int(constant)])'", name, constant));
    return offset + 2
}

func byteInstruction(_ name: String, chunk: Chunk, offset: Int) -> Int {
    let slot = chunk.code[offset + 1]
    print(String(format: "%-16@ %4d", name, slot));
    return offset + 2
}

func shortInstruction(_ name: String, chunk: Chunk, offset: Int) -> Int {
    let short = Int(chunk.code[offset + 1] << 8) | Int(chunk.code[offset + 2])
    print(String(format: "%-16@ %4d", name, short));
    return offset + 3
}

func disassembleInstruction(_ chunk: Chunk, offset: Int) -> Int {
    print(String.init(format: "%04d ", offset), terminator: "")
    
    if offset > 0 && !chunk.lines.isStartOfRun(offset) {
        print("   | ", terminator: "")
    } else {
        print(String.init(format: "%4d ", chunk.lines[offset] ?? 0), terminator: "")
    }
    
    let instruction = OpCode.init(rawValue: chunk.code[offset])
    switch instruction {
    case .Constant:
        return constantInstruction("OP_CONSTANT", chunk: chunk, offset: offset)
    case .Nil:
        return simpleInstruction("OP_NIL", offset: offset)
    case .True:
        return simpleInstruction("OP_TRUE", offset: offset)
    case .False:
        return simpleInstruction("OP_FALSE", offset: offset)
    case .Pop:
        return simpleInstruction("OP_POP", offset: offset)
    case .PopN:
        return byteInstruction("OP_POPN", chunk: chunk, offset: offset)
    case .GetLocal:
        return byteInstruction("OP_GET_LOCAL", chunk: chunk, offset: offset)
    case .SetLocal:
        return byteInstruction("OP_SET_LOCAL", chunk: chunk, offset: offset)
    case .GetGlobal:
        return constantInstruction("OP_GET_GLOBAL", chunk: chunk, offset: offset)
    case .DefineGlobal:
        return constantInstruction("OP_DEFINE_GLOBAL", chunk: chunk, offset: offset)
    case .SetGlobal:
        return constantInstruction("OP_SET_GLOBAL", chunk: chunk, offset: offset)
    case .Equal:
        return simpleInstruction("OP_EQUAL", offset: offset)
    case .Greater:
        return simpleInstruction("OP_GREATER", offset: offset)
    case .Less:
        return simpleInstruction("OP_LESS", offset: offset)
    case .Add:
        return simpleInstruction("OP_ADD", offset: offset)
    case .Subtract:
        return simpleInstruction("OP_SUBTRACT", offset: offset)
    case .Multiply:
        return simpleInstruction("OP_MULTIPLY", offset: offset)
    case .Divide:
        return simpleInstruction("OP_DIVIDE", offset: offset)
    case .Not:
        return simpleInstruction("OP_NOT", offset: offset)
    case .Negate:
        return simpleInstruction("OP_NEGATE", offset: offset)
    case .Print:
        return simpleInstruction("OP_PRINT", offset: offset)
    case .JumpIfFalse:
        return shortInstruction("OP_JUMP_IF_FALSE", chunk: chunk, offset: offset)
    case .Return:
        return simpleInstruction("OP_RETURN", offset: offset)
    case .none:
        print("Unknown opcode \(chunk.code[offset])")
        return offset + 1
    }
}
