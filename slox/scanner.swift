//
//  scanner.swift
//  slox
//
//  Created by Aneel Nazareth on 5/5/20.
//  Copyright © 2020 Aneel Nazareth. All rights reserved.
//

import Foundation

enum TokenType: Int {
    // Single-character tokens.
    case tokenLeftParen, tokenRightParen,
    tokenLeftBrace, tokenRightBrace,
    tokenComma, tokenDot, tokenMinus, tokenPlus,
    tokenSemicolon, tokenSlash, tokenStar,
    
    // One or two character tokens.
    tokenBang, tokenBangEqual,
    tokenEqual, tokenEqualEqual,
    tokenGreater, tokenGreaterEqual,
    tokenLess, tokenLessEqual,
    
    // Literals.
    tokenIdentifier, tokenString, tokenNumber,
    
    // Keywords.
    tokenAnd, tokenClass, tokenCon, tokenElse, tokenFalse,
    tokenFor, tokenFun, tokenIf, tokenNil, tokenOr,
    tokenPrint, tokenReturn, tokenSuper, tokenThis,
    tokenTrue, tokenVar, tokenWhile,
    
    tokenError,
    tokenEOF
}

struct Token {
    let type: TokenType
    let text: Substring  // to save reallocating strings
    let line: Int
    
    var string: String {
        return String(text)
    }
}

func isDigit(_ c: Character) -> Bool {
    return c >= "0" && c <= "9"
}

func isAlpha(_ c: Character) -> Bool {
    return (c >= "a" && c <= "z") ||
        (c >= "A" && c <= "Z") ||
        c == "_"
}

struct Scanner {
    let source: String
    var start = 0
    var current = 0
    var line = 1
    
    var isAtEnd: Bool {
        return current == source.count
    }
    
    var isNextEnd: Bool {
        return current == source.count - 1
    }
    
    func index(_ offset: Int) -> String.Index {
        return source.index(source.startIndex, offsetBy: offset)
    }
    
    var startIndex: String.Index {
        return index(start)
    }
    
    var currentIndex: String.Index {
        return index(current)
    }
    
    var nextIndex: String.Index {
        return index(current + 1)
    }
    
    func peek() -> Character {
        return source[currentIndex]
    }
    
    func peekNext() -> Character {
        return source[nextIndex]
    }
    
    mutating func advance() -> Character {
        defer { current += 1 }
        return peek()
    }
    
    mutating func match(_ expected: Character) -> Bool {
        if isAtEnd { return false }
        if (source[currentIndex] != expected) { return false }
        
        current += 1
        return true
    }
    
    func token(type: TokenType) -> Token {
        return Token(type: type,
                     text: source[startIndex..<currentIndex],
                     line: line)
    }
    
    func errorToken(message: String) -> Token {
        return Token(type: .tokenError, text: message[..<message.endIndex], line: line)
    }
    
    mutating func skipWhitespace() {
        while !isAtEnd {
            let c = peek()
            switch c {
            case " ", "\r", "\t":
                _ = advance()
            case "\n":
                line += 1
                _ = advance()
            case "/":
                if !isNextEnd && peekNext() == "/" {
                    while !isAtEnd && advance() != "\n" {}
                } else {
                    return
                }
            default:
                return
            }
        }
    }
    
    mutating func string() -> Token {
        while !isAtEnd && peek() != "\"" {
            if peek() == "\n" {
                line += 1
            }
            _ = advance()
        }
        
        if isAtEnd {
            return errorToken(message: "Unterminated string.")
        }
        
        // The closing quote.
        _ = advance()
        return token(type: .tokenString)
    }
    
    mutating func number() -> Token {
        while !isAtEnd && isDigit(peek()) { _ = advance() }
        
        // Look for a fractional part.
        if !isAtEnd && peek() == "." && !isNextEnd && isDigit(peekNext()) {
          // Consume the ".".
          _ = advance()

            while !isAtEnd && isDigit(peek()) { _ = advance() };
        }

        return token(type: .tokenNumber)
    }
    
    func checkKeyword(match: String, type: TokenType) -> TokenType {
        if source[startIndex..<currentIndex] == match {
            return type
        }
        return .tokenIdentifier
    }
    
    func identifierType() -> TokenType {
        // I didn't feel like mucking around with String.Index more,
        // so this is slightly less optimized than the switch-trie
        // in the book. It checks the _whole_ token against the keyword
        // instead of just the part we haven't previously looked at
        switch source[startIndex] {
        case "a": return checkKeyword(match: "and", type: .tokenAnd)
        case "c":
            if current - start > 1 {
                switch source[index(start + 1)] {
                case "o": return checkKeyword(match: "con", type: .tokenCon)
                case "l": return checkKeyword(match: "class", type: .tokenClass)
                default:
                    break
                }
            }
        case "e": return checkKeyword(match: "else", type: .tokenElse)
        case "f":
            if current - start > 1 {
                switch source[index(start + 1)] {
                case "a": return checkKeyword(match: "false", type: .tokenFalse)
                case "o": return checkKeyword(match: "for", type: .tokenFor)
                case "u": return checkKeyword(match: "fun", type: .tokenFun)
                default:
                    break
                }
            }
        case "i": return checkKeyword(match: "if", type: .tokenIf)
        case "n": return checkKeyword(match: "nil", type: .tokenNil)
        case "o": return checkKeyword(match: "or", type: .tokenOr)
        case "p": return checkKeyword(match: "print", type: .tokenPrint)
        case "r": return checkKeyword(match: "return", type: .tokenReturn)
        case "s": return checkKeyword(match: "super", type: .tokenSuper)
        case "t":
            if current - start > 1 {
                switch source[index(start + 1)] {
                case "h": return checkKeyword(match: "this", type: .tokenThis)
                case "r": return checkKeyword(match: "true", type: .tokenTrue)
                default:
                    break
                }
            }
        case "v": return checkKeyword(match: "var", type: .tokenVar)
        case "w": return checkKeyword(match: "while", type: .tokenWhile)
        default:
            break
        }
        
        return .tokenIdentifier
    }
    
    mutating func identifier() -> Token {
        while !isAtEnd && (isAlpha(peek()) || isDigit(peek())) { _ = advance() }

        return token(type: identifierType())
    }
    
    mutating func scanToken() -> Token {
        skipWhitespace()
        start = current
        
        if isAtEnd {
            return Token(type: .tokenEOF, text: "", line: line)
        }
        
        let c = advance()
        if isAlpha(c) { return identifier() }
        if isDigit(c) { return number() }
        
        switch c {
        case "(": return token(type:.tokenLeftParen)
        case ")": return token(type:.tokenRightParen)
        case "{": return token(type:.tokenLeftBrace)
        case "}": return token(type:.tokenRightBrace)
        case ";": return token(type:.tokenSemicolon)
        case ",": return token(type:.tokenComma)
        case "-": return token(type:.tokenMinus)
        case "+": return token(type:.tokenPlus)
        case "/": return token(type:.tokenSlash)
        case "*": return token(type:.tokenStar)
            
        case "!":
            return token(type: match("=") ? .tokenBangEqual : .tokenBang)
        case "=":
            return token(type: match("=") ? .tokenEqualEqual : .tokenEqual)
        case "<":
            return token(type: match("=") ? .tokenLessEqual : .tokenLess)
        case ">":
            return token(type: match("=") ? .tokenGreaterEqual : .tokenGreater)
            
        case "\"":
            return string()
            
        default:
            break
        }
        
        return errorToken(message: "Unexpected character.")
    }
}
