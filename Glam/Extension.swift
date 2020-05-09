//
//  Extension.swift
//  Glam
//
//  Created by Mahin Ibrahim on 08/05/2020.
//  Copyright © 2020 Mahi. All rights reserved.
//

import Foundation
import UIKit
import Combine
import Moya

extension Reachability {
    var isConnected: Bool { connection != .unavailable }
}

extension String {
    var url: URL? {
        return URL(string: self)
    }
}

extension MoyaProviderType {
    
//    func requestPublisher(_ token: Target, callbackQueue: DispatchQueue? = nil) -> AnyPublisher<Response, MoyaError> {
//        return AnyPublisher { [weak self] subscriber in
//            let cancel = self?.request(token, callbackQueue: callbackQueue, progress: nil) { result in
//                switch result {
//                case let .success(response): subscriber(.value(response))
//                case let .failure(error): subscriber(.failure(error))
//                }
//            }
//            return subscriber(.finished) { cancel?.cancel() }
//        }
//    }
    
//    func requestPublisher(_ token: Target, callbackQueue: DispatchQueue? = nil) -> AnyPublisher<Response, MoyaError> {
//        return MoyaPublisher { [weak self] subscriber in
//            return self?.request(token, callbackQueue: callbackQueue, progress: nil) { result in
//                switch result {
//                case let .success(response):
//                    _ = subscriber.receive(response)
//                    subscriber.receive(completion: .finished)
//                case let .failure(error): subscriber.receive(completion: .failure(error))
//                }
//            }
//
//        }.eraseToAnyPublisher()
//    }
    
    
    func requestPublisher(_ token: Target, callbackQueue: DispatchQueue? = nil) -> Future<Response, MoyaError> {
        return Future { [weak self] promise in
            _ = self?.request(token, callbackQueue: callbackQueue, progress: nil) { result in
                switch result {
                case let .success(response): promise(.success(response))
                case let .failure(error): promise(.failure(error))
                }
            }
        }
    }
}


//class MoyaPublisher<Output>: Publisher {
//
//    internal typealias Failure = MoyaError
//
//    private class Subscription: Combine.Subscription {
//
//        private let cancellable: Moya.Cancellable?
//
//        init(subscriber: AnySubscriber<Output, MoyaError>, callback: @escaping (AnySubscriber<Output, MoyaError>) -> Moya.Cancellable?) {
//            self.cancellable = callback(subscriber)
//        }
//
//        func request(_ demand: Subscribers.Demand) {
//            // We don't care for the demand right now
//        }
//
//        func cancel() {
//            cancellable?.cancel()
//        }
//    }
//
//    private let callback: (AnySubscriber<Output, MoyaError>) -> Moya.Cancellable?
//
//    init(callback: @escaping (AnySubscriber<Output, MoyaError>) -> Moya.Cancellable?) {
//        self.callback = callback
//    }
//
//    internal func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
//        let subscription = Subscription(subscriber: AnySubscriber(subscriber), callback: callback)
//        subscriber.receive(subscription: subscription)
//    }
//}
