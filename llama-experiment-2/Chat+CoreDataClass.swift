//
//  Chat+CoreDataClass.swift
//  llama-experiment-2
//
//  Created by Katya Raman on 9/5/23.
//
//

import Foundation
import CoreData

enum DecoderConfigurationError: Error {
  case missingManagedObjectContext
}

@objc(Chat)
public class Chat: NSManagedObject, Codable {
    required public convenience init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderConfigurationError.missingManagedObjectContext
          }

          self.init(context: context)
        
        
      let values = try decoder.container(keyedBy: CodingKeys.self)
        chatName = try values.decodeIfPresent(String.self, forKey: .chatName)
        modelPath = try values.decodeIfPresent(String.self, forKey: .modelPath)
        modelName = try values.decodeIfPresent(String.self, forKey: .modelName)
        chatHistory = try values.decodeIfPresent([String].self, forKey: .chatHistory)
        id = try values.decodeIfPresent(UUID.self, forKey: .id)
        lastMessageDate = try values.decodeIfPresent(Date.self, forKey: .lastMessageDate)
        relationship = try values.decode(Set<Message>?.self, forKey: .relationship) as NSSet?
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(chatName, forKey: .chatName)
        try container.encode(modelPath, forKey: .modelPath)
        try container.encode(modelName, forKey: .modelName)
        try container.encode(chatHistory, forKey: .chatHistory)
        try container.encode(id, forKey: .id)
        try container.encode(lastMessageDate, forKey: .lastMessageDate)
//        print("RELATIONSHIP: \(self.relationship)")
        
        if let relationshipSet = relationship as? Set<Message> {
            try container.encode(relationshipSet, forKey: .relationship)
        }
    }

    
      
    private enum CodingKeys: String, CodingKey {
        case chatName, modelPath, modelName, chatHistory, id, lastMessageDate, relationship
    }
    
    
}

extension CodingUserInfoKey {
    static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")!
}


