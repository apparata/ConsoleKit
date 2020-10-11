
import Foundation
import ConsoleKit

let readEvaluatePrintLoop = try ReadEvaluatePrintLoop()

readEvaluatePrintLoop.textCompletion = SimpleWordCompletion(completions: [
    "banana",
    "discombobulated",
    "water",
    "whatever"
])

do {
    try readEvaluatePrintLoop.run { input in
        guard !["quit", "exit"].contains(input) else {
            return .break
        }
        
        Console.write(terminalString: "You entered: \(input)\n")
        return .continue
    }
} catch {
    #if DEBUG
    dump(error)
    #endif
}
