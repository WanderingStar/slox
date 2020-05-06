//
//  main.swift
//  slox
//
//  Created by Aneel Nazareth on 5/3/20.
//  Copyright © 2020 Aneel Nazareth. All rights reserved.
//

import Foundation

final class StandardErrorOutputStream: TextOutputStream {
    func write(_ string: String) {
        FileHandle.standardError.write(Data(string.utf8))
    }
}
var stderr = StandardErrorOutputStream()

func repl(vm: VM) {
    while (true) {
        print("> ", terminator:"")
        guard let line = readLine(strippingNewline: true) else {
            print()
            break
        }
        var scanner = Scanner(source: line)
        while (!scanner.isAtEnd) {
            let token = scanner.scanToken()
            print(token)
        }
        if line == "" {
            break
        }
        _ = vm.interpret(source: line)
    }
}

func readFile(_ file: String) -> String? {
    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        let fileURL = dir.appendingPathComponent(file)
        do {
            return try String(contentsOf: fileURL, encoding: .utf8)
        }
        catch {/* error handling here */}
    }
    return nil
}

func runFile(vm: VM, file: String) {
    guard let source = readFile(file) else {
        print("Could not read file \"\(file)\"")
        exit(74)
    }
    switch vm.interpret(source: source) {
    case .CompileError:
        exit(65)
    case .RuntimeError:
        exit(70)
    default:
        exit(0)
    }
}

func main() {
    let vm = VM()
    
    let arguments = CommandLine.arguments
    if arguments.count == 1 {
        repl(vm: vm)
    } else if arguments.count == 2 {
        runFile(vm: vm, file: arguments[1])
    } else {
        print("Usage: slox [path]", to: &stderr)
        exit(64)
    }
    
    vm.free()
}
main()
