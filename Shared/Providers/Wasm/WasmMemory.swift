//
//  WasmMemory.swift
//  Aidoku
//
//  Created by Skitty on 1/8/22.
//

import Foundation
import WasmInterpreter
import CWasm3

struct WasmAllocation {
    var address: Int32
    var size: Int32
}

class WasmMemory {
    let vm: WasmInterpreter
    
    let base: Int32
    var allocations = [WasmAllocation]()
    
//    var mallocCount = 0
//    var freeCount = 0
    
    init(vm: WasmInterpreter) {
        self.vm = vm
        self.base = (try? self.vm.call("get_heap_base")) ?? Int32(66992)
    }
    
    var malloc: (Int32) -> Int32 {
        { size in
//            self.mallocCount += 1
            var location: Int32 = self.base
            var i = 0
            for allocation in self.allocations {
                let available = allocation.address - location
                if available > size {
                    self.allocations.insert(WasmAllocation(address: location, size: size), at: i)
                    return location
                } else {
                    location = allocation.address + allocation.size + 1
                }
                i += 1
            }
            // requires some tweaking of the wasm library -- TODO: write my own wasm3 wrapper
            let pageCount = self.vm.runtime.pointee.memory.numPages
            if location + size >= pageCount * 64 * 1024 {
                ResizeMemory(self.vm.runtime, pageCount + 1)
            }
            self.allocations.append(WasmAllocation(address: location, size: size))
            return location
        }
    }
    
    var free: (Int32) -> Void {
        { addr in
//            self.freeCount += 1
            if let index = self.allocations.firstIndex(where: { $0.address == addr }) {
                self.allocations.remove(at: index)
//                if self.freeCount % 10 == 0 || self.allocations.count == 0 {
//                    print("-> \(self.mallocCount) \(self.freeCount) \(self.allocations.count)")
//                }
            } else {
                print("ADDRESS TO FREE NOT FOUND (\(addr))")
            }
        }
    }
}