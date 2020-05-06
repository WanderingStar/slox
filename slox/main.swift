//
//  main.swift
//  slox
//
//  Created by Aneel Nazareth on 5/3/20.
//  Copyright © 2020 Aneel Nazareth. All rights reserved.
//

import Foundation



var chunk = Chunk()

chunk.write(op: .Constant, line: 123)
chunk.write(byte: Int8(chunk.addConstant(value: 1.2)), line: 123)

chunk.write(op: .Constant, line: 123)
chunk.write(byte: Int8(chunk.addConstant(value: 3.4)), line: 123)

chunk.write(op: .Add, line: 123)

chunk.write(op: .Constant, line: 123)
chunk.write(byte: Int8(chunk.addConstant(value: 5.6)), line: 123)

chunk.write(op: .Divide, line: 123);
chunk.write(op: .Negate, line: 123);

chunk.write(op: .Return, line: 123)

disassembleChunk(chunk, name: "test chunk")
let vm = VM()
_ = vm.interpret(chunk: chunk)
vm.free()
chunk.free()

