//
//  NameTests.swift
//  VJson
//
//  Created by Marinus van der Lugt on 03/10/17.
//
//

import XCTest
import VJson


class NameTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    
    // Testing: nameValue
    
    func testNameValue() {
        
        // Without a name
        let json = VJson()
        json.undoManager = UndoManager()
        XCTAssertFalse(json.hasName)
        XCTAssertNil(json.nameValue)
        
        #if os(macOS)
        json.undoManager?.removeAllActions()
        #endif
        
        // With a name
        json.nameValue = "aName"
        XCTAssertTrue(json.hasName)
        XCTAssertEqual(json.nameValue, "aName")
        
        #if os(macOS)

        json.undoManager?.undo()
        
        XCTAssertFalse(json.hasName)
        XCTAssertNil(json.nameValue)

        #endif
    }
}
