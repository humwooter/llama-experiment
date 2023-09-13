//
//  Message+CoreDataProperties.swift
//  llama-experiment-2
//
//  Created by Katya Raman on 9/5/23.
//
//

import Foundation
import CoreData


extension Message {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Message> {
        return NSFetchRequest<Message>(entityName: "Message")
    }

    @NSManaged public var timestamp: Date?
    @NSManaged public var content: String?
    @NSManaged public var isSender: Bool
    @NSManaged public var id: UUID?
    @NSManaged public var relationship: Chat?

}

extension Message : Identifiable {

}
