//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation

public final class TerminalREPL: REPLImplementation {
    
    public typealias Evaluator = ReadEvaluatePrintLoop.Evaluator
        
    private enum EscapeSequence {
        case up
        case down
        case left
        case right
        case delete
    }
    
    var isLogEnabled = false
        
    public var prompt: TerminalString
    
    public var textCompletion: TextCompletion?
        
    private var putBackBuffer: String = ""
    
    private var history: CommandLineHistory
    
    private var evaluationCondition = NSCondition()
    private var result: ReadEvaluatePrintLoopResult?
        
    // MARK: - Init
    
    public init(prompt: TerminalString = ">>> ",
                maxHistoryLineCount: Int = 1000,
                textCompletion: TextCompletion? = nil) {
        self.prompt = prompt
        self.textCompletion = textCompletion
        history = CommandLineHistory(maxLineCount: 1000)
    }
    
    // MARK: - Run
    
    public func run(evaluateAndPrint: @escaping Evaluator) throws {
        do {
            try internalRun(evaluateAndPrint: evaluateAndPrint)
        } catch {
            cleanUp()
            throw error
        }
        cleanUp()
    }
        
    private func internalRun(evaluateAndPrint: @escaping Evaluator) throws {
        
        if isLogEnabled {
            Console.printError("\n\n-----------------------")
        }
                
        try TerminalInputMode.setRawMode()
        
        Console.clearLine()
        
        var state = TerminalREPLState()
                
        if isLogEnabled {
            Console.printError("startRow:\(state.startRow) startColumn:\(state.startColumn)")
        }
        
        var historyIndex: Int = 0
        history.addEntry("")
                
        Console.write(terminalString: prompt)
        
        while true {
            
            if isLogEnabled {
                Console.printError("")
            }
            
            result = nil
            
            state.prompt = prompt
            
            let (height, width) = Terminal.windowSize
            let (currentRow, currentColumn) = Console.cursorPosition()
                        
            if isLogEnabled {
                Console.printError("curRow:\(currentRow) curCol:\(currentColumn) width:\(width) height:\(height)")

                Console.printError("state.row:\(state.row) state.col:\(state.column) state.exp:\(state.expandedToRows)")
            }
                        
            let character = try readNextCharacter()

            if character.isCtrlD {
                // End of input
                throw ReadEvaluatePrintLoopError.endOfInput
            }
            
            else if character.isCtrlC {
                // Interrupt
                throw ReadEvaluatePrintLoopError.interrupted
            }
                
            else if character.isCtrlA {
                state.moveToStart()
            }

            else if character.isCtrlE {
                state.moveToEnd()
            }
                
            else if character.isCtrlK {
                // Delete to end of line
                state.input.removeSubrange(state.stringIndex(offset: 0)...)
            }

            else if character.isCtrlU {
                // Delete to beginning of line
                state.input.removeSubrange(..<state.stringIndex(offset: 0))
                state.row = state.startRow
                state.column = state.startColumn
            }
                
            else if character.isCtrlL {
                Console.clear()
                Console.write(.setPosition(row: 1, column: 1))
                state = TerminalREPLState()
            }
            
            else if character.isPrintable {
                let index = state.input.index(state.input.startIndex, offsetBy: state.index)
                state.input.insert(character, at: index)
                
                let (endRow, endColumn) = state.end

                if isLogEnabled {
                    Console.printError("endRow:\(endRow) endCol:\(endColumn)")
                }
                
                state.column += 1
                if state.column > width {
                    state.row += 1
                    state.column = 1
                    Console.write("\n")
                }
            }
                
            else if character.isBackspace {
                state.moveLeft {
                    $0.input.remove(at: $1)
                }
            }
                
            else if character.isNewline {
                state.moveToEnd()
                let (endRow, endColumn) = state.end
                Console.write(.setPosition(row: endRow, column: endColumn))
                Console.write("\n")
                Console.write(.toLineStart)
                
                if historyIndex == 0 {
                    history.addEntry("")
                } else {
                    history.removeFirstEntry()
                    if state.input.trimmingWhitespace().count > 0 {
                        history.addEntry(state.input)
                    }
                    history.addEntry("")
                }
                historyIndex = 0

                DispatchQueue.global(qos: .userInteractive).async {
                    evaluateAndPrint(state.input, { [weak self] result in
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

                Console.write(.toLineStart)
                state = TerminalREPLState()
            }
                
            else if character == "\t" {
                if let textCompletion = textCompletion {
                    let inputBefore = state.input
                    let indexBefore = state.index
                    let (input, index) = textCompletion.complete(input: inputBefore, index: indexBefore)
                    if inputBefore == input, indexBefore == index {
                        Console.bell()
                    } else {
                        let expandedBefore = state.expandedToRows
                        state.input = input
                        state.index = index
                        let (endRow, endColumn) = state.end
                        Console.write(.setPosition(row: endRow, column: endColumn))
                        let expandedAfter = state.expandedToRows
                        let delta = expandedAfter - expandedBefore
                        if delta > 0 {
                            if isLogEnabled {
                                Console.printError("Delta \(delta)")
                            }
                            Console.write(String.init(repeating: "\n", count: delta))
                        }
                    }
                } else {
                    Console.bell()
                }
            }
                        
            else if let escapeSequence = try readEscapeSequence(character) {
                switch escapeSequence {
                    
                case .up:
                    historyIndex = historyIndex + 1
                    if historyIndex >= history.lineCount {
                        historyIndex = history.lineCount - 1
                        Console.bell()
                    }
                    let expandedBefore = state.expandedToRows
                    state.input = history[historyIndex]
                    state.moveToEnd()
                    let (endRow, endColumn) = state.end
                    Console.write(.setPosition(row: endRow, column: endColumn))
                    let expandedAfter = state.expandedToRows
                    let delta = expandedAfter - expandedBefore
                    if delta > 0 {
                        if isLogEnabled {
                            Console.printError("Delta \(delta)")
                        }
                        Console.write(String.init(repeating: "\n", count: delta))
                    }
                    Console.write(.setPosition(row: endRow, column: endColumn))

                case .down:
                    historyIndex = historyIndex - 1
                    if historyIndex < 0 {
                        historyIndex = 0
                        Console.bell()
                    }
                    let expandedBefore = state.expandedToRows
                    state.input = history[historyIndex]
                    state.moveToEnd()
                    let (endRow, endColumn) = state.end
                    Console.write(.setPosition(row: endRow, column: endColumn))
                    let expandedAfter = state.expandedToRows
                    let delta = expandedAfter - expandedBefore
                    if delta > 0 {
                        Console.write(String.init(repeating: "\n", count: delta))
                    }
                    Console.write(.setPosition(row: endRow, column: endColumn))

                case .left:
                    state.moveLeft()

                case .right:
                    state.moveRight()
                    
                case .delete:
                    let end = state.end
                    if state.row == end.row && state.column == end.column {
                        Console.bell()
                    } else {
                        let index = state.input.index(state.input.startIndex, offsetBy: state.index)
                        state.input.remove(at: index)
                    }
                }
            }
            
            let (endRow, _) = state.end
            if endRow > height {
                let difference = endRow - height
                state.startRow -= difference
                state.row -= difference
            }
            if isLogEnabled {
                Console.printError("startRow: \(state.startRow)")
            }
            
            history.updateEntry(state.input, at: historyIndex)
                        
            updateCommandLine(state: state)
        }
        
        if case .error(let error) = result {
            throw error
        }
    }
    
    // MARK: - Update Command Line
    
    private func updateCommandLine(state: TerminalREPLState) {
        Console.write(.setPosition(row: state.startRow, column: state.startColumn))
        Console.write(.clearScreenFromCursor)
        Console.write(terminalString: state.prompt)
        Console.write(state.input)
        Console.write(.setPosition(row: state.row, column: state.column))
    }
    
    // MARK: - Read Next Character
    
    private func readNextCharacter() throws -> Character {
        guard putBackBuffer.isEmpty else {
            let character = putBackBuffer.removeFirst()
            return character
        }
        guard let string = Console.standard.in.read(), string.count > 0 else {
            throw ReadEvaluatePrintLoopError.endOfInput
        }
        var characters = string
        let character = characters.removeFirst()
        putBackBuffer.append(characters)
        return character
    }
    
    // MARK: - Put Back Character(s)
    
    private func putBackCharacter(_ character: Character) {
        putBackBuffer.insert(character, at: putBackBuffer.startIndex)
    }
    
    private func putBackCharacters(_ characters: Character...) {
        putBackBuffer.insert(contentsOf: characters, at: putBackBuffer.startIndex)
    }
    
    // MARK: - Clean Up
    
    func cleanUp() {
        do {
            try TerminalInputMode.reset()
        } catch {
            if isLogEnabled {
                print("Error: Failed to reset terminal")
            }
        }
        Console.write("\n")
        Console.write(.toLineStart)
        Console.flush()
    }
    
    // MARK: - Read Esc Sequence
    
    private func readEscapeSequence(_ character: Character) throws -> EscapeSequence? {
        guard character.isEscape else {
            return nil
        }

        let character1 = try readNextCharacter()
        if character1 == "[" {
            let character2 = try readNextCharacter()
            switch character2 {
                
            case "A": return .up
            case "B": return .down
            case "D": return .left
            case "C": return .right
            
            case "3":
                let character3 = try readNextCharacter()
                if character3 == "~" {
                    return .delete
                } else {
                    putBackCharacters(character1, character2)
                }
            
            default: putBackCharacters(character1, character2)
            }
        } else {
            putBackCharacter(character1)
        }
        
        return nil
    }
}
