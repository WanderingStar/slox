//
//  object.swift
//  slox
//
//  Created by Aneel Nazareth on 5/10/20.
//  Copyright © 2020 Aneel Nazareth. All rights reserved.
//

import Foundation

enum ObjType: Int8 {
    case String
    
    var structType: Any {
        switch self {
        case .String:
            return ObjString.self
        }
    }
}

struct Obj {
    var type: ObjType
    var next: UnsafeMutablePointer<Obj>? = nil
}

struct ObjString {
    var obj: Obj
    var length: Int
    var chars: UnsafeMutablePointer<CChar>
}

extension ObjString : CustomStringConvertible {
    var description: String {
        return String(bytesNoCopy: chars, length: length, encoding: .ascii, freeWhenDone: false) ?? "<bad ObjString>"
    }
}
