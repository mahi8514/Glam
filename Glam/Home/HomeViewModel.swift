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
import Moya
import UIKit

protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    
    func transform(input: Input) -> Output
}

class HomeViewModel: ViewModelType {
    
    struct Input {
        let trigger: AnyPublisher<Void, Never>
        let pullToRefreshTrigger: AnyPublisher<Void, Never>
        let keywordTrigger: AnyPublisher<String?, Never>
        let deleteTrigger: AnyPublisher<Void, Never>
    }
    
    struct Output {
        let title: AnyPublisher<String?, Never>
        let searchBarPlaceHolder: AnyPublisher<String?, Never>
        let snapshot: AnyPublisher<Snapshot, Never>
        let loadingCompleteEvent: AnyPublisher<Void, Never>
    }
    
    private var cancellable = Set<AnyCancellable>()
    let database = Database.shared
    let glamProvider = MoyaProvider<GlamService>()
    
    typealias Snapshot = NSDiffableDataSourceSnapshot<Int, CDCategory>
    
    func transform(input: Input) -> Output {
        
        let title = CurrentValueSubject<String?, Never>("Home")
        let searchBarPlaceHolder = CurrentValueSubject<String?, Never>("Search Categories")
        let snapshot = PassthroughSubject<Snapshot, Never>()
        let loadComplete = PassthroughSubject<Void, Never>()
        
        let keyword = input.keywordTrigger
            //.throttle(for: .microseconds(300), scheduler: DispatchQueue.main, latest: true)
            .removeDuplicates()
        
        Publishers.CombineLatest(input.trigger, keyword)
            .subscribe(on: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .flatMapLatest { [weak self] _, keyword -> AnyPublisher<Array<CDCategory>, Error> in
                guard let self = self else { return AnyPublisher { $0(.failure(GlamAPIError.genericError)) } }
                return CDPublisher(request: self.getPredicateRequest(searchText: keyword),
                                   context: self.database.managedContext)
                    .eraseToAnyPublisher()
        }
        .replaceError(with: [])
        .map {
            var snapshot = Snapshot()
            snapshot.appendSections([0])
            snapshot.appendItems($0)
            return snapshot
        }
        .subscribe(snapshot)
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
        
        return Output(title: title.eraseToAnyPublisher(),
                      searchBarPlaceHolder: searchBarPlaceHolder.eraseToAnyPublisher(),
                      snapshot: snapshot.eraseToAnyPublisher(),
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
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return Future<Result<[Category], GlamAPIError>, GlamAPIError> { promise in
            self.glamProvider.requestPublisher(.categories)
                .tryMap { dataResponse -> Data in
                    guard let httpResponse = dataResponse.response, 200...299 ~= httpResponse.statusCode else {
                        throw GlamAPIError.responseError(dataResponse.response?.statusCode ?? 500)
                    }
                    return dataResponse.data
            }
            .decode(type: ResponseObject<Category>.self, decoder: decoder)
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
            }) {
                promise(.success($0.success ? .success($0.data) : .failure(.noDataFound))) }
                .store(in: &self.cancellable)
            
        }
    }
    
    deinit {
        print("Homevm deinit")
    }
    
}
