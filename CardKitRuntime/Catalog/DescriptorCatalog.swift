/**
 * Copyright 2018 IBM Corp. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
    var executableActionTypes: [ActionCardDescriptor: ExecutableAction.Type] { get }
}

extension DescriptorCatalog {
    public var descriptorsByPath: [String: [CardDescriptor]] {
        var groups: [String: [CardDescriptor]] = [:]
        
        for descriptor in self.descriptors {
            if groups[descriptor.path.description] == nil {
                groups[descriptor.path.description] = []
            }
            groups[descriptor.path.description]?.append(descriptor)
        }
        
        return groups
    }
}
