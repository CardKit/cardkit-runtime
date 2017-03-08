//
//  CKWaitUntilTimeTests.swift
//  CardKitRuntime
//
//  Created by ismails on 3/7/17.
//  Copyright © 2017 IBM. All rights reserved.
//

@testable import CardKit
@testable import CardKitRuntime

import Freddy
import Foundation
import XCTest

class CKWaitUntilTimeTests: XCTestCase {
    public static let expectationTimeout: TimeInterval = 20
    
    func testWaitUntilTimeExecutable() {
        let inputsToTest: [TimeInterval] = [0, 5, -5]
        
        for input in inputsToTest {
            executeWaitUntilTime(input)
        }
    }
    
    func executeWaitUntilTime(_ seconds: TimeInterval) {
        //executableInstance
        let waitUntilTimeExecutable = CKWaitUntilTime(with: CardKit.Action.Trigger.Time.WaitUntilTime.makeCard())
        
        // bind inputs and tokens
        let cardStartTime = Date()
        let secondsToWait: TimeInterval = seconds
        let cardStartTimePlusSeconds = cardStartTime.addingTimeInterval(secondsToWait)
    
        let inputBindings: [String : JSONEncodable] = ["ClockTime": cardStartTimePlusSeconds]
        waitUntilTimeExecutable.setup(inputBindings: inputBindings, tokenBindings: [:])
        
        // execute
        let myExpectation = expectation(description: "test completion")
        
        DispatchQueue.global(qos: .default).async {
            waitUntilTimeExecutable.main()
            myExpectation.fulfill()
        }
        
        waitForExpectations(timeout: CardKitRuntimeTests.expectationTimeout) { error in
            if let error = error {
                XCTFail("error: \(error)")
            }
            
            let currentDate = Date()
            let timeElapsed = currentDate.timeIntervalSince(cardStartTime)
            
            //if the seconds to wait is negative, then time elapsed should be around 0
            //if seconds to wait is zero or positive, and the difference between secondsToWait and
            //time elapsed is greater than one, then the card did not wait until the correct time
            if (secondsToWait < 0 && timeElapsed > 1) ||
                (secondsToWait >= 0 && abs(secondsToWait - timeElapsed) > 1) {
                XCTFail("Card did not wait until the specified time. cardStartTime: \(cardStartTime), secondsToWait: \(secondsToWait), Time Elapsed: \(timeElapsed)")
            }
        }
    }
}
