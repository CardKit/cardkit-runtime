//
//  ExecutableTokenCard.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/22/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

import CardKit

open class ExecutableTokenCard: CarriesTokenCardState {
    var tokenCard: TokenCard
    
    public init(with card: TokenCard) {
        self.tokenCard = card
    }
}
