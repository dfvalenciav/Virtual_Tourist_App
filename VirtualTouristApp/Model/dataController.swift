//
//  dataController.swift
//  VirtualTouristApp
//
//  Created by Daniel Felipe Valencia Rodriguez on 10/06/22.
//

import Foundation
import CoreData

class dataController {

    static let shared = dataController()
    let persistenceContainer:NSPersistentContainer
    var viewContext:NSManagedObjectContext {
        return persistenceContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext!
    init() {
        persistenceContainer = NSPersistentContainer(name: "VirtualTouristApp")
        backgroundContext = persistenceContainer.newBackgroundContext()
    }
    
    func configureContexts() {
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistenceContainer.loadPersistentStores { (storeDescription, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.autoSaveViewContext()
            self.configureContexts()
            completion?()
        }
    }
}

extension dataController {
    func autoSaveViewContext(interval:TimeInterval = 30) {
        print("autosaving")
        guard interval > 0 else {
            print("cannot set negative autosave interval")
            return
        }
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
}
