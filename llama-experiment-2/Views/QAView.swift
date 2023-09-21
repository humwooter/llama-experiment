//
//  QAView.swift
//  llama-experiment-2
//
//  Created by Katya Raman on 9/11/23.
//

import Foundation
import SwiftUI


struct QAView : View {
    @State var sidebar = ["Documents", "Chats"]
    @State var selected_view = "Documents"
    var body : some View {
        NavigationSplitView {
            List(sidebar, id: \.self, selection: $selected_view) { selection in
                if (selection == "Documents") {
                    Label(selection, systemImage: "doc.fill").padding(7)
                }
                else {
                    Label(selection, systemImage: "message.fill").padding(7)
                }
            }
        } content: {
            Text("Content")
        } detail: {
            Text("Detail")
        }

//        Text("QA View")
    }
}
