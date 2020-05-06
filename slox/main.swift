//
//  main.swift
//  slox
//
//  Created by Aneel Nazareth on 5/3/20.
//  Copyright © 2020 Aneel Nazareth. All rights reserved.
//

import Foundation



var chunk = Chunk()

let constant = chunk.addConstant(value: 1.2)
chunk.write(op: .Constant, line: 123)
chunk.write(byte: Int8(constant), line: 123)

chunk.write(op: .Return, line: 123)

disassembleChunk(chunk, name: "test chunk")
let vm = VM()
vm.interpret(chunk: chunk)
vm.free()
chunk.free()

