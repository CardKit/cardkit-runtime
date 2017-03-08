//
//  ExecutionEngineTests.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/29/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import XCTest

@testable import CardKit
@testable import CardKitRuntime

class ExecutionEngineTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // swiftlint:disable:next function_body_length
    func testCalculator() {
        var deck: Deck? = nil
        var yield: Yield? = nil
        
        // Calculator token
        let calcToken = CKCalc.Token.Calculator.makeCard()
        
        do {
            let two = try (CardKit.Input.Numeric.Real <- 2.0)
            let five = try (CardKit.Input.Numeric.Real <- 5.0)
            let ten = try (CardKit.Input.Numeric.Real <- 10.0)
            
            let add = try CKCalc.Action.Math.Add <- five <- ten <- ("Calculator", calcToken)
            
            guard let addYield = add.yields.first else {
                XCTFail("error getting the yield of the add card")
                return
            }
            
            let mult = try CKCalc.Action.Math.Multiply <- (add, addYield) <- two <- ("Calculator", calcToken)
            yield = mult.yields.first
            
            let handOne = ( add )%
            let handTwo = ( mult )%
            
            deck = ( handOne ==> handTwo )%
            deck?.add(calcToken)
            
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
        
        let calculator = CKSlowCalculator(with: calcToken)
        engine.setTokenInstance(calculator, for: calcToken)
        
//        print("\(deck!.toJSON().stringify(true))")
        
        engine.execute { (yields: [YieldData], error: ExecutionError?) in
            print("*******")
            
            guard let result = yields.filter({ $0.yield == y }).first else {
                XCTFail("could not find yielded result")
                return
            }
            
            print("result: \(result.data)")
            
            if let error = error {
                print("error: \(error)")
            }
            
            XCTAssertNil(error)
        }
    }
    
    // swiftlint:disable:next function_body_length
    func testYieldsFromNonEndingCard() {
        // token cards
        let sieveCard = CKCalc.Token.Sieve.makeCard()
        let calcCard = CKCalc.Token.Calculator.makeCard()
        
        // action cards
        var primeSieve = CKCalc.Action.Math.PrimeSieve.makeCard()
        var add = CKCalc.Action.Math.Add.makeCard()
        
        // bind tokens
        do {
            primeSieve = try primeSieve <- ("Sieve", sieveCard)
            add = try add <- ("Calculator", calcCard)
        } catch let error {
            XCTFail("error binding token cards: \(error)")
        }
        
        // bind inputs
        do {
            let a = try CardKit.Input.Numeric.Real <- 3000.0
            let b = try CardKit.Input.Numeric.Real <- 100.0
            add = try add <- ("A", a)
            add = try add <- ("B", b)
        } catch let error {
            XCTFail("error binding inputs: \(error)")
        }
        
        // set up the deck
        let deck = ( add ++ primeSieve )%
        
        // add tokens to the deck
        deck.add(sieveCard)
        deck.add(calcCard)
        
        // set up the execution engine
        let engine = ExecutionEngine(with: deck)
        engine.setExecutableActionType(CKPrimeSieve.self, for: CKCalc.Action.Math.PrimeSieve)
        engine.setExecutableActionType(CKAdd.self, for: CKCalc.Action.Math.Add)
        
        // create token instances
        let calculator = CKSlowCalculator(with: calcCard)
        let sieve = CKSieveOfEratosthenes(with: sieveCard)
        
        engine.setTokenInstance(sieve, for: sieveCard)
        engine.setTokenInstance(calculator, for: calcCard)
        
        // execute
        engine.execute({ (yields: [YieldData], error: ExecutionError?) in
            XCTAssertNil(error)
            
            // two yields -- one from add, one from the sieve
            XCTAssertTrue(yields.count == 2)
            
            for yield in yields {
                switch yield.cardIdentifier {
                case add.identifier:
                    do {
                        let sum = try yield.data.decode(type: Double.self)
                        XCTAssertTrue(sum == 3100.0)
                    } catch let error {
                        XCTFail("expected a yield of type Double, error: \(error)")
                    }
                case primeSieve.identifier:
                    do {
                        let primeList = try yield.data.decode(type: PrimeList.self)
                        let primes = primeList.primes
                        XCTAssertTrue(primes.count > 0)
                    } catch let error {
                        XCTFail("expected a yield of type PrimeList, error: \(error)")
                    }
                default:
                    XCTFail("encountered a Yield that wasn't produced by the Add or PrimeSieve card")
                }
            }
        })

    }
}
