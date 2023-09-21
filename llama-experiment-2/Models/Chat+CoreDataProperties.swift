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

    @NSManaged public var modelName: String?
    @NSManaged public var modelPath: String?
    @NSManaged public var chatHistory: [Message]?
    @NSManaged public var id: UUID?

}

extension Chat : Identifiable {

}
