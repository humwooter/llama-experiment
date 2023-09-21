//
//  Chat+CoreDataProperties.swift
//  llama-experiment-2
//
//  Created by Katya Raman on 9/5/23.
//
//

import Foundation
import CoreData


extension Chat {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Chat> {
        return NSFetchRequest<Chat>(entityName: "Chat")
    }

    @NSManaged public var chatName: String?
    @NSManaged public var modelPath: String?
    @NSManaged public var modelName: String?
    @NSManaged public var chatHistory: [String]?
    @NSManaged public var id: UUID?
    @NSManaged public var lastMessageDate: Date?
    @NSManaged public var relationship: NSSet?
    

}

// MARK: Generated accessors for relationship
extension Chat {

    @objc(addRelationshipObject:)
    @NSManaged public func addToRelationship(_ value: Message)

    @objc(removeRelationshipObject:)
    @NSManaged public func removeFromRelationship(_ value: Message)

    @objc(addRelationship:)
    @NSManaged public func addToRelationship(_ values: NSSet)

    @objc(removeRelationship:)
    @NSManaged public func removeFromRelationship(_ values: NSSet)

}

extension Chat : Identifiable {

}
