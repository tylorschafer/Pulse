//
//  Item.swift
//  Pulse
//
//  Created by Tylor Schafer on 11/3/25.
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
