//
//  object.swift
//  slox
//
//  Created by Aneel Nazareth on 5/10/20.
//  Copyright © 2020 Aneel Nazareth. All rights reserved.
//

import Foundation

func copyString(text: Substring) -> UnsafeMutablePointer<ObjString> {
    let count = text.utf8.count
    let chars = text.withCString { (textPtr) -> UnsafeMutablePointer<CChar> in
        let outPtr = UnsafeMutablePointer<CChar>.allocate(capacity: count + 1)
        outPtr.initialize(from: textPtr, count: count)
        outPtr[count] = CChar(0)
        return outPtr
    }
    
    return allocateString(chars: chars, length: count)
}

func allocateString(chars: UnsafeMutablePointer<CChar>, length: Int) -> UnsafeMutablePointer<ObjString> {
    let ptr = UnsafeMutablePointer<ObjString>.allocate(capacity: 1)
    ptr.withMemoryRebound(to: Obj.self, capacity: 1) { (objPtr) -> () in
        objPtr.pointee.type = .String
    }
    ptr.pointee.length = length
    ptr.pointee.chars = chars
    
    return ptr
}
