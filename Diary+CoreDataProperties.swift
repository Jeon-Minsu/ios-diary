//
//  Diary+CoreDataProperties.swift
//  Diary
//
//  Created by 전민수 on 2022/08/19.
//
//

import Foundation
import CoreData


extension Diary {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Diary> {
        return NSFetchRequest<Diary>(entityName: "Diary")
    }

    @NSManaged public var title: String?
    @NSManaged public var body: String?
    @NSManaged public var createdAt: String?

}

extension Diary : Identifiable {

}
