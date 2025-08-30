//
//  Item.swift
//  Serenity
//
//  Created by Mario Moschetta on 30/08/25.
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
