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

struct CallFrame {
    var function: UnsafeMutablePointer<ObjFunction>
    var ip: Int  // index into the code
    var slots: Int  // index into Stack
}

let framesMax = 64

class VM {
    var frames: [CallFrame] = []
    var debugTraceExecution = true
    var stack: [Value] = []
    var globals = Table()
    var strings = Table()
    var objects: UnsafeMutablePointer<Obj>? = nil
    var current: CompilerState
    
    var frame: CallFrame {
        get { frames.last! }
        set(newValue) { frames[frames.count - 1] = newValue }
    }
    
    var chunk: Chunk {
        return frame.function.pointee.chunk
    }
    
    init() {
        frames.reserveCapacity(framesMax)
        stack.reserveCapacity(framesMax * Int(UINT8_COUNT))
        var locals: [Local] = []
        locals.reserveCapacity(Int(UINT8_COUNT))
        current = CompilerState(locals: locals)
    }
    
    func free() {
        stack = []
        freeObjects()
        freeTable(&globals)
        freeTable(&strings)
    }
    
    func interpret(source: String) -> InterpretResult {
        let compiler = Compiler(source: source, functionType: .Script, vm: self, state: current)
        guard let compiled = compiler.compile() else {
            return .CompileError
        }
        push(Value.from(objFunctionPtr: compiled))
        let frame = CallFrame(function: compiled, ip: 0, slots: stack.count)
        frames.append(frame)

        return run()
    }
    
    func push(_ value: Value) {
        stack.append(value)
    }
    
    func pop() -> Value {
        return stack.popLast()!
    }
    
    func popN(_ n: UInt8) {
        return stack.removeLast(Int(n))
    }
    
    func peek(_ distance: Int) -> Value {
        return stack[stack.count - 1 - distance]
    }
    
    func readByte() -> UInt8 {
        defer { frame.ip += 1 }
        return frame.function.pointee.chunk.code[Int(frame.ip)]
    }
    
    func readConstant() -> Value {
        return chunk.constants.values[Int(readByte())]
    }
    
    func readShort() -> UInt16 {
        frame.ip += 2
        return UInt16(chunk.code[Int(frame.ip - 2)] << 8) | UInt16(chunk.code[Int(frame.ip - 1)])
    }
    
    func readString() -> UnsafeMutablePointer<ObjString> {
        guard case .valObj(let ptr) = readConstant() else {
            preconditionFailure("Tried to read string and failed")
        }
        return ptr.withMemoryRebound(to: ObjString.self, capacity: 1) { (objStringPtr) -> UnsafeMutablePointer<ObjString> in
            return objStringPtr
        }
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
                // print(tableEntries(table: strings))
                _ = disassembleInstruction(chunk, offset: Int(frame.ip))
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
            case .Pop:
                _ = pop()
            case .PopN:
                let n = readByte()
                popN(n)
            case .GetLocal:
                let slot = Int(readByte())
                push(stack[Int(frame.slots + slot)])
            case .SetLocal:
                let slot = Int(readByte())
                stack[Int(frame.slots + slot)] = peek(0)
            case .GetGlobal:
                let name = readString()
                guard let value = tableGet(table: globals, key: name) else {
                    runtimeError(format: "Undefined variable '%s'.", name.pointee.chars)
                    return .RuntimeError
                }
                push(value)
            case .DefineGlobal:
                let name = readString()
                _ = tableSet(table: &globals, key: name, value: peek(0))
                _ = pop()
            case .SetGlobal:
                let name = readString()
                if tableSet(table: &globals, key: name, value: peek(0)) {
                    _ = tableDelete(table: &globals, key: name)
                    runtimeError(format: "Undefined variable '%s'.", name.pointee.chars)
                    return .RuntimeError
                }
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
                    let b = pop(), a = pop()
                    concatenate(a: a, b: b)
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
            case .Print:
                print(pop())
            case .Jump:
                let offset = readShort()
                frame.ip += Int(offset)
            case .JumpIfFalse:
                let offset = readShort()
                if (peek(0).isFalsey) {
                    frame.ip += Int(offset)
                }
            case .JumpIfUnequal:
                // this is for switch, so it does NOT pop the first artument
                let b = pop(), a = peek(0)
                let offset = readShort()
                if (a != b) {
                    frame.ip += Int(offset)
                }
            case .Loop:
                let offset = readShort()
                frame.ip -= Int(offset)
            default:
                return .RuntimeError
            }
        }
    }
    
    func runtimeError(format: String, _ arguments: Any...) {
        printErr(format: format + "\n", arguments)
        let instruction = frame.ip - 1
        let line = chunk.lines[Int(instruction)]
        printErr(format: "[line \(line ?? -1)] in script\n")
    }

}
