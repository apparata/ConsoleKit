# ConsoleKit

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager/) ![MIT License](https://img.shields.io/badge/license-MIT-blue.svg) ![language Swift 5.3](https://img.shields.io/badge/language-Swift%205.3-orange.svg) ![platform macOS](https://img.shields.io/badge/platform-macOS-lightgrey.svg) ![platform Linux](https://img.shields.io/badge/platform-Linux-lightgrey.svg)

The ConsoleKit framework contains various convenient utilities for making it easier to write
terminal I/O in Swift.

## License

ConsoleKit is released under the MIT license. See `LICENSE` file for more detailed information.

# Table of Contents

- [Getting Started](#getting-started)
- [Reference Documentation](#reference-documentation)
- [Features](#features)
  - [Terminal Output](#terminal-output)
  - [Read Evaluate Print Loop](#read-evaluate-print-loop)

# Getting Started

Add ConsoleKit to your Swift package by adding the following to your `Package.swift` file in
the dependencies array:

```swift
.package(url: "https://github.com/apparata/ConsoleKit.git", from: "<version>")
```
You can add CLIKit by entering the URL to the repository via the `File` menu in Xcode:

```
File > Swift Packages > Add Package Dependency...
```

**Note:** ConsoleKit requires **Swift 5.3** or later.

# Reference Documentation

There is generated [reference documentation](https://apparata.github.io/ConsoleKit/ConsoleKit/) available.

# Features

The following sections contain some rudimentary information about the most prominent
features in ConsoleKit, along with examples.

## Terminal Output

Example of using the `TerminalString` struct to print a string with ANSI terminal codes:

```swift
Console.print("\(.green)This is green.\(.reset)\(.bold)This is bold.\(.reset)")
```

If the console is a "dumb" terminal or the Xcode console, the ANSI terminal codes will be
filtered out.

The `Console` class has a few convenience methods for console input and output:

```swift
if Console.confirmYesOrNo(question: "Clear the screen?", default: false) {
    // Clear the screen.
    Console.clear()
} else {
    // Do not clear the screen.
}
```

## Read Evaluate Print Loop

The `ReadEvaluatePrintLoop` class has a built in command line editor with support for
various common keyboard shortcuts, customizable tab completion, a command line
history, and multi-line support. If the terminal is "dumb" or a debugger is attached
(such as if you want to run in the Xcode console) it falls back to just reading buffered lines
from stdin.

Example:

```swift
let readEvaluatePrintLoop = try ReadEvaluatePrintLoop()

readEvaluatePrintLoop.textCompletion = SimpleWordCompletion(completions: [
    "banana",
    "discombobulated",
    "water",
    "whatever"
])

try readEvaluatePrintLoop.run { input in
    guard !["quit", "exit"].contains(input) else {
        return .break
    }
    
    Console.write(terminalString: "You entered: \(input)\n")
    return .continue
}

```

