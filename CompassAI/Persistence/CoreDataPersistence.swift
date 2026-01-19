//
//  CoreDataPersistence.swift
//  Compass AI V2
//
//  Created by Steve on 9/26/25.

import CoreData

// TODO: Make sure that the cateogry of each query is saved correctly.
final class CoreDataPersistence {
    static let shared = CoreDataPersistence()

    let container: NSPersistentContainer
    var viewContext: NSManagedObjectContext { container.viewContext }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Model") // matches .xcdatamodeld name

        if inMemory {
            let d = NSPersistentStoreDescription()
            d.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [d]
        }
    
        // Data model migration boilerplate
        if let description = container.persistentStoreDescriptions.first {
            // Enable Automatic Migration
            description.shouldMigrateStoreAutomatically = true
            // Enable Mapping Inference
            description.shouldInferMappingModelAutomatically = true
        }

        // Merge changes from background contexts into the UI context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved Core Data error: \(error), \(error.userInfo)")
            }
        }

        // Modern constraint validation & undo if you like:
        container.viewContext.undoManager = nil
    }
 
}
