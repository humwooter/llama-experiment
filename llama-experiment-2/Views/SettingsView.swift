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

    @Binding var pythonScriptsPath: String

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

            
            Section(header: Text("Python Scripts Path")) {
                Text("Current path: \(pythonScriptsPath)")
                Button("Select Path") {
                    let newPath = selectPythonScriptsPath()
                    if let newPath = newPath {
                        pythonScriptsPath = newPath
                    }
                }
            }
        }.formStyle(.grouped)
    }

    func selectPythonScriptsPath() -> String? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            return url.path
        }
        return nil
    }
}

