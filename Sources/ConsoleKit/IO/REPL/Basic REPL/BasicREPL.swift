//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation

public final class BasicREPL: REPLImplementation {
    
    var prompt: TerminalString
    
    /// Text completion is not supported by `BasicREPL`
    var textCompletion: TextCompletion?
    
    private var evaluationCondition = NSCondition()
    private var result: ReadEvaluatePrintLoopResult?
    
    /// Command history and text completion are not supported by `BasicREPL`
    init(prompt: TerminalString,
         maxHistoryLineCount: Int = 0,
         textCompletion: TextCompletion? = nil) {
        self.prompt = prompt
    }
    
    func run(evaluateAndPrint: @escaping ReadEvaluatePrintLoop.Evaluator) throws {
        
        while true {
            
            result = nil
            
            Console.write(prompt.asPlainString)
            guard let line = Console.readLine() else {
                break
            }
            
            DispatchQueue.global(qos: .userInteractive).async {
                evaluateAndPrint(line, { [weak self] result in
                    self?.evaluationCondition.lock()
                    self?.result = result
                    self?.evaluationCondition.signal()
                    self?.evaluationCondition.unlock()
                })
            }
            
            evaluationCondition.lock()
            while result == nil {
                evaluationCondition.wait()
            }
            evaluationCondition.unlock()
            guard case .continue = result else {
                break
            }
        }
        
        Console.write("\n")
        Console.flush()
        
        if case .error(let error) = result {
            throw error
        }
    }
    
    func cleanUp() {
        //
    }
}

