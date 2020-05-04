//
//  main.swift
//  slox
//
//  Created by Aneel Nazareth on 5/3/20.
//  Copyright © 2020 Aneel Nazareth. All rights reserved.
//

import Foundation

var chunk = Chunk()
chunk.write(byte: OpCode.Return.rawValue)
disassembleChunk(chunk, name: "test chunk")
chunk.free()
