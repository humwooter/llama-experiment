////
////  ContentView.swift
////  llama-experiment-2
////
////  Created by Katya Raman on 9/5/23.


import SwiftUI
import PythonKit
import AppKit


func cleanResponse(_ response: String) -> String {
    return response
}



struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Chat.id, ascending: true)],
        animation: .default)
    private var chats: FetchedResults<Chat>
    
    
    @State var models_paths = ["llama 2 7b"] //list of modelPaths
    @State var selected_model_path = ""
    @State private var userInput: String = ""
    @State private var chatHistory: [String] = []
    @State private var modelPath: String?
    @State private var isLoading: Bool = false
    
    @State private var selected_chat: Chat? = nil
    
    
    var body : some View {
        NavigationSplitView {
            List(chats, id: \.self, selection: $selected_chat) { chat in
                Text(chat.chatName ?? "Unnamed Chat")
                    .padding(10)
                    .contextMenu {
                         Button(action: {
                             deleteChat(chat: chat)
                         }) {
                             Text("Delete Chat")
                             Image(systemName: "trash")
                         }
                     }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        // Action to create a new chat
                        createNewChat()
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            
        } detail: {
//            if selected_chat?.modelPath == "/Users/kraman/Desktop/llama.cpp/models/7B-chat/ggml-model-q4_0.bin" {
                VStack {
                    Spacer()
                    ScrollView {
                        let sortedMessages = (selected_chat?.relationship as? Set<Message> ?? [])
                            .sorted { $0.timestamp! < $1.timestamp! }

                 
//                        ForEach(Array(selected_chat!.relationship as? Set<Message> ?? []), id: \.self) { message in
                        ForEach(sortedMessages, id: \.self) { message in
                            HStack {
                                if message.isSender {
                                    Spacer()
                                    Text(message.content ?? "empty")
                                        .padding(5)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                } else {
                                    Text(message.content ?? "empty")
                                        .padding(5)
                                        .background(Color.gray)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
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
                        TextField("Enter your message", text: $userInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(selected_chat?.modelPath == nil)

//                        Button("Select Model") {
//                            selected_chat?.modelPath = select_llama_file()
//                        }
                        Button("Send") {
                            sendMessage()
                        }
                    }
                    .padding()
                }
//            }
//            else {
//                Text("in progress")
//            }
            }
        }

    
    func sendMessage() {
        guard let path = selected_chat?.modelPath else {
//            print("model path: \(modelPath)")
            // Handle case when model path is not selected
            return
        }

        isLoading = true

        Task {
            let rawResponse = generate_output(userInput: userInput, modelPath: path)
            let cleanedResponse = cleanResponse(rawResponse)
            
            let user_message = createNewMessage(messageContent: userInput, isSender: true)
            let response_message = createNewMessage(messageContent: cleanedResponse, isSender: false)
            selected_chat?.addToRelationship(user_message)
            selected_chat?.addToRelationship(response_message)

            
            
            chatHistory.append("User: \(userInput)")
            chatHistory.append("\(cleanedResponse)")

            userInput = ""
            isLoading = false
        }
    }

    func select_llama_file() -> String? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["bin"]

        if panel.runModal() == .OK, let url = panel.url {
            return url.path
        }
        return nil
    }

    func generate_output(userInput: String, modelPath: String?) -> String {
        let dirPath = "/Users/kraman/Desktop/python_scripts"
        if let selectedPath = selected_chat?.modelPath {
            print("selectedPath: \(selectedPath)")
            let sys = Python.import("sys")
            sys.path.append(dirPath)
            print("sys path: \(sys)")
            let example = Python.import("hello")
            let response = example.run_ggml_model(selected_chat?.modelPath, userInput, selected_chat?.id?.uuidString)
            let result : String = String(response)!
            print("RESULT: \(result)")
            
            
            
            return result
        }
        return ""
    }
    
    func killChat(id: UUID?)  {
        if let id = id {
            let dirPath = "/Users/kraman/Desktop/python_scripts"
            if let selectedPath = selected_chat?.modelPath {
                let sys = Python.import("sys")
                sys.path.append(dirPath)
                let example = Python.import("hello")
                example.kill_chat(selected_chat?.id?.uuidString)
                print("Chat with id \(id) was killed")
            }
        }
    }
    

    
    func createNewChat() {
        @State var chatName = ""
        // Call the select_llama_file function to get the model path
        let newModelPath = select_llama_file()
        
        // Check if a model path was selected
        if let path = newModelPath {
            // Create a new Chat object in the view context
            let newChat = Chat(context: viewContext)
            
            // Set the model path of the new chat
            newChat.modelPath = path
            newChat.chatHistory = []
            newChat.id = UUID()
            newChat.chatName = "new chat"
            
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
    
    func createNewMessage(messageContent: String, isSender: Bool) -> Message{
        let newMessage = Message(context: viewContext)
        newMessage.id = UUID()
        newMessage.content = messageContent
        newMessage.isSender = isSender
        newMessage.timestamp = Date()
        newMessage.relationship = selected_chat
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
        
        killChat(id: chat.id)
        viewContext.delete(chat)
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
