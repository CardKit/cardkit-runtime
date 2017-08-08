//
//  CKTimerTests.swift
//  CardKitRuntime
//
//  Created by Kyungmin Lee on 3/16/17.
//  Copyright © 2017 IBM. All rights reserved.
//

@testable import CardKit
@testable import CardKitRuntime

import Foundation
import XCTest

class CKTimerTests: XCTestCase {
    public let expectationTimeout: TimeInterval = 8
    
    func testTimerExecutable() {
        // test a range of seconds, 3 as the standard case and 0, -5 for the edge cases
        let inputsToTest: [TimeInterval] = [0, 3, -5]
        
        for secondsInput in inputsToTest {
            executeSetTimer(waitUntil: secondsInput)
        }
    }
    
    func executeSetTimer(waitUntil seconds: TimeInterval) {
        //executableInstance
        let setTimerExecutable = CKTimer(with: CardKit.Action.Trigger.Time.Timer.makeCard())
        
        // bind inputs and tokens
        let cardStartTime = Date()
        let timerTimeInSeconds: TimeInterval = seconds
        
        let inputBindings: [String : JSONEncodable] = ["Duration": timerTimeInSeconds]
        setTimerExecutable.setup(inputBindings: inputBindings, tokenBindings: [:])
        
        // execute
        let myExpectation = expectation(description: "test completion")
        
        DispatchQueue.global(qos: .default).async {
            setTimerExecutable.main()
            myExpectation.fulfill()
        }
        
        waitForExpectations(timeout: expectationTimeout) { error in
            if let error = error {
                XCTFail("error: \(error)")
            }
            
            let threshold: TimeInterval = 1
            let currentDate = Date()
            let timeElapsed = currentDate.timeIntervalSince(cardStartTime)
         
            // following the same logic implemented in CKWaitUntilTimeTests
            if (timerTimeInSeconds < 0 && timeElapsed > threshold) ||
                (timerTimeInSeconds >= 0 && abs(timerTimeInSeconds - timeElapsed) > threshold) {
                XCTFail("Card did not set the timer for the specified amount of time. cardStartTime: \(cardStartTime), timerTimeInSeconds: \(timerTimeInSeconds), Time Elapsed: \(timeElapsed), endTime: \(currentDate)")
            }
        }
    }
}
