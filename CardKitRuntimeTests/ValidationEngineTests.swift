/**
 * Copyright 2018 IBM Corp. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
