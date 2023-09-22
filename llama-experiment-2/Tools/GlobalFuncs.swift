//
//  GlobalFuncs.swift
//  llama-experiment-2
//
//  Created by Katya Raman on 9/22/23.
//

import Foundation
import AppKit
import SwiftUI



func selectPath() -> String? {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    
    if panel.runModal() == .OK, let url = panel.url {
        return url.path
    }
    return nil
}

func start_server() {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
    task.launch()
}

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

func saveToKeychain(key: String, data: Data) -> OSStatus {
    let query = [
        kSecClass as String: kSecClassGenericPassword as String,
        kSecAttrAccount as String: key,
        kSecValueData as String: data ] as [String : Any]
    
    SecItemDelete(query as CFDictionary)
    
    return SecItemAdd(query as CFDictionary, nil)
}

func loadFromKeychain(key: String) -> Data? {
    let query = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecReturnData as String: kCFBooleanTrue!,
        kSecMatchLimit as String: kSecMatchLimitOne ] as [String : Any]
    
    var dataTypeRef: AnyObject?
    let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
    
    if status == noErr {
        return dataTypeRef as! Data?
    } else {
        return nil
    }
}

func textColorBasedOnBackgroundColor(userPreferences: UserPreferences) -> Color {
    print("changing text color")
    let nsColor = NSColor(userPreferences.accentColor)
    let brightness = nsColor.brightnessComponent
    
    // If brightness is more than 0.5, return black color else return white color
    return brightness > 0.5 ? Color.black : Color.white
}
