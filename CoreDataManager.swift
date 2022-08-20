//
//  CoreDataManager.swift
//  Diary
//
//  Created by 전민수 on 2022/08/19.
//

import UIKit
import CoreData

class CoreDataManager {
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
        
        do {
            try persistentContainer.viewContext.save()
            appDelegate.saveContext()
        } catch {
            print(error.localizedDescription)
        }
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
    
    func delete(_ diary: Diary, completion: @escaping () -> Void) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Diary")
        fetchRequest.predicate = NSPredicate(format: "title == %@", diary.title ?? "")
        
        do {
            guard let diary = try persistentContainer.viewContext.fetch(fetchRequest).last as? NSManagedObject else { return }
            persistentContainer.viewContext.delete(diary)
        } catch {
            fatalError()
        }
        
        do {
            try persistentContainer.viewContext.save()
            completion()
        } catch {
            fatalError()
        }
    }

}

struct DiaryData: Hashable {
    let title: String
    let body: String
    let createdAt: Date
}

