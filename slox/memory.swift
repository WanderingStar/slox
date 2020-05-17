//
//  memory.swift
//  slox
//
//  Created by Aneel Nazareth on 5/12/20.
//  Copyright © 2020 Aneel Nazareth. All rights reserved.
//

import Foundation

extension VM {
    
    func reallocate<T>(pointer: UnsafeMutablePointer<T>?, oldCapacity: Int, newCapacity: Int) -> UnsafeMutablePointer<T>? {
        defer {
            // this always destroys the old pointer
            if let pointer = pointer {
                pointer.deinitialize(count: oldCapacity)
                pointer.deallocate()
            }
        }
        if (newCapacity == 0) {
            return nil
        }
        
        let newPointer = UnsafeMutablePointer<T>.allocate(capacity: newCapacity)
        guard let pointer = pointer, oldCapacity > 0 else {
            return newPointer
        }
        newPointer.moveInitialize(from: pointer, count: min(oldCapacity, newCapacity))
        return newPointer
    }
    
    func allocateObj<T>(objType: ObjType) -> UnsafeMutablePointer<T> {
        guard let ptr: UnsafeMutablePointer<T> = reallocate(pointer: nil, oldCapacity: 0, newCapacity: 1)
            else {
                preconditionFailure("Failed to allocateObj")
        }
        ptr.withMemoryRebound(to: Obj.self, capacity: 1) { (objPtr) -> () in
            objPtr.pointee = Obj(type: objType, next: self.objects)
            self.objects = objPtr
        }
        return ptr
    }

    func allocateString(chars: UnsafeMutablePointer<CChar>, length: Int, hash: UInt32) -> UnsafeMutablePointer<ObjString> {
        let ptr: UnsafeMutablePointer<ObjString> = allocateObj(objType: .String)
        ptr.withMemoryRebound(to: Obj.self, capacity: 1) { (objPtr) -> () in
            objPtr.pointee.type = .String
        }
        ptr.pointee.length = length
        ptr.pointee.chars = chars
        ptr.pointee.hash = hash
        
        _ = tableSet(table: &strings, key: ptr, value: .valNil(()))
        
        return ptr
    }

    // Create a string out of characters that we can "own"
    func takeString(chars: UnsafeMutablePointer<CChar>, length: Int) -> UnsafeMutablePointer<ObjString> {
        let hash = hashString(chars: chars, length: length)
        if let interned = tableFindString(table: &strings, chars: chars, length: length, hash: hash) {
            _ = reallocate(pointer: chars, oldCapacity: length + 1, newCapacity: 0)
            return interned
        }
        return allocateString(chars: chars, length: length, hash: hash)
    }
    
    // Create a string out of characters that we must copy
    func copyString(text: Substring) -> UnsafeMutablePointer<ObjString> {
        let length = text.utf8.count
        let chars = text.withCString { (textPtr) -> UnsafeMutablePointer<CChar> in
            guard let outPtr: UnsafeMutablePointer<CChar> = reallocate(pointer: nil, oldCapacity: 0, newCapacity: length + 1)
                else {
                    preconditionFailure("Failed to allocate CChars")
            }
            outPtr.initialize(from: textPtr, count: length)
            outPtr[length] = CChar(0)
            return outPtr
        }
        let hash = hashString(chars: chars, length: length)
        if let interned = tableFindString(table: &strings, chars: chars, length: length, hash: hash) {
            return interned
        }
        return allocateString(chars: chars, length: length, hash: hash)
    }
    
    func concatenate(a: Value, b: Value) {
        guard let a = a.asObjString, let b = b.asObjString
            else {
                preconditionFailure("Can only concatenate string objects")
        }

        let length = a.length + b.length
        guard let charPtr: UnsafeMutablePointer<CChar> = reallocate(pointer: nil, oldCapacity: 0, newCapacity: length + 1)
        else {
                preconditionFailure("Failed to allocate CChars")
        }
        memcpy(charPtr, a.chars, a.length)
        memcpy(charPtr + a.length, b.chars, b.length)
        charPtr[length] = CChar(0)
        let result = takeString(chars: charPtr, length: length)
        result.withMemoryRebound(to: Obj.self, capacity: 1) {
            (ptr: UnsafeMutablePointer<Obj>) -> () in
            push(.valObj(ptr))
        }
    }
    
    func freeObjects() {
        var object = self.objects
        while object != nil {
            let next = object!.pointee.next
            freeObject(object!)
            object = next
        }
    }
    
    func freeObject(_ object: UnsafeMutablePointer<Obj>) {
        switch object.pointee.type {
        case .String:
            object.withMemoryRebound(to: ObjString.self, capacity: 1) {
                (string: UnsafeMutablePointer<ObjString>) -> () in
                _ = reallocate(pointer: string.pointee.chars, oldCapacity: string.pointee.length + 1, newCapacity: 0)
            }
        }
        _ = reallocate(pointer: object, oldCapacity: 1, newCapacity: 0)
    }
    
    func freeTable(_ table: inout Table) {
        table.entries = reallocate(pointer: table.entries, oldCapacity: table.capacity, newCapacity: 0)
        table.count = 0
        table.capacity = 0
    }
}
