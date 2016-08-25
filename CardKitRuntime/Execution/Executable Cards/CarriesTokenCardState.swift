//
//  CarriesTokenCardState.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/22/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

import CardKit

/// Appled to classes that implement an executable TokenCard
protocol CarriesTokenCardState {
    var tokenCard: TokenCard { get }
}
