//
//  table.swift
//  slox
//
//  Created by Aneel Nazareth on 5/13/20.
//  Copyright © 2020 Aneel Nazareth. All rights reserved.
//

import Foundation

let tableMaxLoad = 0.75

struct Entry {
    var key: UnsafeMutablePointer<ObjString>?
    var value: Value
}

struct Table {
    var count: Int = 0
    var capacity: Int = 0
    var entries: UnsafeMutablePointer<Entry>? = nil
}

func hashString(chars: UnsafeMutablePointer<CChar>, length: Int) -> UInt32 {
    var hash: UInt32 = 2166136261
    
    let buffer = UnsafeBufferPointer<CChar>(start: chars, count: length)
    for char in buffer {
        hash ^= UInt32(char)
        hash = hash &* 16777619
    }
    
    return hash
}

extension VM {
    
    // returns nil if value is absent, .valNil if value is present and .valNil
    func tableGet(table: Table, key: UnsafeMutablePointer<ObjString>) -> Value? {
        guard let entries = table.entries else { return nil }
        let entry = findEntry(entries: entries, capacity: table.capacity, key: key)
        if entry.pointee.key == nil { return nil }
        return entry.pointee.value
    }

    func tableSet(table: inout Table, key: UnsafeMutablePointer<ObjString>, value: Value) -> Bool {
        if (Double(table.count) + 1 > Double(table.capacity) * tableMaxLoad) {
            let capacity = growCapacity(table.capacity)
            adjustCapacity(table: &table, capacity: capacity)
        }
        
        guard let entries = table.entries else {
            preconditionFailure("Didn't allocate table")
        }
        let entry = findEntry(entries: entries, capacity: table.capacity, key: key)
        
        let isNewKey = entry.pointee.key == nil
        if isNewKey, case .valNil = entry.pointee.value {
            table.count += 1
        }
        
        entry.pointee.key = key
        entry.pointee.value = value
        return isNewKey
    }
    
    // returns the deleted value, nil if no value was deleted
    func tableDelete(table: inout Table, key: UnsafeMutablePointer<ObjString>) -> Value? {
        guard let entries = table.entries else { return nil }
        let entry = findEntry(entries: entries, capacity: table.capacity, key: key)
        if entry.pointee.key == nil { return nil }
        
        // Place a tombstone in the entry
        entry.pointee.key = nil
        let value = entry.pointee.value
        entry.pointee.value = .valBool(true)
        return value
    }
    
    func tableAddAll(from: inout Table, to: inout Table) {
        let entries = UnsafeBufferPointer<Entry>(start: from.entries, count: from.capacity)
        for entry in entries {
            if let key = entry.key {
                _ = tableSet(table: &to, key: key, value: entry.value)
            }
        }
    }
    
    func tableFindString(table: inout Table, chars: UnsafeMutablePointer<CChar>, length: Int, hash: UInt32) -> UnsafeMutablePointer<ObjString>? {
        guard let entries = table.entries else { return nil }
        var index = hash % UInt32(table.capacity)
        while true {
            let entry = entries[Int(index)]
            if let key = entry.key {
                if key.pointee.length == length &&
                    key.pointee.hash == hash &&
                    memcmp(key.pointee.chars, chars, length) == 0 {
                    // We found it.
                    return key
                }
            } else {
                // Stop if we find an empty non-tombstone entry.
                if case .valNil = entry.value { return nil }
            }
            index = (index + 1) % UInt32(table.capacity)
        }
    }
    
    func findEntry(entries: UnsafeMutablePointer<Entry>, capacity: Int, key: UnsafeMutablePointer<ObjString>) -> UnsafeMutablePointer<Entry> {
        var index = key.pointee.hash % UInt32(capacity)
        var tombstone: UnsafeMutablePointer<Entry>?
        while true {
            let entry = entries + Int(index)
            if entry.pointee.key == nil {
                if case .valNil = entry.pointee.value {
                    // Empty entry. If we already found a tombstone, return that instead
                    return tombstone ?? entry
                } else {
                    // We found a tombstone
                    tombstone = tombstone ?? entry
                }
            } else if entry.pointee.key == key {
                return entry
            }
            index = (index + 1) % UInt32(capacity)
        }
    }
    
    func adjustCapacity(table: inout Table, capacity: Int) {
        guard let entries: UnsafeMutablePointer<Entry> = reallocate(pointer: nil, oldCapacity: 0, newCapacity: capacity) else {
            preconditionFailure("Failed to allocate table entries")
        }
        entries.initialize(repeating: Entry(key: nil, value: .valNil(())), count: capacity)
        
        let oldEntries = UnsafeBufferPointer<Entry>(start: table.entries, count: table.capacity)
        table.count = 0
        for entry in oldEntries {
            guard let key = entry.key else { continue }
            
            let dest = findEntry(entries: entries, capacity: capacity, key: key)
            dest.pointee.key = key
            dest.pointee.value = entry.value
            table.count += 1
        }
        
        _ = reallocate(pointer: table.entries, oldCapacity: table.capacity, newCapacity: 0)
        table.entries = entries
        table.capacity = capacity
    }
    
    func tableEntries(table: Table) -> [(String, Value)] {
        let entries = UnsafeBufferPointer<Entry>(start: table.entries, count: table.capacity)
        var nonempty: [(String, Value)] = []
        for entry in entries {
            if let key = entry.key {
                nonempty.append((String(objString: key.pointee), entry.value))
            }
        }
        return nonempty
    }
    
}
