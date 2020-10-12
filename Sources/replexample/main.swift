
import Foundation
import ConsoleKit

let readEvaluatePrintLoop = try ReadEvaluatePrintLoop()

readEvaluatePrintLoop.textCompletion = SimpleWordCompletion(completions: [
    "banana",
    "discombobulated",
    "water",
    "whatever"
])

readEvaluatePrintLoop.run { input, finish in
    guard !["quit", "exit"].contains(input) else {
        finish(.break)
        return
    }
    
    Console.write(terminalString: "You entered: \(input)\n")
    finish(.continue)
}
