//
//  dataController.swift
//  VirtualTouristApp
//
//  Created by Daniel Felipe Valencia Rodriguez on 10/06/22.
//

import Foundation
import CoreData

class dataController {
    
    // MARK: - Properties
    static let shared = dataController(modelName: "VirtualTouristApp")
    
    private let persistentContainer: NSPersistentContainer!
    var backgroundContext: NSManagedObjectContext!
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    
    // MARK: - Initialization
    
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
        backgroundContext = persistentContainer.newBackgroundContext()
    }
    
    
    
    // MARK: - Config & Helper Functions
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { (description, error) in
            if let error = error {
                fatalError("Error in loading Persistent Stores : \(error.localizedDescription)")
            }
            
            self.setupContexts()
            self.autoSaveViewContext()
            completion?()
        }
    }
    
    private func setupContexts() {
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
    
    func saveContext() {
        if viewContext.hasChanges {
            try? viewContext.save()
        }
    }
    
    private func autoSaveViewContext(interval: TimeInterval = 5) {
        guard interval > 0 else { return }
        
        saveContext()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
    
}
