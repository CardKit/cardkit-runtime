//
//  ExecutionEngineTests.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/29/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import XCTest
@testable import CardKit

class ExecutionEngineTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCalculator() {
        var deck: Deck? = nil
        var yield: Yield? = nil
        
        do {
            let five = try (CardKit.Input.Numeric.Real <- 5.0)
            let ten = try (CardKit.Input.Numeric.Real <- 10.0)
            
            let add = try (CKCalc.Action.Math.Add <- five) <- ten
            let handOne = ( add )%
            
            let mult = CKCalc.Action.Math.Multiply.makeCard()
            
            guard let addYield = add.descriptor.yields.first else {
                XCTFail("could not get yield of Add card")
                return
            }
            
            guard let slotA = mult.inputSlots.slot(named: "A") else {
                XCTFail("could not get slot A")
                return
            }
            
            guard let slotB = mult.inputSlots.slot(named: "B") else {
                XCTFail("could not get slot B")
                return
            }
            
            mult.bind(with: add, yield: addYield, in: slotA)
            
            let two = try (CardKit.Input.Numeric.Real <- 2.0)
            mult.bind(with: two, in: slotB)
            
            yield = mult.yields.first
            
            let handTwo = ( mult )%
            
            deck = ( handOne ==> handTwo )%
            
        } catch let error {
            XCTFail("error setting up deck: \(error)")
        }
        
        guard let d = deck else {
            XCTFail("error setting up the deck")
            return
        }
        
        guard let y = yield else {
            XCTFail("error getting the final yield")
            return
        }
        
        let engine = ExecutionEngine(with: d)
        engine.setExecutableActionType(CKAdd.self, for: CKCalc.Action.Math.Add)
        engine.setExecutableActionType(CKSubtract.self, for: CKCalc.Action.Math.Subtract)
        engine.setExecutableActionType(CKMultiply.self, for: CKCalc.Action.Math.Multiply)
        engine.setExecutableActionType(CKDivide.self, for: CKCalc.Action.Math.Divide)
        
        print("\(deck!.toJSON().stringify(true))")
        
        engine.execute() {
            (yields: YieldBindings, error: ExecutionError?) in
            
            if let result = yields[y] {
                print("result: \(result)")
            }
            if let error = error {
                print("error: \(error)")
            }
        }
    }

}
