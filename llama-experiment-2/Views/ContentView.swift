////
////  ContentView.swift
////  llama-experiment-2
////
////  Created by Katya Raman on 9/5/23.

import SwiftUI
import PythonKit
import AppKit

var modelType: [String] = ["Llama", "GPT 3.5", "GPT 4"]


func cleanResponse(_ response: String) -> String {
    var newResponse =  response.replacingOccurrences(of: "User:Bob: ", with: "")
    newResponse = newResponse.replacingOccurrences(of: "#END#", with: "");
    return newResponse
//    return response
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
    @State private var pythonScriptsPath: String = "/Users/kraman/Desktop/python_scripts"
    @Binding var selectedTab: Int
    
    @State private var selected_model_type: String = "Llama"

    @State private var isRenamingChat: [UUID: Bool] = [:]
    @State private var chatToRename: Chat? = nil
    @State private var newChatName: String = ""
    
    
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
                    ModelTypeView(selected_model_type: model_type)
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
//                    .disabled(selected_chat?.modelPath == nil)
                
                    .onSubmit {
                        sendMessage()
                    }
            }
            .padding()
        }
    }
    }
    
    func sendMessage() {
        print("ENTERED SEND MESSAGe")
        var path: String?
//        guard let path = selected_chat?.modelPath else {
//            //            print("model path: \(modelPath)")
//            // Handle case when model path is not selected
//            return
//        }
//
        isLoading = true
        
        Task {
            let rawResponse = await generate_output(userInput: userInput, modelPath: selected_chat?.modelPath)
            print("RAW RESPONSE: \(rawResponse)")
            let cleanedResponse = cleanResponse(rawResponse)
            
            DispatchQueue.main.async {
                
                let user_message = createNewMessage(messageContent: userInput, isSender: true)
                let response_message = createNewMessage(messageContent: cleanedResponse, isSender: false)
                selected_chat?.addToRelationship(user_message)
                selected_chat?.addToRelationship(response_message)
                
                print("response message: \(response_message)")
                print("USER INPUT: \(userInput)")
                chatHistory.append("\(userInput)")
                chatHistory.append("\(cleanedResponse)")
                
                userInput = ""
                isLoading = false
            }
        }
    }
    
    
    func generate_output(userInput: String, modelPath: String?) async -> String {
        var result = ""
        var url: URL?
        var params: [String: String] = ["userInput": userInput, "chat_uuid": selected_chat?.id?.uuidString ?? ""]

        switch selected_model_type {
        case "Llama":
            url = URL(string: "http://localhost:8000/run_ggml_model")
            params["model_path"] = selected_chat?.modelPath ?? ""
        case "GPT 3.5", "GPT 4":
            url = URL(string: "http://localhost:8000/run_openai_model")
            params["modelName"] = selected_model_type
        default:
            return ""
        }

        guard let finalUrl = url else { return "" }

        var components = URLComponents(url: finalUrl, resolvingAgainstBaseURL: false)!
        components.queryItems = params.map { (key, value) in
            URLQueryItem(name: key, value: value)
        }

        let request = URLRequest(url: components.url!)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            if let json = try? JSONSerialization.jsonObject(with: data, options: []),
               let jsonDict = json as? [String: Any],
               let apiResult = jsonDict["result"] as? String {
                result = apiResult
            }
        } catch {
            print("Error making API request: \(error)")
            return ""
        }

        return result
    }

    
    
    
//    func generate_output(userInput: String, modelPath: String?) async -> String {
////        if let selectedPath = selected_chat?.modelPath, let modelType = selected_chat?.modelType {
////            print("selectedPath: \(selectedPath)")
////            let sys = Python.import("sys")
////            sys.path.append(pythonScriptsPath)
////            print("sys path: \(sys)")
////        if let selectedPath = selected_chat?.modelPath { //path to python scripts
//            print(Python.versionInfo)
//            let sys = Python.import("sys")
//
//            sys.path.append(pythonScriptsPath)
////            print("Python \(sys.version_info.major).\(sys.version_info.minor)")
////            print("Python Version: \(sys.version)")
////            print("Python Encoding: \(sys.getdefaultencoding().upper())")
////            print("Python executable location\(sys.executable)")
////            print("reached generate output")
//
//            let result: String
//            switch selected_model_type {
//            case "Llama":
//                print("ITS LLAMA!")
//                if let selectedPath = selected_chat?.modelPath, let modelType = selected_chat?.modelName {
////                    print("selectedPath: \(selectedPath)")
////                    let sys = Python.import("sys")
////                    sys.path.append(pythonScriptsPath)
////                    print("sys path: \(sys)")
//
//                    let example = Python.import("llama_chat")
//                    let response = example.run_ggml_model(selectedPath, userInput, selected_chat?.id?.uuidString)
//                    result = String(response)!
//                    return result
//                }
//
//            case "GPT 3.5":
//                let example = Python.import("openai_chat")
//                let response = example.run_openai_model(selected_chat?.id?.uuidString, userInput, selected_model_type)
//                result = String(response)!
//                return result
//
//            case "GPT 4":
//                let example = Python.import("openai_chat")
//                let response = example.run_openai_model(selected_chat?.id?.uuidString, userInput, selected_model_type)
//                result = String(response)!
//                return result
//
//            default:
//                result = ""
//                return result
//            }
//
////            print("RESULT: \(result)")
//
////        }
//        return ""
//    }
//
//    func killChat(id: UUID?)  {
//        if let id = id {
//            //            let dirPath = "/Users/kraman/Desktop/python_scripts"
//            if let selectedPath = selected_chat?.modelPath {
//                let sys = Python.import("sys")
//                sys.path.append(pythonScriptsPath)
//                let example = Python.import("llama_chat")
//                example.kill_chat(selected_chat?.id?.uuidString)
//                print("Chat with id \(id) was killed")
//            }
//        }
//    }
    func killChat(id: UUID?)  {
        if let id = id {
            guard let urlString = "http://localhost:8000/kill_chat?chat_uuid=\(id.uuidString)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: urlString) else { return }

            let request = URLRequest(url: url)
            
            Task {
                do {
                    let (_, _) = try await URLSession.shared.data(for: request)
                    print("Chat with id \(id) was killed")
                } catch {
                    print("Error killing the chat: \(error)")
                }
            }
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



struct ContentView: View {
    @State private var pythonScriptsPath: String = "/Users/kraman/Desktop/python_scripts"
    @State private var selectedTab = 0
    @ObservedObject private var userPreferences = UserPreferences()
    
    var body : some View {
        TabView(selection: $selectedTab) {
            ChatView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Llama Chat", systemImage: "home")
                }.tag(0)
                .environmentObject(userPreferences)
            //            QAView()
            //                .tabItem {
            //                    Label("Helium Chat", systemImage: "message.fill")
            //                }.tag(2)
            
            SettingsView(pythonScriptsPath: $pythonScriptsPath)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }.tag(1)
                .environmentObject(userPreferences)
            
        }
        .font(.custom(String(userPreferences.fontName), size: CGFloat(Float(userPreferences.fontSize))))
    }
    
}






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



struct ResizableNSTextView: NSViewRepresentable {
    @Binding var text: String
    
    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.delegate = context.coordinator
        return textView
    }
    
    func updateNSView(_ nsView: NSTextView, context: Context) {
        nsView.string = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ResizableNSTextView
        
        init(_ parent: ResizableNSTextView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}


//struct SettingsView: View {
//    var body: some View {
//        Text("Settings View")
//    }
//}





struct ModelTypeView: View {
    @State var selected_model_type: String
    
    var body: some View {
        HStack {
            // Image and Text
            Image(selected_model_type.lowercased() + ".logo")
                .resizable()
                .frame(width: 60, height: 60)
//                .clipShape(Circle())
            Text(selected_model_type)
                .bold()
//            VStack(alignment: .leading) {
//                Text(selected_model_type)
//                Text(most_recent_message.content ?? "")
//                    .lineLimit(2)
//                    .truncationMode(.tail)
//            }
//
//            Spacer()
            
            // Timestamp
//            Text(dateToString(most_recent_message.timestamp ?? Date()))
//                .font(.footnote)
        }
    }
    
    func dateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
