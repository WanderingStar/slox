//
//  compiler.swift
//  slox
//
//  Created by Aneel Nazareth on 5/5/20.
//  Copyright © 2020 Aneel Nazareth. All rights reserved.
//

import Foundation

func compile(source: String) -> Chunk? {
    var scanner = Scanner(source: source)
    var line = -1
    while (true) {
        let token = scanner.scanToken()
        if (token.line != line) {
            print(String.init(format:"%4d", token.line), terminator: "")
            line = token.line
        } else {
            print("   | ", terminator: "")
        }
        
        print(String.init(format:"%2d '\(token.string)'", token.type.rawValue))
        
        if token.type == .tokenEOF {
            break
        }
    }
    
    return nil
}
