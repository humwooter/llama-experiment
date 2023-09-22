//
//  NewChatOverlayView.swift
//  llama-experiment-2
//
//  Created by Katya Raman on 9/22/23.
//

import Foundation
import SwiftUI
import PythonKit
import AppKit
import Security


struct NewChatOverlayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isPresented: Bool
    @Binding var modelName: String
    @State private var chatName: String = ""
    @State private var modelPath: String?
    @State private var modelSelected: Bool = false
    //    @State private var selectedModelType: String = "Llama" // Default model type
    
    
    var body: some View {
        VStack() {
            HStack {
                //                Spacer()
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "arrow.left")
                }
                Spacer()
            }
            .padding(.leading)
            .padding(.vertical)
            
            //            Picker("Model Type", selection: $selectedModelType) {
            //                ForEach(modelType, id: \.self) { type in
            //                    Text(type)
            //                }
            //            }
            //            .padding()
            
            
            TextField("Enter chat name", text: $chatName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .background(Color.clear)
                .onSubmit {
                    createNewChat(modelPath: modelPath, chatName: chatName)
                    isPresented = false
                }
            
            HStack(spacing: 5) {
                
                
                if modelName == "Llama" {
                    Button("Select model file") {
                        modelPath = select_llama_file()
                        modelSelected.toggle()
                    }
                    .buttonStyle(.bordered)
                    .tint(modelSelected ? .green : .gray)
                    .padding(15)
                }
                
                
                Button(action: {
                    createNewChat(modelPath: modelPath, chatName: chatName)
                    isPresented = false
                }) {
                    Label("create chat", systemImage: "message.fill")
                }
                .buttonStyle(.bordered)
                .padding(15)
                .disabled(chatName.isEmpty)
            }
        }
        //        .frame(width: 400, height: 400)
        .frame(width: 400)
        //        .background()
        //        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        //        .cornerRadius(20)
        .shadow(radius: 5)
        .padding(15)
        .padding(.vertical, 10)
    }
    
    func createNewChat(modelPath: String?, chatName: String) {
        let newChat = Chat(context:  viewContext)
        newChat.modelPath = modelPath
        newChat.chatName = chatName
        newChat.id = UUID()
        newChat.chatHistory = []
        newChat.modelName = modelName // Set the model type of the new chat
        
        
        // Save the view context
        do {
            try viewContext.save()
        } catch {
            // Handle the error appropriately
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
