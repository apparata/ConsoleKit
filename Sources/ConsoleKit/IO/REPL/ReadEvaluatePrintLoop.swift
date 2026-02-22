//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation

public enum ReadEvaluatePrintLoopError: Error {
    case unsupportedTerminal
    case endOfInput
    case interrupted
}

public enum ReadEvaluatePrintLoopResult: Sendable {
    case `continue`
    case `break`
    case error(Error)
}

internal protocol REPLImplementation: Sendable {

    var prompt: TerminalString { get set }

    var textCompletion: TextCompletion? { get set }

    init(prompt: TerminalString,
         maxHistoryLineCount: Int,
         textCompletion: TextCompletion?)

    func run(evaluateAndPrint: @escaping ReadEvaluatePrintLoop.Evaluator) throws

    func cleanUp()
}


public final class ReadEvaluatePrintLoop {
    
    public typealias Finish = @Sendable (ReadEvaluatePrintLoopResult) -> Void

    public typealias Evaluator = @Sendable (String, @escaping Finish) -> Void
    
    public var prompt: TerminalString {
        didSet {
            repl.prompt = prompt
        }
    }
    
    public var textCompletion: TextCompletion? {
        didSet {
            repl.textCompletion = textCompletion
        }
    }

    private var repl: REPLImplementation
    
    public init(prompt: TerminalString = ">>> ",
                maxHistoryLineCount: Int = 1000,
                textCompletion: TextCompletion? = nil) throws {
        self.prompt = prompt
        switch Terminal.type(output: Console.standard.out) {
        case .terminal(_):
            repl = TerminalREPL(prompt: prompt, maxHistoryLineCount: maxHistoryLineCount)
        case .dumb:
            repl = BasicREPL(prompt: prompt)
        default:
            if ExecutionMode.isDebuggerAttached {
                // We are probably running in Xcode.
                repl = BasicREPL(prompt: prompt)
            } else {
                throw ReadEvaluatePrintLoopError.unsupportedTerminal
            }
        }        
    }

    public func run(evaluateAndPrint: @escaping Evaluator) {
        
        let replThread = Thread { [repl] in
            do {
                try repl.run(evaluateAndPrint: evaluateAndPrint)
                DispatchQueue.main.async {
                    REPLExecution.stop()
                    raise(SIGINT)
                }
            } catch let replError as ReadEvaluatePrintLoopError {
                switch replError {
                case .unsupportedTerminal:
                    print("Error: Unsupported terminal")
                    REPLExecution.stop()
                case .endOfInput:
                    repl.cleanUp()
                    REPLExecution.stop()
                case .interrupted:
                    repl.cleanUp()
                    exit(0)
                }
            } catch {
                
            }
        }
        replThread.qualityOfService = .userInteractive
        replThread.start()
        
        REPLExecution.run { [repl] _ in
            repl.cleanUp()
            return true
        }
                
        repl.cleanUp()
    }
}
