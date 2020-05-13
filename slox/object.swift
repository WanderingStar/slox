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
}
