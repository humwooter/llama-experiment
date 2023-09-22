//
//  ModelTypeView.swift
//  llama-experiment-2
//
//  Created by Katya Raman on 9/22/23.
//

import Foundation
import SwiftUI
import PythonKit
import AppKit
import Security


struct ModelTypeView: View {
    @State var selected_model_type: String
    @Binding var selected_h2o_model: String
    
    
    var body: some View {
        HStack {
            // Image and Text
            Image(selected_model_type.lowercased() + ".logo")
                .resizable()
                .frame(width: 60, height: 60)
            //                .clipShape(Circle())
            VStack(alignment: .center) {
                Text(selected_model_type)
                    .bold()
                if selected_model_type == "H2O GPT" {
                    Text(selected_h2o_model)
                        .font(.caption).opacity(0.65)
                }
            }
            
        }
        //        if selected_model_type == "H2O GPT" {
        .contextMenu {
            if selected_model_type == "H2O GPT" {
                Button(action: {
                    selected_h2o_model = "llama2-70b"
                }) {
                    Label("Use llama2-70b", image: "llama.logo")
                }
                Button(action: {
                    selected_h2o_model = "falcon-40b-v2"
                }) {
                    Text("Use falcon-40b-v2")
                }
            }
        }
        //        }
        
    }
    
    func dateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
