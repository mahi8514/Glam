//
//  Database.swift
//  Glam
//
//  Created by Mahin Ibrahim on 07/05/2020.
//  Copyright © 2020 Mahi. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import Combine

class Database {
    
    static let shared: Database = Database()
    let managedContext: NSManagedObjectContext
    let appDelegate: AppDelegate
    
    private init() {
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        managedContext = appDelegate.persistentContainer.viewContext
    }
    
    func save(categories: [Category]) {
        delete()
        categories.forEach {
            let category = CDCategory(context: appDelegate.persistentContainer.viewContext)
            category.id = Int16($0.id)
            category.name = $0.name
            category.highResImage = $0.highResImage
            category.lowResImage = $0.lowResImage
            category.path = $0.path
        }
        save()
    }
    
    func delete(lastOnly: Bool = false) {
        let fetchedResults: [CDCategory] = try! managedContext.fetch(fetchRequest(isAscending: false))
        if lastOnly {
            if let lastItem = fetchedResults.last { managedContext.delete(lastItem) }
        } else {
            fetchedResults.forEach { managedContext.delete($0) }
        }
        save()
    }
    
    private func save() {
        if managedContext.hasChanges {
            do { try managedContext.save() }
            catch { print(error.localizedDescription) }
        }
    }
    
    func fetchRequest(isAscending: Bool = true) -> NSFetchRequest<CDCategory> {
        let fetchRequest: NSFetchRequest<CDCategory> = CDCategory.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: isAscending)]
        return fetchRequest
    }
}

class CDPublisher<Entity>: NSObject, NSFetchedResultsControllerDelegate, Publisher where Entity: NSManagedObject {
    typealias Output = [Entity]
    typealias Failure = Error
  
    private let request: NSFetchRequest<Entity>
    private let context: NSManagedObjectContext
    private let subject: CurrentValueSubject<[Entity], Failure>
    private var resultController: NSFetchedResultsController<NSManagedObject>?
    private var subscriptions = 0
  
      init(request: NSFetchRequest<Entity>, context: NSManagedObjectContext) {
        if request.sortDescriptors == nil { request.sortDescriptors = [] }
        self.request = request
        self.context = context
        subject = CurrentValueSubject([])
        super.init()
    }
  
      func receive<S>(subscriber: S)
        where S: Subscriber, CDPublisher.Failure == S.Failure, CDPublisher.Output == S.Input {
        var start = false

        objc_sync_enter(self)
        subscriptions += 1
        start = subscriptions == 1
        objc_sync_exit(self)

        if start {
            let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context,
                                                        sectionNameKeyPath: nil, cacheName: nil)
            controller.delegate = self

            do {
                try controller.performFetch()
                let result = controller.fetchedObjects ?? []
                subject.send(result)
            } catch {
                subject.send(completion: .failure(error))
            }
            resultController = controller as? NSFetchedResultsController<NSManagedObject>
        }
        CDSubscription(fetchPublisher: self, subscriber: AnySubscriber(subscriber))
    }
  
      func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        let result = controller.fetchedObjects as? [Entity] ?? []
        subject.send(result)
    }
  
      private func dropSubscription() {
        objc_sync_enter(self)
        subscriptions -= 1
        let stop = subscriptions == 0
        objc_sync_exit(self)

        if stop {
            resultController?.delegate = nil
            resultController = nil
        }
    }

    private class CDSubscription: Subscription {
        private var fetchPublisher: CDPublisher?
        private var cancellable: AnyCancellable?

        @discardableResult
        init(fetchPublisher: CDPublisher, subscriber: AnySubscriber<Output, Failure>) {
            self.fetchPublisher = fetchPublisher

            subscriber.receive(subscription: self)

            cancellable = fetchPublisher.subject.sink(receiveCompletion: { completion in
                subscriber.receive(completion: completion)
            }, receiveValue: { value in
                _ = subscriber.receive(value)
            })
        }

        func request(_ demand: Subscribers.Demand) {}

        func cancel() {
            cancellable?.cancel()
            cancellable = nil
            fetchPublisher?.dropSubscription()
            fetchPublisher = nil
        }
    }
  
}
