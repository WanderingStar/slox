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
}

struct Obj {
    var type: ObjType
    var next: UnsafeMutablePointer<Obj>? = nil
}

struct ObjString {
    var obj: Obj
    var length: Int
    var chars: UnsafeMutablePointer<CChar>
    var hash: UInt32
}

// not making this a function on the Obj struct because that adds to
// the in-memory representation
extension String {
    init(objString: ObjString) {
        self.init(String(bytesNoCopy: objString.chars, length: objString.length, encoding: .ascii, freeWhenDone: false) ?? "<bad ObjString>")
    }
}

