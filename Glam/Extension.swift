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
import Kingfisher

extension Reachability {
    var isConnected: Bool { connection != .unavailable }
}

extension String {
    var url: URL? {
        return URL(string: self)
    }
}

extension URLSession {
    func adaptiveLoader(regularURL: URL, lowDataURL: URL) -> AnyPublisher<Data, Error> {
        var request = URLRequest(url: regularURL)
        request.allowsConstrainedNetworkAccess = false
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryCatch { error -> URLSession.DataTaskPublisher in
                guard error.networkUnavailableReason == .constrained else { throw error }
                return URLSession.shared.dataTaskPublisher(for: lowDataURL)
        }
        .tryMap { data, response -> Data in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw GlamAPIError.genericError }
            return data
        }
        .eraseToAnyPublisher()
    }
}

public protocol OptionalType {
    associatedtype Wrapped
    var value: Wrapped? { get }
}

extension Optional: OptionalType {
    public var value: Wrapped? {
        return self
    }
}

extension Publisher {
    func apply<Section, Item>(to dataSource: UICollectionViewDiffableDataSource<Section, Item>) -> AnyCancellable where Output == NSDiffableDataSourceSnapshot<Section, Item>, Failure == Never {
        sink { snapshot in
            dataSource.apply(snapshot)
        }
    }
    func apply<Section, Item>(to dataSource: UITableViewDiffableDataSource<Section, Item>) -> AnyCancellable where Output == NSDiffableDataSourceSnapshot<Section, Item>, Failure == Never {
        sink { snapshot in
            dataSource.apply(snapshot)
        }
    }
    
    func setKfImage<T>(to imageView: T) -> AnyCancellable where T: UIImageView, Output == URL, Failure == Never {
        sink { imageView.kf.setImage(with: $0, placeholder: UIImage(named: "image-placeholder")) }
    }
}

public extension Publisher where Self.Output: OptionalType {
    func filterNil() -> AnyPublisher<Self.Output.Wrapped, Self.Failure> {
        return self.flatMap { element -> AnyPublisher<Self.Output.Wrapped, Self.Failure> in
            guard let value = element.value
                else { return Empty(completeImmediately: false).setFailureType(to: Self.Failure.self).eraseToAnyPublisher() }
            return Just(value).setFailureType(to: Self.Failure.self).eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}


public extension Publisher where Failure: Error {
    func trackError(errorss: PassthroughSubject<Error, Never>) -> AnyPublisher<Output, Failure> {
        return handleEvents(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                errorss.send(error)
            }
        }).eraseToAnyPublisher()
    }
}
