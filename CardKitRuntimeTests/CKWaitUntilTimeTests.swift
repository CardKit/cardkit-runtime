//
//  CKWaitUntilTimeTests.swift
//  CardKitRuntime
//
//  Created by ismails on 3/7/17.
//  Copyright © 2017 IBM. All rights reserved.
//

@testable import CardKit
@testable import CardKitRuntime

import Foundation
import XCTest

class CKWaitUntilTimeTests: XCTestCase {
    public let expectationTimeout: TimeInterval = 8
    
    func testWaitUntilTimeExecutable() {
        // test a range of seconds, 3 as the standard case and 0, -5 for the edge cases
        let inputsToTest: [TimeInterval] = [0, 3, -5]
        
        for secondsInput in inputsToTest {
            executeWaitUntilTime(addSeconds: secondsInput)
        }
    }
    
    func executeWaitUntilTime(addSeconds seconds: TimeInterval) {
        // create executable instance
        let waitUntilTimeExecutable = CKWaitUntilTime(with: CardKit.Action.Trigger.Time.WaitUntilTime.makeCard())
        
        // bind inputs and tokens
        let cardStartTime = Date()
        let secondsToWait: TimeInterval = seconds
        let cardStartTimePlusSeconds = cardStartTime.addingTimeInterval(secondsToWait)
        
        guard let clockTime = cardStartTimePlusSeconds.boxedEncoding() else {
            XCTFail("could not get boxed encoding of cardStartTimePlusSeconds")
            return
        }
        
        let inputBindings: [String : Data] = ["ClockTime": clockTime]
        waitUntilTimeExecutable.setup(inputBindings: inputBindings, tokenBindings: [:])
        
        // execute
        let myExpectation = expectation(description: "test completion")
        
        DispatchQueue.global(qos: .default).async {
            waitUntilTimeExecutable.main()
            myExpectation.fulfill()
        }
        
        waitForExpectations(timeout: expectationTimeout) { error in
            if let error = error {
                XCTFail("error: \(error)")
            }
            
            let threshold: TimeInterval = 1
            let currentDate = Date()
            let timeElapsed = currentDate.timeIntervalSince(cardStartTime)
            
            //if the seconds to wait is negative, then time elapsed should be around 0
            //if seconds to wait is zero or positive, and the difference between secondsToWait and
            //time elapsed is greater than one, then the card did not wait until the correct time
            if (secondsToWait < 0 && timeElapsed > threshold) ||
                (secondsToWait >= 0 && abs(secondsToWait - timeElapsed) > threshold) {
                XCTFail("Card did not wait until the specified time. cardStartTime: \(cardStartTime), secondsToWait: \(secondsToWait), Time Elapsed: \(timeElapsed), endTime: \(currentDate)")
            }
        }
    }
}
