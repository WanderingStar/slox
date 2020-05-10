//
//  compiler.swift
//  slox
//
//  Created by Aneel Nazareth on 5/5/20.
//  Copyright © 2020 Aneel Nazareth. All rights reserved.
//

import Foundation

struct Parser {
    var scanner: Scanner
    var current: Token?
    var previous: Token?
    var hadError = false
    var panicMode = false
    
    init(source: String) {
        scanner = Scanner(source: source)
    }
    
    mutating func advance() {
        previous = current
        
        while true {
            current = scanner.scanToken()
            guard let current = current else { return }
            if current.type != .tokenError {
            break
            }
            errorAtCurrent(message: current.text.description)
        }
    }
    
    mutating func consume(type: TokenType, message: String) {
        if (current?.type == type) {
            advance()
            return
        }
        
        errorAtCurrent(message: message)
    }
    
    mutating func errorAtCurrent(message: String) {
        errorAt(token: current, message: message)
    }
    
    mutating func error(message: String) {
        errorAt(token: previous, message: message)
    }
    
    mutating func errorAt(token: Token?, message: String) {
        if panicMode { return }
        panicMode = true
        guard let token = token else {
            printErr(format: "Missing token in errorAt: " + message)
            return
        }
        printErr(format: "[line \(token.line)] Error")
        switch token.type {
        case .tokenEOF:
        printErr(format: " at end")
        case .tokenError:
            break
        default:
            printErr(format: " at '\(token.text)")
        }
        printErr(format: ": \(message)\n")
        hadError = true
    }
}

class compiler {
    var parser: Parser
    var compilingChunk: Chunk
    
    init(source: String, chunk: Chunk) {
        parser = Parser(source: source)
        compilingChunk = chunk
    }
    
    func compile() -> Bool {
        _ = parser.advance()
        expression()
        parser.consume(type: .tokenEOF, message: "Expect end of expression")
        endCompiler()
        return !parser.hadError
    }
    
    var currentChunk: Chunk {
        return compilingChunk
    }
    
    func emit(byte: UInt8) {
        compilingChunk.write(byte: byte, line: parser.previous?.line ?? -1)
    }
    
    func emit(opCode: OpCode) {
        compilingChunk.write(op: opCode, line: parser.previous?.line ?? -1)
    }
    
    func emit(opCode: OpCode, byte: UInt8) {
        emit(opCode: opCode)
        emit(byte: byte)
    }
    
    func emitReturn() {
        emit(opCode: .Return)
    }
    
    func endCompiler() {
        emitReturn()
    }
    
    func expression() {
        
    }
    
}
