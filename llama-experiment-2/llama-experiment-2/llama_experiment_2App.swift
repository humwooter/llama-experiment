//
//  llama_experiment_2App.swift
//  llama-experiment-2
//
//  Created by Katya Raman on 9/5/23.
//

import SwiftUI

@main
struct llama_experiment_2App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
