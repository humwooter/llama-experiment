//
//  ChatView.swift
//  llama-experiment-2
//
//  Created by Katya Raman on 9/22/23.
//

import Foundation
import SwiftUI
import PythonKit
import AppKit
import Security


struct ChatView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Chat.lastMessageDate, ascending: false)],
        animation: .default)
    private var chats: FetchedResults<Chat>
    
    
    
    
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @EnvironmentObject var userPreferences: UserPreferences
    
    
    @State var models_paths = ["llama 2 7b"] //list of modelPaths
    @State var selected_model_path = ""
    @State private var userInput: String = ""
    @State private var chatHistory: [String] = []
    @State private var modelPath: String?
    @State private var isLoading: Bool = false
    
    @State private var selected_chat: Chat? = nil
    @State private var isCreatingNewChat = false
    @State private var textEditorHeight: CGFloat = 50 // Initial height
    //    @State private var pythonScriptsPath: String = "/Users/kraman/Desktop/python_scripts"
    @Binding var selectedTab: Int
    
    @State private var selected_model_type: String = "GPT 3.5"
    @State private var selected_h2o_model: String = "llama2-70b"
    
    @State private var isRenamingChat: [UUID: Bool] = [:]
    @State private var chatToRename: Chat? = nil
    @State private var newChatName: String = ""
    @State private var isExported: Bool = false
    
    @State private var openAIKey: String? = {
        if let data = loadFromKeychain(key: "OpenAI_API_Key") {
            return String(data: data, encoding: .utf8)
        } else {
            return nil
        }
    }()
    @State private var enteredKey: String = "wef"
    @State private var isKeySaved: Bool = false
    
    
    
    
    var body : some View {
        
        var filteredChats: [Chat] {
            return chats.filter { $0.modelName == selected_model_type }
        }
        //        if let mostRecentChat = filteredChats.max(by: { $0.lastMessageDate! < $1.lastMessageDate! }) {
        //            let sortedMessages = (mostRecentChat.relationship as? Set<Message> ?? [])
        //                .sorted { $0.timestamp! < $1.timestamp! }
        //            let mostRecentMessage = sortedMessages.last
        //        }
        
        
        NavigationSplitView {
            //            if let mostRecentChat = filteredChats.max(by: { $0.lastMessageDate! < $1.lastMessageDate! }) {
            //                let sortedMessages = (mostRecentChat.relationship as? Set<Message> ?? [])
            //                    .sorted { $0.timestamp! < $1.timestamp! }
            //                let mostRecentMessage = sortedMessages.last
            //
            List(modelType, id: \.self, selection: $selected_model_type) { model_type in
                ModelTypeView(selected_model_type: model_type, selected_h2o_model: $selected_h2o_model)
                //                    Text(model_type)
                //                        .padding(7)
            }
            //            }
            
        } content: {
            List(filteredChats, id: \.self, selection: $selected_chat) { chat in
                Text(chat.chatName ?? "Unnamed Chat")
                    .padding(7)
                    .popover(isPresented: Binding(get: {
                        self.isRenamingChat[chat.id ?? UUID()] ?? false
                    }, set: {
                        self.isRenamingChat[chat.id ?? UUID()] = $0
                    })) {
                        VStack {
                            TextField("New chat name", text: $newChatName)
                                .onSubmit {
                                    chat.chatName = newChatName
                                    try? viewContext.save()
                                    isRenamingChat[chat.id ?? UUID()] = false
                                }
                            Button("Save") {
                                chat.chatName = newChatName
                                try? viewContext.save()
                                isRenamingChat[chat.id ?? UUID()] = false
                            }
                        }
                        .padding()
                    }
                    .contextMenu {
                        Button(action: {
                            deleteChat(chat: chat)
                        }) {
                            Text("Delete Chat")
                            Image(systemName: "trash")
                        }
                        Button(action: {
                            isRenamingChat[chat.id ?? UUID()] = true
                        }) {
                            Text("Rename Chat")
                            Image(systemName: "pencil")
                        }
                    }
            }
            
            .toolbar {
                if selectedTab == 0 {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            isCreatingNewChat = true
                        }) {
                            Image(systemName: "plus")
                        }
                        .sheet(isPresented: $isCreatingNewChat) {
                            NewChatOverlayView(isPresented: $isCreatingNewChat, modelName: $selected_model_type)
                                .background(Color.clear)
                        }
                    }
                    
                }
            }
        }
    detail: {
        if openAIKey != nil {
            ZStack {
                VStack {
                    Spacer()
                    ScrollView {
                        let sortedMessages = (selected_chat?.relationship as? Set<Message> ?? [])
                            .sorted { $0.timestamp! < $1.timestamp! }
                        
                        ForEach(sortedMessages, id: \.self) { message in
                            HStack {
                                if message.isSender {
                                    Spacer()
                                    Text(message.content ?? "empty")
                                        .padding(6.5)
                                        .background(userPreferences.accentColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                        .contextMenu {
                                            Button(action: {
                                                let pasteboard = NSPasteboard.general
                                                pasteboard.declareTypes([.string], owner: nil)
                                                pasteboard.setString(message.content ?? "", forType: .string)
                                            }) {
                                                Text("Copy Message")
                                                Image(systemName: "doc.on.doc")
                                            }
                                        }
                                        .textSelection(.enabled)
                                } else {
                                    Text(message.content ?? "empty")
                                        .padding(6.5)
                                        .background(colorScheme == .dark ? Color.white.opacity(0.2) : Color.gray.opacity(0.2))
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .cornerRadius(10)
                                    
                                        .contextMenu {
                                            
                                            Button(action: {
                                                let pasteboard = NSPasteboard.general
                                                pasteboard.declareTypes([.string], owner: nil)
                                                pasteboard.setString(message.content ?? "", forType: .string)
                                            }) {
                                                Text("Copy Message")
                                                Image(systemName: "doc.on.doc")
                                            }
                                        }
                                        .textSelection(.enabled)
                                    Spacer()
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 3)
                        }
                    }
                    
                    if isLoading {
                        ProgressView()
                            .padding()
                            .animation(Animation.easeInOut(duration: 1).repeatForever())
                    }
                    
                    HStack {
                        TextField("message", text: $userInput, prompt: Text("message"), axis: .vertical).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20)).lineSpacing(10)
                        
                            .onSubmit {
                                sendMessage()
                            }
                        Button {
                            isExported = true
                            exportChatAsJSON()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        //                .background(isExported ? Color.blue : Color.clear)
                        
                    }
                    .padding()
                }
                .onChange(of: selected_model_type, perform: { newValue in
                    print("filtered chats: \(filteredChats)")
                    if let mostRecentChat = filteredChats.max(by: {
                        ($0.lastMessageDate ?? Date.distantPast) < ($1.lastMessageDate ?? Date.distantPast)
                    }) {
                        selected_chat = mostRecentChat
                    } else {
                        selected_chat = nil
                    }
                })
            }
        }
        
    }
    }
    
    
    func sendMessage() {
        print("ENTERED SEND MESSAGe")
        var path: String?

        isLoading = true
        let newMessage_user = createNewMessage(messageContent: userInput, isSender: true)
        selected_chat?.addToRelationship(newMessage_user)
        
        
        Task {
            let rawResponse = await generate_output(userInput: userInput, modelPath: selected_chat?.modelPath)
            let cleanedResponse = cleanResponse(rawResponse)
            
            DispatchQueue.main.async {
                
                //                let user_message = createNewMessage(messageContent: userInput, isSender: true)
                let response_message = createNewMessage(messageContent: cleanedResponse, isSender: false)
                //                selected_chat?.addToRelationship(user_message)
                //                selected_chat?.addToRelationship(response_message)
                
                print("response message: \(response_message)")
                print("USER INPUT: \(userInput)")
                chatHistory.append("\(userInput)")
                chatHistory.append("\(cleanedResponse)")
                
                //                let newMessage_user = createNewMessage(messageContent: userInput, isSender: true)
                let newMessage_model = createNewMessage(messageContent: cleanedResponse, isSender: false)
                
                
                //                selected_chat?.addToRelationship(newMessage_user)
                selected_chat?.addToRelationship(newMessage_model)
                
                
                print(selected_chat)
                
                userInput = ""
                isLoading = false
            }
        }
    }
    
    
//     func generate_output(userInput: String, modelPath: String?) async -> String {
//         var result = ""
//         var url: URL?
//         var params: [String: String] = ["userInput": userInput, "chat_uuid": selected_chat?.id?.uuidString ?? ""]
//
//         switch selected_model_type {
//         case "Llama":
//             url = URL(string: "http://localhost:8000/run_ggml_model")
//             params["model_path"] = selected_chat?.modelPath ?? ""
//
//         case "GPT 3.5", "GPT 4":
//
//             guard let OPENAI_KEY_data = loadFromKeychain(key: "OpenAI_API_Key") else {
//                 // Handle the error: the key doesn't exist in the Keychain
//                 return "no key"
//             }
//
//             guard let OPENAI_KEY_string = String(data: OPENAI_KEY_data, encoding: .utf8) else {
//                 // Handle the error: the data couldn't be converted to a string
//                 return "no key"
//             }
//
//             url = URL(string: "http://localhost:8000/run_openai_model")
//
//             params["modelName"] = selected_model_type
//             params["openai_key"] = OPENAI_KEY_string
//         case "H2O GPT":
//             url = URL(string: "http://localhost:8000/run_h2o_model")
//             var model_endpoint = h2o_model_to_endpoint[selected_h2o_model]
//             print("model endpoint: \(model_endpoint)")
//             params["model_endpoint"] = model_endpoint
//
//         default:
//             return ""
//         }
//
//         guard let finalUrl = url else { return "" }
//
//         var components = URLComponents(url: finalUrl, resolvingAgainstBaseURL: false)!
//         components.queryItems = params.map { (key, value) in
//             URLQueryItem(name: key, value: value)
//         }
//
//         let request = URLRequest(url: components.url!)
//
//         do {
//             let (data, _) = try await URLSession.shared.data(for: request)
//
//             if let json = try? JSONSerialization.jsonObject(with: data, options: []),
//                let jsonDict = json as? [String: Any],
//                let apiResult = jsonDict["result"] as? String {
//                 result = apiResult
//             }
//         } catch {
//             print("Error making API request: \(error)")
//             return ""
//         }
//
//         return result
//     }
    
    func generate_output(userInput: String, modelPath: String?) async -> String {
        if userPreferences.openAIKey.isEmpty {
            return "please enter valid openAI API key"
        }

        print("selected model type: \(selected_model_type)")
        var result = ""
        var url: URL?
        var params: [String: Any] = [
            "model": openai_model_to_endpoint[selected_model_type], // Specify the model type here
            "messages": [["role": "system", "content": "You are a helpful assistant."], ["role": "user", "content": userInput]]
        ]
        switch selected_model_type {
        case "GPT 3.5", "GPT 4":
            url = URL(string: "https://api.openai.com/v1/chat/completions")
        default:
            return ""
        }

        print("URL: \(url)")

        guard let finalUrl = url else { return "" }
        print("finalUrl: \(finalUrl)")

  
        var request = URLRequest(url: finalUrl)
        request.httpMethod = "POST"
        request.addValue("Bearer \(userPreferences.openAIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        print("request: \(request)")


        do {
            let jsonData = try JSONSerialization.data(withJSONObject: params, options: [])
            request.httpBody = jsonData
        } catch {
            print("Error creating JSON from parameters: \(error)")
            return ""
        }

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data, options: []),
               let jsonDict = json as? [String: Any],
               let apiResult = jsonDict["choices"] as? [[String: Any]],
               let firstChoice = apiResult.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                result = content
            }
        } catch {
            print("Error making API request: \(error)")
            return ""
        }
        return result
    }
    
    
    
    func exportChatAsJSON() {
        guard let selectedChat = selected_chat else { print("WURD")
            return }
        do {
            //            let sortedMessages = (selectedChat.relationship as? Set<Message> ?? [])
            //                .sorted { $0.timestamp! < $1.timestamp! }
            //            selectedChat.chatHistory = sortedMessages.map { $0.content ?? "empty" }
            
            let encoder = JSONEncoder()
            //            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(selectedChat)
            
            
            
            let panel = NSSavePanel()
            panel.nameFieldStringValue = selectedChat.chatName ?? "UnnamedChat"
            panel.allowedFileTypes = ["json"]
            
            panel.begin { (result) in
                if result == NSApplication.ModalResponse.OK {
                    guard let url = panel.url else { return }
                    do {
                        try data.write(to: url)
                        print("File successfully saved at \(url)")
                        isExported = false
                    } catch {
                        print("Failed to save file: \(error)")
                    }
                }
            }
        } catch {
            print("Failed to export chat: \(error)")
        }
    }
    
    
    func createNewChat() {
        @State var chatName = ""
        // Call the select_llama_file function to get the model path
        if selected_model_type == "Llama" {
            let newModelPath = select_llama_file()
        }
        
        // Check if a model path was selected
        //        if let path = newModelPath {
        // Create a new Chat object in the view context
        let newChat = Chat(context: viewContext)
        
        // Set the model path of the new chat
        newChat.modelPath = selected_model_path
        newChat.chatHistory = []
        newChat.id = UUID()
        newChat.lastMessageDate = Date()
        newChat.chatName = "new chat"
        
        
        // Save the view context
        do {
            try viewContext.save()
        } catch {
            // Handle the error appropriately
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        //        }
    }
    
    func createNewMessage(messageContent: String, isSender: Bool) -> Message{
        let newMessage = Message(context: viewContext)
        newMessage.id = UUID()
        newMessage.content = messageContent
        newMessage.isSender = isSender
        newMessage.timestamp = Date()
        newMessage.relationship = selected_chat
        selected_chat?.lastMessageDate = newMessage.timestamp
        do {
            try viewContext.save()
        } catch {
            // Handle the error appropriately
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return newMessage
    }
    func deleteChat(chat: Chat) {
        //should also terminate the chat subprocess
        if let messages = chat.relationship as? Set<Message> {
            for message in messages {
                viewContext.delete(message)
            }
        }
        
        //        killChat(id: chat.id)
        viewContext.delete(chat)
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
