//
//  MessageModel.swift
//  llama-experiment-2
//
//  Created by Katya Raman on 9/5/23.
//

import Foundation
import SwiftUI

struct Message: Identifiable {
    @State var id: UUID
    @State var timestamp: Date
    @State var content: String
    @State var isSender: Bool
}
