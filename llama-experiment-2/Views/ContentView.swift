////
////  ContentView.swift
////  llama-experiment-2
////
////  Created by Katya Raman on 9/5/23.

import SwiftUI
import PythonKit
import AppKit
import Security

var modelType: [String] = ["GPT 3.5", "GPT 4"]
var openai_model_to_endpoint: [String: String] = ["GPT 3.5" : "gpt-3.5-turbo", "GPT 4" : "gpt-4-0613"]
var h2o_model_to_endpoint: [String: String] = ["llama2-70b" : "https://llama.h2o.ai", "falcon-40b-v2" : "https://falcon.h2o.ai"]



struct ContentView: View {
    @State private var showingInitialView = true
    @State private var pythonScriptsPath: String? = nil
    @State private var selectedTab = 0
    @ObservedObject private var userPreferences = UserPreferences()
    
//    init() {
//        if showingInitialView == false {
//            if let path = pythonScriptsPath {
//                print("python script path is: \(path)")
//                ServerManager.shared.startServer(pythonScriptsPath: path)
//            } else {
//                print("error")
//            }
//        }
//    }
    
    var body: some View {
//        if showingInitialView {
//            InitialView(pythonScriptsPath: $pythonScriptsPath, showingInitialView: $showingInitialView)
//        } else {
            TabView(selection: $selectedTab) {
                ChatView(selectedTab: $selectedTab)
                    .tabItem {
                        Label("Chat", systemImage: "home")
                    }.tag(0)
                    .environmentObject(userPreferences)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }.tag(1)
                    .environmentObject(userPreferences)
                
            }
            .font(.custom(String(userPreferences.fontName), size: CGFloat(Float(userPreferences.fontSize))))
    }
}
