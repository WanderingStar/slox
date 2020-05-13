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
    var objects: UnsafeMutablePointer<Obj>? = nil
    
    init() {
    }
    
    func free() {
        chunk = Chunk()
        stack = []
        freeObjects()
    }
    
    func interpret(chunk: Chunk) -> InterpretResult {
        self.chunk = chunk
        self.ip = 0
        return run()
    }
    
    func interpret(source: String) -> InterpretResult {
        let compiler = Compiler(source: source, chunk: chunk, vm: self)
        guard let compiled = compiler.compile() else {
            return .CompileError
        }
        chunk = compiled
        ip = 0
        let result = run()
        chunk.free()
        return result
    }
    
    func push(_ value: Value) {
        stack.append(value)
    }
    
    func pop() -> Value {
        return stack.popLast()!
    }
    
    func peek(_ distance: Int) -> Value {
        return stack[-1 - distance]
    }
    
    func readByte() -> UInt8 {
        defer { ip += 1 }
        return chunk.code[ip]
    }
    
    func readConstant() -> Value {
        return chunk.constants.values[Int(readByte())]
    }
    
    func binaryOp(_ op: (Value, Value) -> Value) -> InterpretResult? {
        let b = pop(), a = pop()
        switch (a, b) {
        case (.valNumber, .valNumber):
            push(op(a, b))
            return nil
        default:
            runtimeError(format: "Operands must be numbers.")
            return .RuntimeError
        }
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
            case .Nil:
                push(.valNil(()))
            case .True:
                push(.valBool(true))
            case .False:
                push(.valBool(false))
                
            case .Equal:
                let b = pop(), a = pop()
                push(.valBool(a == b))
            case .Greater:
                if let error = binaryOp(>) {
                    return error
                }
            case .Less:
                if let error = binaryOp(<) {
                    return error
                }
            case .Add:
                if peek(0).isObjType(.String) && peek(1).isObjType(.String) {
                    concatenate(a: peek(0), b: peek(0))
                } else if let error = binaryOp(+) {
                    return error
                }
            case .Subtract:
                if let error = binaryOp(-) {
                    return error
                }
            case .Multiply:
                if let error = binaryOp(*) {
                    return error
                }
            case .Divide:
                if let error = binaryOp(/) {
                    return error
                }
            case .Not:
                push(.valBool(pop().isFalsey))
            case .Negate:
                switch peek(0) {
                case .valNumber:
                    push(-pop())
                default:
                    runtimeError(format: "Operand must be a number.");
                    return .RuntimeError
                }
            case .Return:
                print(pop())
                return .Ok
            default:
                return .RuntimeError
            }
        }
    }
    
    func runtimeError(format: String, _ arguments: Any...) {
        printErr(format: format + "\n", arguments)
        let instruction = ip - 1
        let line = chunk.lines[instruction]
        printErr(format: "[line \(line ?? -1)] in script\n")
    }

}
