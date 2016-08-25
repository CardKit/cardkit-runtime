//
//  CardValidatorTests.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/17/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import XCTest
@testable import Freddy
@testable import CardKit

class CardValidatorTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testCardDescriptorTypeDoesNotMatchInstanceType() {
        let str = "{\"tokenBindings\":{},\"identifier\":\"137335BB-BEFA-4E37-BB6B-DC6E2D71101A\",\"descriptor\":{\"cardType\":\"Input\",\"assetCatalog\":{\"textualDescription\":\"No action performed.\"},\"version\":0,\"tokenSlots\":[],\"yieldDescription\":\"\",\"ends\":true,\"endDescription\":\"Ends instantly.\",\"yields\":[],\"path\":{\"path\":[\"Action\",\"nil\"]},\"inputSlots\":[],\"name\":\"No Action\"},\"inputBindings\":{}}"
        let data = str.dataUsingEncoding(NSUTF8StringEncoding)!
        let json = try! JSON(data: data)
        
        let noAction = try! ActionCard(json: json)
        
        let deck = Deck()
        let hand = Hand()
        hand.add(noAction)
        deck.add(hand)
        
        let errors = ValidationEngine.validate(noAction, hand, deck)
        print("\(errors)")
        
//        let noAction =
//        let noAction = CardKit.Action.NoAction.instance()
//        let data = try! noAction.toJSON().serialize()
//        let str = String(data: data, encoding: NSUTF8StringEncoding)!
//        print("\(str)")
    }

}
