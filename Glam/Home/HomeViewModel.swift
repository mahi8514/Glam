//
//  HomeViewModel.swift
//  Glam
//
//  Created by Mahin Ibrahim on 28/04/2020.
//  Copyright © 2020 Mahi. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import CoreData

class HomeViewModel: ObservableObject {
    
    struct Input {
        let trigger: AnyPublisher<Void, Never>
        let pullToRefreshTrigger: AnyPublisher<Void, Never>
        let deleteTrigger: AnyPublisher<Void, Never>
    }
    
    struct Output {
        let title: CurrentValueSubject<String?, Never>
        let items: PassthroughSubject<[CDCategory], Never>
        let loadingCompleteEvent: AnyPublisher<Void, Never>
    }
    
    private var cancellable = Set<AnyCancellable>()
    
    func transform(input: Input) -> Output {
        
        let title = CurrentValueSubject<String?, Never>("Home")
        let elements = PassthroughSubject<[CDCategory], Never>()
        let loadComplete = PassthroughSubject<Void, Never>()
        
        let database = Database.shared
        CDPublisher(request: database.fetchRequest(), context: database.managedContext)
            .subscribe(on: DispatchQueue.global())
            .sink(receiveCompletion: { _ in
                print("Completed fetch")
            }) { elements.send($0) }
            .store(in: &cancellable)
        
        Publishers.Merge(input.trigger, input.pullToRefreshTrigger)
            .filter { try! Reachability().isConnected }
            .setFailureType(to: GlamAPIError.self)
            .flatMapLatest { self.getCategories() }
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error): print(error.localizedDescription)
                case .finished: print("Finished")
                }
            }) {
                loadComplete.send(())
                Database.shared.save(categories: $0)
            }
            .store(in: &cancellable)
        
        input.deleteTrigger.sink { Database.shared.delete(lastOnly: true) }.store(in: &cancellable)
        
        return Output(title: title, items: elements, loadingCompleteEvent: loadComplete.eraseToAnyPublisher())
        
    }
    
    func getCategories() -> Future<[Category], GlamAPIError> {
        return Future<[Category], GlamAPIError> { promise in
            let url = URL(string: "https://pastebin.com/raw/HpSAiSBf")!
            URLSession.shared.dataTaskPublisher(for: url)
                .map { $0.data }
                .decode(type: ResponseObject<Category>.self, decoder: JSONDecoder())
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        switch error {
                        case let urlError as URLError:
                          promise(.failure(.urlError(urlError)))
                        case let decodingError as DecodingError:
                          promise(.failure(.decodingError(decodingError)))
                        case let apiError as GlamAPIError:
                          promise(.failure(apiError))
                        default:
                          promise(.failure(.genericError))
                        }
                    }
                }) { promise(.success($0.data)) }
                .store(in: &self.cancellable)
            
        }
    }
    
    
    
}


enum GlamAPIError: Error, LocalizedError {
    case urlError(URLError)
    case responseError(Int)
    case decodingError(DecodingError)
    case genericError
    
    var localizedDescription: String {
        switch self {
        case .urlError(let error):
            return error.localizedDescription
        case .decodingError(let error):
            return error.localizedDescription
        case .responseError(let status):
            return "Bad response code: \(status)"
        case .genericError:
            return "An unknown error has been occured"
        }
    }
}
