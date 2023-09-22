//
//  SettingsView.swift
//  llama-experiment-2
//
//  Created by Katya Raman on 9/7/23.
//

import Foundation
import SwiftUI
import CoreData
import AppKit


class UserPreferences: ObservableObject {
    
    @Published var openAIKey: String {
        didSet {
            saveToKeychain(key: "OpenAI_API_Key", data: Data(openAIKey.utf8))
        }
    }
    
    
    @Published var accentColor: Color {
        didSet {
            UserDefaults.standard.setColor(color: accentColor, forKey: "accentColor")
        }
    }
    
    
    @Published var fontSize: CGFloat {
        didSet {
            UserDefaults.standard.set(fontSize, forKey: "fontSize")
        }
    }
    @Published var fontName: String {
        didSet {
            UserDefaults.standard.set(fontName, forKey: "fontName")
        }
    }
    
    
    init() {
        self.accentColor = UserDefaults.standard.color(forKey: "accentColor") ?? Color.blue
        self.fontSize = CGFloat(UserDefaults.standard.float(forKey: "fontSize")) != 0.0 ? CGFloat(UserDefaults.standard.float(forKey: "fontSize")) : CGFloat(16)
        self.fontName = UserDefaults.standard.string(forKey: "fontName") ?? "seif"
        if let data = loadFromKeychain(key: "OpenAI_API_Key") {
            self.openAIKey = String(data: data, encoding: .utf8) ?? ""
        } else {
            self.openAIKey = ""
        }
    }
}

extension UserDefaults {
    func setColor(color: Color, forKey key: String) {
        let nsColor = NSColor(color)
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false) {
            set(data, forKey: key)
        }
    }
    
    func color(forKey key: String) -> Color? {
        guard let data = data(forKey: key),
              let nsColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? NSColor
        else { return nil }
        
        return Color(nsColor)
    }
}

struct SettingsView: View {
    @EnvironmentObject var userPreferences: UserPreferences
    let fonts = ["Helvetica Neue", "Times New Roman", "Courier New", "American Typewriter", "Bradley Hand"]
    
    //    @Binding var pythonScriptsPath: String
    @State private var openAIKey: String? = {
        if let data = loadFromKeychain(key: "OpenAI_API_Key") {
            return String(data: data, encoding: .utf8)
        } else {
            return nil
        }
    }()
    
    @State private var enteredKey: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Accent Color")) {
                ColorPicker("Accent Color", selection: $userPreferences.accentColor)
            }
            Section(header: Text("Font Size")) {
                Slider(value: $userPreferences.fontSize, in: 10...30, step: 1, label: { Text("Font Size") })
            }
            Picker("Font Type", selection: $userPreferences.fontName) {
                ForEach(fonts, id: \.self) { font in
                    Text(font).tag(font)
                        .font(.custom(font, size: userPreferences.fontSize))
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            
            //             Section(header: Text("API Keys")) {
            //                 SecureField("OpenAI Key", text: $enteredKey) {
            //                     print("SETTING OPENAI KEY!")
            //                     saveToKeychain(key: "OpenAI_API_Key", data: Data(enteredKey.utf8))
            //                     openAIKey = enteredKey
            //                 }
            // //                SecureField("OpenAI Key", text: $enteredKey, onCommit: {
            // //                    saveToKeychain(key: "OpenAI_API_Key", data: Data(enteredKey.utf8))
            // //                    openAIKey = enteredKey
            // //                })
            //             }
            Section(header: Text("API Keys")) {
                SecureField("OpenAI Key", text: $userPreferences.openAIKey)
            }
            
            
        }.formStyle(.grouped)
    }
    
    
}
