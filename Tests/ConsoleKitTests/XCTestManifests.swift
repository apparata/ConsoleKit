//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ConsoleKitTests.allTests),
    ]
}
#endif
