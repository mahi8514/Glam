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
