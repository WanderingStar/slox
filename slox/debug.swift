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
    case .Add:
        return simpleInstruction("OP_ADD", offset: offset)
    case .Subtract:
        return simpleInstruction("OP_SUBTRACT", offset: offset)
    case .Multiply:
        return simpleInstruction("OP_MULTIPLY", offset: offset)
    case .Divide:
        return simpleInstruction("OP_DIVIDE", offset: offset)
    case .Negate:
        return simpleInstruction("OP_NEGATE", offset: offset)
    case .Return:
        return simpleInstruction("OP_RETURN", offset: offset)
    default:
        print("Unknown opcode \(chunk.code[offset])")
        return offset + 1
    }
}
