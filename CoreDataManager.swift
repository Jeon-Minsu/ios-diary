//
//  CoreDataManager.swift
//  Diary
//
//  Created by 전민수 on 2022/08/19.
//

import UIKit
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {
        
    }
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    let persistentContainer: NSPersistentContainer = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        return appDelegate.persistentContainer
    }()
    
    func saveDiary(data: DiaryData) {
        let diary = Diary(context: persistentContainer.viewContext)
        
        diary.setValue(data.title, forKey: "title")
        diary.setValue(data.body, forKey: "body")
        diary.setValue(data.createdAt, forKey: "createdAt")

        appDelegate.saveContext()
    }
    
    func saveDiary(title: String, body: String, createdAt: Date) {
        let diary = Diary(context: persistentContainer.viewContext)
        
        diary.setValue(title, forKey: "title")
        diary.setValue(body, forKey: "body")
        diary.setValue(createdAt, forKey: "createdAt")

        appDelegate.saveContext()
    }
    
    func fetch() -> [Diary] {
        guard let contact  = try? persistentContainer.viewContext.fetch(Diary.fetchRequest()) as? [Diary] else {
            return []
        }
        
        return contact
    }
    
//    func fetchDiary() {
//        do {
//            guard let diary = try persistentContainer.viewContext.fetch(Diary.fetchRequest()) as? [Diary] else {
//                return
//            }
//
//            diary.forEach {
//                print($0.title)
//            }
//        } catch {
//            print(error.localizedDescription)
//        }
//    }
    
//    let request: NSFetchRequest<Contact> = Contact.
//    let fetchResult = PersistenceManager.shared.fetch(request: request) // [Contact]
//
    func fetch<T: NSManagedObject>(request: NSFetchRequest<T>) -> [T] {
        do {
            let fetchResult = try persistentContainer.viewContext.fetch(request)
            return fetchResult
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
    

    func delete(title: String) {
        let fetchedData = fetch()
        let data = fetchedData.filter { $0.title == title }
                
        persistentContainer.viewContext.delete(data.last!)
        
        do {
            try self.persistentContainer.viewContext.save()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func delete(_ diary: Diary) {
        let fetchRequest: NSFetchRequest<Diary> = NSFetchRequest(entityName: "Diary")
        fetchRequest.predicate = NSPredicate(format: "title == %@", diary.title ?? "")
        
        do {
            guard let diary = try persistentContainer.viewContext.fetch(fetchRequest).last else { return }
            persistentContainer.viewContext.delete(diary)
        } catch {
            fatalError()
        }
        
        do {
            try persistentContainer.viewContext.save()
        } catch {
            print(error)
        }
    }
    
    func update(title: String, body: String, createdAt: Date) {
        
        let request = NSFetchRequest<Diary>(entityName: "Diary")
        request.predicate = NSPredicate(format: "createdAt = %@", createdAt as NSDate)
        
        do {
            guard let fetchedData = try persistentContainer.viewContext.fetch(request).first else {
                return
            }
            
            fetchedData.title = title
            fetchedData.body = body
            
            appDelegate.saveContext()
            
        } catch {
            print(error)
        }
    }

}

struct DiaryData: Hashable {
    let title: String
    let body: String
    let createdAt: Date
}

