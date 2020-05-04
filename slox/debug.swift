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

func disassembleInstruction(_ chunk: Chunk, offset: Int) -> Int {
    print(String.init(format: "%04d ", offset), "")
    
    let instruction = OpCode.init(rawValue: chunk.code[offset])
    switch instruction {
    case .Return:
        return simpleInstruction("OP_RETURN", offset: offset)
    default:
        print("Unknown opcode \(chunk.code[offset])")
        return offset + 1
    }
}
