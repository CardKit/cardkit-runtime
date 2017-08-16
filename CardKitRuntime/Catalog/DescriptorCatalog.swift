//
//  DescriptorCatalog.swift
//  CardKit
//
//  Created by Justin Weisz on 8/16/17.
//  Copyright © 2017 IBM. All rights reserved.
//

import Foundation

import CardKit

public protocol DescriptorCatalog {
    /// Complete list of all the card descriptors provided by this descriptor catalog.
    var descriptors: [CardDescriptor] { get }
    
    /// Card descriptors grouped by path, e.g. "Action/Trigger/Time", "Input/Numeric", etc.
    /// This method is implemented in an extension to `DescriptorCatalog` and does not need
    /// to be implemented by new `DescriptorCatalog` implementors.
    var descriptorsByPath: [String: [CardDescriptor]] { get }
    
    /// Map between an `ActionCardDescriptor` and its `ExecutableAction` type.
    var executableActionTypes: [ActionCardDescriptor : ExecutableAction.Type] { get }
}

extension DescriptorCatalog {
    public var descriptorsByPath: [String : [CardDescriptor]] {
        var groups: [String : [CardDescriptor]] = [:]
        
        for descriptor in self.descriptors {
            if groups[descriptor.path.description] == nil {
                groups[descriptor.path.description] = []
            }
            groups[descriptor.path.description]?.append(descriptor)
        }
        
        return groups
    }
}
