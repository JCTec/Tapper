//
//  Item.swift
//  Tapper
//
//  Created by Juan Carlos on 05/01/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}