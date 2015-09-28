//
//  Vote.swift
//  wiserIos
//
//  Created by Peter Helstrup Jensen on 21/09/2015.
//  Copyright © 2015 Peter Helstrup Jensen. All rights reserved.
//

import Foundation

/// A Vote is an up or downvote for a question. Value will either be -1 for down, or 1 for up.
class Vote {
    var CreatedById: String?
    var Value: Int?
    
    init(createdById: String, value: Int){
        self.CreatedById = createdById
        self.Value = value
    }
}