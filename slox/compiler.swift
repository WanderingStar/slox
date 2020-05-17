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
    
    mutating func check(type: TokenType) -> Bool {
        return current?.type == type
    }
    
    mutating func match(type: TokenType) -> Bool {
        if (!check(type: type)) {
            return false
        }
        advance()
        return true;
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

enum Precedence: Int {
    case None,
    Assignment, // =
    Or,         // or
    And,        // and
    Equality,   // == !==
    Comparison, // < > <= >=
    Term,       // + -
    Factor,     // * /
    Unary,      // ! -
    Call,       // . ()
    Primary
    
    var higher: Precedence? {
        return Precedence(rawValue: rawValue + 1)
    }
}
extension Precedence: Comparable {
    static func < (lhs: Precedence, rhs: Precedence) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

typealias ParseFn = (Compiler) -> (Bool) -> ()

struct ParseRule {
    let prefix: ParseFn?
    let infix: ParseFn?
    let precedence: Precedence
    
    init(_ prefix: ParseFn?, _ infix: ParseFn?, _ precedence: Precedence) {
        self.prefix = prefix
        self.infix = infix
        self.precedence = precedence
    }
}

let UINT8_COUNT = UINT8_MAX + 1

struct Local {
    let name: Token
    let depth: Int
}

struct CompilerState {
    var locals: [Local]
    var localCount = 0
    var scopeDepth = 0
}

class Compiler {
    var parser: Parser
    var compilingChunk: Chunk
    var debugPrintCode = true
    var vm: VM
    var current: CompilerState
    
    init(source: String, chunk: Chunk, vm: VM, state: CompilerState) {
        parser = Parser(source: source)
        compilingChunk = chunk
        self.vm = vm
        self.current = state
    }
    
    func compile() -> Chunk? {
        _ = parser.advance()
        // expression()
        // parser.consume(type: .tokenEOF, message: "Expect end of expression")
        while !parser.match(type: .tokenEOF) {
            declaration()
        }
        
        endCompiler()
        return parser.hadError ? nil : currentChunk
    }
    
    var currentChunk: Chunk {
        get {
            return compilingChunk
        }
        set(newChunk) {
            compilingChunk = newChunk
        }
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
    
    func emit(constant: Value) {
        emit(opCode: .Constant, byte: makeConstant(value: constant))
    }
    
    func emitReturn() {
        emit(opCode: .Return)
    }
    
    func makeConstant(value: Value) -> UInt8 {
        let constant = currentChunk.addConstant(value: value)
        if (constant > UINT8_MAX) {
            parser.error(message: "Too many constants in one chunk.")
            return 0;
        }
        return UInt8(constant)
    }
    
    func endCompiler() {
        if (debugPrintCode && !parser.hadError) {
            disassembleChunk(currentChunk, name: "code")
        }
        emitReturn()
    }
    
    func beginScope() {
        current.scopeDepth += 1
    }
    
    func endScope() {
        current.scopeDepth -= 1
        
        let start = current.localCount
        while current.localCount > 0 &&
            current.locals[current.localCount - 1].depth > current.scopeDepth {
                current.localCount -= 1
        }
        emit(opCode: .PopN, byte: UInt8(start - current.localCount))
    }
    
    func binary(_ canAssign: Bool) {
        // Remember the operator.
        guard let operatorType = parser.previous?.type
            else {
                parser.error(message: "Binary with no previous.")
                return
        }
        
        // Compile the right operand.
        let rule = Compiler.getRule(type: operatorType)
        guard let nextPrecedence = rule.precedence.higher else {
            parser.error(message: "No higher precedence.")
            return
        }
        parsePrecedence(nextPrecedence)
        
        // Emit the operator instruction.
        switch operatorType {
        case .tokenBangEqual:
            emit(opCode: .Equal)
            emit(opCode: .Not)
        case .tokenEqualEqual: emit(opCode: .Equal)
        case .tokenGreater: emit(opCode: .Greater)
        case .tokenGreaterEqual:
            emit(opCode: .Less)
            emit(opCode: .Not)
        case .tokenLess: emit(opCode: .Less)
        case .tokenLessEqual:
            emit(opCode: .Greater)
            emit(opCode: .Not)
        case .tokenPlus: emit(opCode: .Add)
        case .tokenMinus: emit(opCode: .Subtract)
        case .tokenStar: emit(opCode: .Multiply)
        case .tokenSlash: emit(opCode: .Divide)
        default:
            assert(false) // Unreachable.
        }
    }
    
    func literal(_ canAssign: Bool) {
        switch parser.previous?.type {
        case .tokenFalse: emit(opCode: .False)
        case .tokenNil: emit(opCode: .Nil)
        case .tokenTrue: emit(opCode: .True)
        default:
            assert(false) // Unreachable.
        }
    }
    
    func grouping(_ canAssign: Bool) {
        expression()
        parser.consume(type: .tokenRightParen,
                       message: "Expect ')' after expression.")
    }
    
    func number(_ canAssign: Bool) {
        guard let string = parser.previous?.string,
            let number = Double(string)
            else {
                parser.error(message: "Number with no previous.")
                return
        }
        let value = Value.valNumber(number)
        emit(constant: value)
    }
    
    func string(_ canAssign: Bool) {
        guard let text = parser.previous?.text else {
            assert(false, "Tried to make a string out of a bad token")
        }
        // token text includes the " on both sides
        let unquoted = text.dropFirst().dropLast()
        emit(constant: .valObj(vm.copyString(text: unquoted).withMemoryRebound(to: Obj.self, capacity: 1, { (ptr) -> UnsafeMutablePointer<Obj> in
            return ptr
        })))
    }
    
    func namedVariable(name: Token, canAssign: Bool) {
        let arg = identifierConstant(name: name)
        
        if canAssign && parser.match(type: .tokenEqual) {
            expression()
            emit(opCode: .SetGlobal, byte: arg)
        } else {
            emit(opCode: .GetGlobal, byte: arg)
        }
    }
    
    func variable(_ canAssign: Bool) {
        guard let previous = parser.previous else {
            preconditionFailure("Variable with no previous.")
        }
        namedVariable(name: previous, canAssign: canAssign)
    }
    
    func unary(_ canAssign: Bool) {
        guard let operatorType = parser.previous?.type
            else {
                parser.error(message: "Unary with no previous.")
                return
        }
        // Compile the operand
        parsePrecedence(.Unary)
        
        // emit the operator instruction
        switch operatorType {
        case .tokenBang:
            emit(opCode: .Not)
        case .tokenMinus:
            emit(opCode: .Negate)
        default:
            assert(false); // Unreachable.
        }
    }
    
    func parsePrecedence(_ precedence: Precedence) {
        parser.advance()
        guard let operatorType = parser.previous?.type
            else {
                parser.error(message: "parsePrecedence with no previous.")
                return
        }
        guard let prefixRule = Compiler.getRule(type: operatorType).prefix
            else {
                parser.error(message: "Expect expression.")
                return
        }
        
        let canAssign = precedence <= .Assignment
        prefixRule(self)(canAssign)
        
        while let operatorType = parser.current?.type,
        precedence <= Compiler.getRule(type: operatorType).precedence {
            parser.advance()
            guard let infixRule = Compiler.getRule(type: operatorType).infix
                else {
                    parser.error(message: "Expect expression.")
                    return
            }
            
            infixRule(self)(canAssign)
        }
        
        if (canAssign && parser.match(type: .tokenEqual)) {
            parser.error(message: "Invalid assignment target.")
        }
    }
    
    func identifierConstant(name: Token) -> UInt8 {
        return makeConstant(value: Value.from(objStringPtr: vm.copyString(text: name.text)))
    }
    
    func identifiersEqual(_ a: Token, _ b: Token) -> Bool {
        return a.text == b.text
    }
    
    func addLocal(name: Token) {
        guard current.localCount < UINT8_COUNT else {
            parser.error(message: "Too many local variables in function.")
            return
        }
        
        let local = Local(name: name, depth: current.scopeDepth)
        if current.localCount == current.locals.count {
            current.locals.append(local)
        } else {
            // reuse existing slot
            current.locals[current.localCount] = local
        }
        current.localCount += 1
    }
    
    func declareVariable() {
        // Global variables are implicitly declared
        if (current.scopeDepth == 0) { return }
        
        guard let name = parser.previous else {
            preconditionFailure("Missing variable name.")
        }
        var i = current.localCount - 1
        while i >= 0 {
            let local = current.locals[i]
            if local.depth != -1 && local.depth < current.scopeDepth {
                break
            }
            
            if (identifiersEqual(name, local.name)) {
                parser.error(message: "Variable with this name already declared in this scope.")
            }
            i -= 1
        }
        addLocal(name: name)
    }
    
    func parseVariable(errorMessage: String) -> UInt8 {
        parser.consume(type: .tokenIdentifier, message: errorMessage)
        
        declareVariable()
        if (current.scopeDepth > 0) { return 0 }
        
        guard let name = parser.previous else {
            preconditionFailure("Consumed an identifier, but it's gone.")
        }
        return identifierConstant(name: name)
    }
    
    func defineVariable(global: UInt8) {
        if (current.scopeDepth > 0) { return }
        
        emit(opCode: .DefineGlobal, byte: global)
    }
    
    func varDeclaration() {
        let global = parseVariable(errorMessage: "Expect variable name.")
        
        if parser.match(type: .tokenEqual) {
            expression()
        } else {
            emit(opCode: .Nil)
        }
        parser.consume(type: .tokenSemicolon, message: "Expect ';' after variable declaration.")
        
        defineVariable(global: global)
    }
    
    func expression() {
        parsePrecedence(.Assignment)
    }
    
    func declaration() {
        if parser.match(type: .tokenVar) {
            varDeclaration();
        } else {
            statement()
        }
        
        if parser.panicMode { synchronize() }
    }
    
    func block() {
        while !parser.check(type: .tokenRightBrace) && !parser.check(type: .tokenEOF) {
            declaration()
        }
        
        parser.consume(type: .tokenRightBrace, message: "Expect '}' after block.")
    }
    
    func statement() {
        if parser.match(type: .tokenPrint) {
            printStatement()
        } else if (parser.match(type: .tokenLeftBrace)) {
            beginScope()
            block()
            endScope()
        } else {
            expressionStatement()
        }
    }
    
    func printStatement() {
        expression()
        parser.consume(type: .tokenSemicolon, message: "Expect ';' after value.")
        emit(opCode: .Print)
    }
    
    func expressionStatement() {
        expression()
        parser.consume(type: .tokenSemicolon, message: "Expect ';' after expression.")
        emit(opCode: .Pop)
    }
    
    func synchronize() {
        parser.panicMode = false
        
        while parser.current?.type != .tokenEOF {
            if parser.previous?.type == .tokenSemicolon {
                return
            }
            
            switch parser.current?.type {
            case .tokenClass, .tokenFun, .tokenVar, .tokenFor,
                 .tokenIf, .tokenWhile, .tokenPrint, .tokenReturn:
                return
            default:
                break
            }
            
            parser.advance()
        }
    }
    
    
    static let rules: [ParseRule] = [
        ParseRule( grouping, nil,    .None ),       // TOKEN_LEFT_PAREN
        ParseRule( nil,      nil,    .None ),       // TOKEN_RIGHT_PAREN
        ParseRule( nil,      nil,    .None ),       // TOKEN_LEFT_BRACE
        ParseRule( nil,      nil,    .None ),       // TOKEN_RIGHT_BRACE
        ParseRule( nil,      nil,    .None ),       // TOKEN_COMMA
        ParseRule( nil,      nil,    .None ),       // TOKEN_DOT
        ParseRule( unary,    binary, .Term ),       // TOKEN_MINUS
        ParseRule( nil,      binary, .Term ),       // TOKEN_PLUS
        ParseRule( nil,      nil,    .None ),       // TOKEN_SEMICOLON
        ParseRule( nil,      binary, .Factor ),     // TOKEN_SLASH
        ParseRule( nil,      binary, .Factor ),     // TOKEN_STAR
        ParseRule( unary,    nil,    .None ),       // TOKEN_BANG
        ParseRule( nil,      binary, .Equality ),   // TOKEN_BANG_EQUAL
        ParseRule( nil,      nil,    .None ),       // TOKEN_EQUAL
        ParseRule( nil,      binary, .Equality ),   // TOKEN_EQUAL_EQUAL
        ParseRule( nil,      binary, .Comparison ), // TOKEN_GREATER
        ParseRule( nil,      binary, .Comparison ), // TOKEN_GREATER_EQUAL
        ParseRule( nil,      binary, .Comparison ), // TOKEN_LESS
        ParseRule( nil,      binary, .Comparison ), // TOKEN_LESS_EQUAL
        ParseRule( variable, nil,    .None ),       // TOKEN_IDENTIFIER
        ParseRule( string,   nil,    .None ),       // TOKEN_STRING
        ParseRule( number,   nil,    .None ),       // TOKEN_NUMBER
        ParseRule( nil,      nil,    .None ),       // TOKEN_AND
        ParseRule( nil,      nil,    .None ),       // TOKEN_CLASS
        ParseRule( nil,      nil,    .None ),       // TOKEN_ELSE
        ParseRule( literal,  nil,    .None ),       // TOKEN_FALSE
        ParseRule( nil,      nil,    .None ),       // TOKEN_FOR
        ParseRule( nil,      nil,    .None ),       // TOKEN_FUN
        ParseRule( nil,      nil,    .None ),       // TOKEN_IF
        ParseRule( literal,  nil,    .None ),       // TOKEN_NIL
        ParseRule( nil,      nil,    .None ),       // TOKEN_OR
        ParseRule( nil,      nil,    .None ),       // TOKEN_PRINT
        ParseRule( nil,      nil,    .None ),       // TOKEN_RETURN
        ParseRule( nil,      nil,    .None ),       // TOKEN_SUPER
        ParseRule( nil,      nil,    .None ),       // TOKEN_THIS
        ParseRule( literal,  nil,    .None ),       // TOKEN_TRUE
        ParseRule( nil,      nil,    .None ),       // TOKEN_VAR
        ParseRule( nil,      nil,    .None ),       // TOKEN_WHILE
        ParseRule( nil,      nil,    .None ),       // TOKEN_ERROR
        ParseRule( nil,      nil,    .None ),       // TOKEN_EOF
    ]
    
    static func getRule(type: TokenType) -> ParseRule {
        return rules[type.rawValue]
    }
}
