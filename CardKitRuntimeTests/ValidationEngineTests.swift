//
//  ValidationEngineTests.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/2/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import XCTest

@testable import CardKit
@testable import CardKitRuntime

class ValidationEngineTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testValidationEngineSimple() {
        let calcToken = CKCalc.Token.Calculator.makeCard()
        let add = CKCalc.Action.Math.Add
        
        do {
            let five = try CardKit.Input.Numeric.Real <- 5.0
            
            let deck = try (
                add <- ("A", five) <- ("B", five) <- ("Calculator", calcToken) ==>
                add <- ("A", five) <- ("B", five) <- ("Calculator", calcToken)
                )%
            deck.add(calcToken)
            
            let errors = ValidationEngine.validate(deck)
            
            XCTAssertTrue(errors.count == 0)
        } catch let error {
            XCTFail("error: \(error.localizedDescription)")
        }
    }
}
