//
//  InitialView.swift
//  llama-experiment-2
//
//  Created by Katya Raman on 9/22/23.
//

import Foundation
import SwiftUI
import PythonKit
import AppKit
import Security



struct InitialView: View {
    @State private var openAIKey: String = ""
    @EnvironmentObject var userPreferences: UserPreferences
    @Binding var pythonScriptsPath: String?
    @Binding var showingInitialView: Bool
    @State private var enteredKey: String = "wef"
    @State private var isKeySaved: Bool = false

    var body : some View {
        Form {
            if pythonScriptsPath == nil {
                Section(header: Text("Python Scripts Path")) {
                    Button("Select Path") {
                        let newPath = selectPath()
                        if let newPath = newPath {
                            pythonScriptsPath = newPath
                            checkIfDone()
                        }
                    }
                }
            }

            if userPreferences.openAIKey == nil {
                Section {
                    VStack(spacing: 20) {
                        Image(systemName: "lock.fill")
                            .resizable()
                            .frame(width: 60, height: 80)
                            .foregroundColor(.gray)

                        Text("Enter OPENAI Key")
                            .font(.title)
                            .bold()

                        HStack {
//                            TextField("OPENAI Key", text: $enteredKey, onCommit: {
//                                saveToKeychain(key: "OpenAI_API_Key", data: Data(enteredKey.utf8))
//                                openAIKey = enteredKey
//                                isKeySaved = true
//                                checkIfDone()
//                            })

                            TextField("OPENAI Key", text: $userPreferences.openAIKey, onCommit: {
                                isKeySaved = true
                                checkIfDone()
                            })
                            .textFieldStyle(.roundedBorder)
//                            .padding()

                            if isKeySaved {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }

        }
    }

//    func checkIfDone() {
//        if pythonScriptsPath != nil && openAIKey != nil {
//            ServerManager.shared.startServer(pythonScriptsPath: pythonScriptsPath!)
//            showingInitialView = false
//        }
//    }
    func checkIfDone() {
        if pythonScriptsPath != nil && userPreferences.openAIKey != "" {
            ServerManager.shared.startServer(pythonScriptsPath: pythonScriptsPath!)
            showingInitialView = false
        }
    }
}
