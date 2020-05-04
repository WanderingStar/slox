//
//  runLengthEncoded.swift
//  slox
//
//  Created by Aneel Nazareth on 5/4/20.
//  Copyright © 2020 Aneel Nazareth. All rights reserved.
//

import Foundation

struct runLengthEncoded<T: Equatable> {
    var items: [(Int, T)] = []
    
    mutating func add(_ item: T, at: Int) {
        if let (_, prev) = items.last {
            if prev != item {
                items.append((at, item))
            }
        } else {
            items.append((0, item))
        }
    }
    
    func lookup(_ at: Int) -> T? {
        var prev: T? = nil
        for (n, item) in items {
            if n > at {
                return prev
            }
            prev = item
        }
        return prev
    }
    
    func isStartOfRun(_ at: Int) -> Bool {
        for (n, _) in items {
            if n == at {
                return true
            }
            if n > at {
                return false
            }
        }
        return false
    }
}
