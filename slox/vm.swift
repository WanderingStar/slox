//
//  vm.swift
//  slox
//
//  Created by Aneel Nazareth on 5/4/20.
//  Copyright © 2020 Aneel Nazareth. All rights reserved.
//

import Foundation

enum InterpretResult: Int {
    case Ok, CompileError, RuntimeError
}

class VM {
    var chunk = Chunk()
    var ip = 0
    var debugTraceExecution = true
    var stack: [Value] = []
    
    init() {
    }
    
    func free() {
    }
    
    func interpret(chunk: Chunk) -> InterpretResult {
        self.chunk = chunk
        self.ip = 0
        return run()
    }
    
    func interpret(source: String) -> InterpretResult {
        print(source)
        return .Ok
    }
    
    func push(_ value: Value) {
        stack.append(value)
    }
    
    func pop() -> Value {
        return stack.popLast()!
    }
    
    func readByte() -> Int8 {
        defer { ip += 1 }
        return chunk.code[ip]
    }
    
    func readConstant() -> Value {
        return chunk.constants.values[Int(readByte())]
    }
    
    func binaryOp(_ op: (Value, Value) -> Value) {
        let b = pop(), a = pop()
        push(op(a, b))
    }
    
    func run() -> InterpretResult {
        while true {
            if debugTraceExecution {
                print("          ", terminator: "")
                for slot in stack {
                    print("[ \(slot) ]", terminator: "")
                }
                print()
                _ = disassembleInstruction(chunk, offset: ip)
            }
            let instruction = readByte()
            switch OpCode(rawValue: instruction) {
            case .Constant:
                let constant = readConstant()
                push(constant)
            case .Add: binaryOp(+)
            case .Subtract: binaryOp(-)
            case .Multiply: binaryOp(*)
            case .Divide: binaryOp(/)
            case .Negate:
                push(-pop())
            case .Return:
                print(pop())
                return .Ok
            default:
                return .RuntimeError
            }
        }
    }
}
