//
//  ServerManager.swift
//  llama-experiment-2
//
//  Created by Katya Raman on 9/22/23.
//

import Foundation
import SwiftUI
import PythonKit
import AppKit
import Security

class ServerManager {
    static let shared = ServerManager()
    private var task: Process?
    private var pipTask: Process?

    private init() {print("hi")}

    func startServer(pythonScriptsPath: String) {
        print("Entered Start Server")
        print("pythonScriptsPath: \(pythonScriptsPath)")
//        if pipTask == nil {
//            print("Installing requirements")
//            pipTask = Process()
//            pipTask?.launchPath = pythonScriptsPath
//            pipTask?.arguments = ["pip3", "install", "-r", "server_requirements.txt"]
//            pipTask?.launch()
//        }
        if task == nil {
            print("Starting Server")
            task = Process()
            task?.launchPath = pythonScriptsPath
            task?.arguments = ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
            print("TASK: \(task.debugDescription)")
            task?.launch()
            
        }
    }
}
