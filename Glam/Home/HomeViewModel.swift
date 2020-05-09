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
        let keywordTrigger: AnyPublisher<String?, Never>
        let deleteTrigger: AnyPublisher<Void, Never>
    }
    
    struct Output {
        let title: CurrentValueSubject<String?, Never>
        let searchBarPlaceHolder: CurrentValueSubject<String?, Never>
        let items: PassthroughSubject<[CDCategory], Never>
        let loadingCompleteEvent: AnyPublisher<Void, Never>
    }
    
    private var cancellable = Set<AnyCancellable>()
    let database = Database.shared
    
    func transform(input: Input) -> Output {
        
        let title = CurrentValueSubject<String?, Never>("Home")
        let searchBarPlaceHolder = CurrentValueSubject<String?, Never>("Search Categories")
        let elements = PassthroughSubject<[CDCategory], Never>()
        let loadComplete = PassthroughSubject<Void, Never>()
        
        let keyword = input.keywordTrigger.throttle(for: .milliseconds(300), scheduler: DispatchQueue.main, latest: true)
        
        Publishers.CombineLatest(input.trigger, keyword)
            .setFailureType(to: Error.self)
            .flatMapLatest { [weak self] _, keyword -> AnyPublisher<Array<CDCategory>, Error> in
                guard let self = self else { return AnyPublisher { $0(.failure(GlamDBError.dataError)) } }
                return CDPublisher(request: self.getPredicateRequest(searchText: keyword),
                                   context: self.database.managedContext)
                    .eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { _ in
                print("Completed fetch")
            }) { elements.send($0) }
            .store(in: &cancellable)
            
        
        Publishers.Merge(input.trigger, input.pullToRefreshTrigger)
            .filter { try! Reachability().isConnected }
            .setFailureType(to: GlamAPIError.self)
            .flatMapLatest { [weak self] () -> Future<Result<[Category], GlamAPIError>, GlamAPIError> in
                guard let self = self else { return Future { $0(.failure(.genericError)) } }
                return self.getCategories()
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error): print(error.localizedDescription)
                case .finished: print("Finished")
                }
            }) {
                loadComplete.send(())
                switch $0 {
                case .success(let categories): Database.shared.save(categories: categories)
                case .failure(let error): print(error.localizedDescription)
                }
            }
            .store(in: &cancellable)
        
        input.deleteTrigger.sink { Database.shared.delete(lastOnly: true) }.store(in: &cancellable)
        
        return Output(title: title,
                      searchBarPlaceHolder: searchBarPlaceHolder,
                      items: elements,
                      loadingCompleteEvent: loadComplete.eraseToAnyPublisher())
        
    }
    
    private func getPredicateRequest(searchText: String? = nil) -> NSFetchRequest<CDCategory> {
        let request = database.fetchRequest()
        if let text = searchText, !text.isEmpty {
            request.predicate = NSPredicate(format: "name contains[c] %@", text)
        } else {
            request.predicate = nil
        }
        return request
    }
    
    func getCategories() -> Future<Result<[Category], GlamAPIError>, GlamAPIError> {
        return Future<Result<[Category], GlamAPIError>, GlamAPIError> { promise in
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
                }) { promise(.success($0.success ? .success($0.data) : .failure(.noDataFound))) }
                .store(in: &self.cancellable)
            
        }
    }
    
    deinit {
        print("Homevm deinit")
    }
    
}


enum GlamAPIError: Error, LocalizedError {
    case urlError(URLError)
    case responseError(Int)
    case decodingError(DecodingError)
    case genericError
    case noDataFound
    
    var localizedDescription: String {
        switch self {
        case .urlError(let error): return error.localizedDescription
        case .decodingError(let error): return error.localizedDescription
        case .responseError(let status): return "Bad response code: \(status)"
        case .genericError: return "An unknown error has been occured"
        case .noDataFound: return "No data found in this url"
        }
    }
}

enum GlamDBError: Error, LocalizedError {
    case dataError
    
    var localizedDescription: String {
        switch self {
        case .dataError: return "Data has error or no data found."
        }
    }
}
