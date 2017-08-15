//
//  ExecutionEngineTests.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/29/16.
//  Copyright © 2016 IBM. All rights reserved.
//

// swiftlint:disable function_body_length cyclomatic_complexity

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
                    guard let sum: Double = yield.data.unboxedValue() else {
                        XCTFail("could not unbox yield data for sum")
                        return
                    }
                    XCTAssertTrue(sum == 3100.0)
                case primeSieve.identifier:
                    guard let primeList: PrimeList = yield.data.unboxedValue() else {
                        XCTFail("could not unbox yield data for primeList")
                        return
                    }
                    
                    let primes = primeList.primes
                    XCTAssertTrue(primes.count > 0)
                default:
                    XCTFail("encountered a Yield that wasn't produced by the Add or PrimeSieve card")
                }
            }
        })
    }
    
    func testEmergencyStopFromActionCard() {
        // token cards
        let sieveCard = CKCalc.Token.Sieve.makeCard()
        
        // action cards
        var primeSieve = CKCalc.Action.Math.PrimeSieve.makeCard()
        let doesNotCompute = CKCalc.Action.Math.DoesNotCompute.makeCard()
        
        // bind tokens
        do {
            primeSieve = try primeSieve <- ("Sieve", sieveCard)
        } catch let error {
            XCTFail("error binding token cards: \(error)")
        }
        
        // set up the deck
        let deck = ( primeSieve ++ doesNotCompute )%
        
        // add tokens to the deck
        deck.add(sieveCard)
        
        // set up the execution engine
        let engine = ExecutionEngine(with: deck)
        engine.setExecutableActionType(CKPrimeSieve.self, for: CKCalc.Action.Math.PrimeSieve)
        engine.setExecutableActionType(CKDoesNotCompute.self, for: CKCalc.Action.Math.DoesNotCompute)
        
        // create token instances
        let sieve = CKSieveOfEratosthenes(with: sieveCard)
        
        engine.setTokenInstance(sieve, for: sieveCard)
        
        // execute
        engine.execute({ (yields: [YieldData], error: ExecutionError?) in
            // no yields
            XCTAssertTrue(yields.count == 0)
            
            // should have an error
            guard let executionError = error else {
                XCTFail("expected a non-nil error")
                return
            }
            
            // error should be ExecutionError.actionCardErrorsTriggeredEmergencyStop
            if case .actionCardErrorsTriggeredEmergencyStop(let actionCardErrors, let results) = executionError {
                // expecting one error that triggered the emergency stop
                XCTAssertTrue(actionCardErrors.count == 1)
                
                if let actionCardError = actionCardErrors.first {
                    switch actionCardError {
                    case ActionExecutionError.emergencyStop(let estopError):
                        switch estopError {
                        case CKCalculatorError.doesNotCompute:
                            break
                        default:
                            XCTFail("expected the error that triggered the emergency stop is CKCalculatorError.doesNotCompute")
                        }
                    default:
                        XCTFail("expected the error that triggered the emergency stop is ActionExecutionError.emergencyStop")
                    }
                } else {
                    XCTFail("expected to find the error that triggered the emergency stop")
                }
                
                // expect one token card to have halted execution
                XCTAssertTrue(results.keys.count == 1)
                
                // expect that it was the calculator token
                XCTAssertNotNil(results[sieveCard])
                
                // expect the halt result to be .success
                guard let result = results[sieveCard] else {
                    XCTFail("unable to retrieve emergency stop result for the sieveCard")
                    return
                }
                
                switch result {
                case .success:
                    break
                case .ignored:
                    XCTFail("expected the emergency stop result for the sieveCard to be .success")
                case .failure:
                    XCTFail("expected the emergency stop result for the sieveCard to be .success")
                }
            } else {
                XCTFail("expected an ExecutionError.actionCardErrorsTriggeredEmergencyStop")
            }
        })
    }
    
    func testHaltOfDeckExecutor() {
        class EngineDelegate: ExecutionEngineDelegate {
            func deckExecutor(_ executor: DeckExecutor, willValidate deck: Deck) {
                print("*** deckExecutor \(executor) willValidate \(deck)")
            }
            func deckExecutor(_ executor: DeckExecutor, didValidate deck: Deck) {
                print("*** deckExecutor \(executor) didValidate \(deck)")
            }
            func deckExecutor(_ executor: DeckExecutor, willExecute deck: Deck) {
                print("*** deckExecutor \(executor) willExecute \(deck)")
            }
            func deckExecutor(_ executor: DeckExecutor, willExecute hand: Hand) {
                print("*** deckExecutor \(executor) willExecute \(hand)")
            }
            func deckExecutor(_ executor: DeckExecutor, willExecute card: Card) {
                print("*** deckExecutor \(executor) willExecute \(card)")
            }
            func deckExecutor(_ executor: DeckExecutor, didExecute deck: Deck, producing yields: [Yield : YieldData]?) {
                print("*** deckExecutor \(executor) didExecute \(deck) producing \(yields)")
            }
            func deckExecutor(_ executor: DeckExecutor, didExecute hand: Hand, producing yields: [Yield : YieldData]?) {
                print("*** deckExecutor \(executor) didExecute \(hand) producing \(yields)")
            }
            func deckExecutor(_ executor: DeckExecutor, didExecute card: Card, producing yields: [Yield : YieldData]?) {
                print("*** deckExecutor \(executor) didExecute \(card) producing \(yields)")
            }
            func deckExecutor(_ executor: DeckExecutor, hadErrors errors: [Error]) {
                print("*** deckExecutor \(executor) hadErrors \(errors)")
            }
        }
        
        // token cards
        let sieveCard = CKCalc.Token.Sieve.makeCard()
        
        // action cards
        var primeSieve = CKCalc.Action.Math.PrimeSieve.makeCard()
        
        // bind tokens
        do {
            primeSieve = try primeSieve <- ("Sieve", sieveCard)
        } catch let error {
            XCTFail("error binding token cards: \(error)")
        }
        
        // set up the deck
        let deck = ( ( primeSieve )% )%
        
        // add tokens to the deck
        deck.add(sieveCard)
        
        // set up the execution engine
        let engine = ExecutionEngine(with: deck)
        engine.setExecutableActionType(CKPrimeSieve.self, for: CKCalc.Action.Math.PrimeSieve)
        
        // create token instances
        let sieve = CKSieveOfEratosthenes(with: sieveCard)
        engine.setTokenInstance(sieve, for: sieveCard)
        
        // create delegate
        engine.delegate = EngineDelegate()
        
        // execute
        engine.execute({ (_, _) in
            XCTFail("execution of this deck should never finish")
        })
        
        // wait 3 seconds
        Thread.sleep(forTimeInterval: 3)
        
        // halt execution
        engine.halt()
        
        // wait 3 more seconds just to see if the halt() triggers the callback
        // on execute
        Thread.sleep(forTimeInterval: 3)
        
        // expect that the emergencyStop() method was called on the token
        guard let emergencyStopError = sieve.emergencyStopError else {
            XCTFail("expected that emergencyStop() was called on the sieve token")
            return
        }
        
        // expect that the error is ExecutionError.executionCancelled
        switch emergencyStopError {
        case ExecutionError.executionCancelled:
            break
        default:
            XCTFail("expected the emergencyStop error to be ExecutionError.executionCancelled, instead it was \(emergencyStopError)")
        }
    }
}
