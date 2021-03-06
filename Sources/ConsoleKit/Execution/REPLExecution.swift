import Foundation

public final class REPLExecution {
    
    public enum SignalType {
        /// User interrupted program, typically by pressing Ctrl-C.
        case interrupt
        
        /// Terminal disconnected, e.g. user closed terminal window.
        case terminalDisconnected
        
        /// The program is about to be terminated.
        case terminate
    }
    
    /// The signal handler is run when the `SIGINT`, `SIGHUP`, or `SIGTERM`
    /// signal is received by the process. It is used to clean up before
    /// exiting the program, or to attempt to suppress the signal.
    ///
    /// Returns `true` if the program should exit, or `false` to keep running.
    /// The normal case would be to return `true`.
    public typealias SignalHandler = (SignalType) -> Bool
    
    /// Private singleton instance.
    private static let instance = REPLExecution()
    
    private var signalSources: [DispatchSourceSignal] = []
    private let signalQueue = DispatchQueue(label: "Execution.signalhandler")
        
    /// Starts the main run loop and optionally installs a signal handler
    /// for the purpose of cleanup before terminating. The signal handler
    /// will be executed for `SIGINT`, `SIGHUP` and `SIGTERM`.
    ///
    /// - parameter signalHandler: Optional signal handler to execute before
    ///                            the program is terminated. If the signal
    ///                            handler returns `false`, the program will
    ///                            suppress the signal and not exit.
    public static func run(signalHandler: SignalHandler? = nil) {
        if let signalHandler = signalHandler {
            instance.signalSources = instance.installSignalHandler(signalHandler)
        }
        var keepGoing = true
        while keepGoing {
            let result = CFRunLoopRunInMode(.defaultMode, 3600, false)
            switch result {
            case .finished:
                keepGoing = false
            case .stopped:
                keepGoing = false
            default:
                break
            }
        }
    }
    
    /// Installs `SIGINT`, `SIGHUP`, and `SIGTERM` signal handler.
    private func installSignalHandler(_ handler: @escaping SignalHandler) -> [DispatchSourceSignal] {
        
        let sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: signalQueue)
        sigintSource.setEventHandler {
            let shouldExit = handler(.interrupt)
            print()
            if shouldExit {
                exit(0)
            }
        }

        let sighupSource = DispatchSource.makeSignalSource(signal: SIGHUP, queue: signalQueue)
        sigintSource.setEventHandler {
            let shouldExit = handler(.terminalDisconnected)
            print()
            if shouldExit {
                exit(0)
            }
        }
        
        let sigtermSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: signalQueue)
        sigtermSource.setEventHandler {
            let shouldExit = handler(.terminate)
            print()
            if shouldExit {
                exit(0)
            }
        }
                
        // Ignore default handlers.
        signal(SIGINT, SIG_IGN)
        signal(SIGHUP, SIG_IGN)
        signal(SIGTERM, SIG_IGN)
        
        sigintSource.resume()
        sighupSource.resume()
        sigtermSource.resume()
        
        return [sigintSource, sighupSource, sigtermSource]
    }
    
    public static func stop() {
        CFRunLoopStop(CFRunLoopGetMain())
    }
}
