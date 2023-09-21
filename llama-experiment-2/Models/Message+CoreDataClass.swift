//
//  Message+CoreDataClass.swift
//  llama-experiment-2
//
//  Created by Katya Raman on 9/5/23.
//
//

import Foundation
import CoreData

@objc(Message)
public class Message: NSManagedObject, Codable {
    
    required public convenience init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderConfigurationError.missingManagedObjectContext
          }

          self.init(context: context)

        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try values.decodeIfPresent(UUID.self, forKey: .id)
        content = try values.decodeIfPresent(String.self, forKey: .content)
        timestamp = try values.decodeIfPresent(Date.self, forKey: .timestamp)
        isSender = try values.decodeIfPresent(Bool.self, forKey: .isSender)!
        relationship = try values.decodeIfPresent(Chat.self, forKey: .relationship)
        
        
        
    }
    
    public func encode(to encoder: Encoder) throws {
        
        print("message: \(self)")
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(content, forKey: .content)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(isSender, forKey: .isSender)
//        try container.encodeIfPresent(relationship, forKey: .relationship)
     }
    
    
    private enum CodingKeys: String, CodingKey {
        case timestamp, content, isSender, id, relationship
    }
    
//    static func create(from decoder: Decoder, in context: NSManagedObjectContext) throws -> Message {
//        let message = Message(from: context)
//
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        message.id = try values.decodeIfPresent(UUID.self, forKey: .id)
//        message.timestamp = try values.decodeIfPresent(Date.self, forKey: .timestamp)
//        message.isSender = try values.decodeIfPresent(Bool.self, forKey: .isSender) ?? false
//        // Set other attributes
//
//        return message
//    }
    
}
