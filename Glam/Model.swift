//
//  Model.swift
//  Glam
//
//  Created by Mahin Ibrahim on 08/05/2020.
//  Copyright © 2020 Mahi. All rights reserved.
//

import Foundation

struct ResponseObject<T: Decodable>: Decodable {
    let success: Bool
    let data: Array<T>
}

struct Category: Decodable, Hashable {
    let id: Int
    let name: String
    let highResImage: String
    let lowResImage: String
    let path: String
}

enum GlamAPIError: Error, LocalizedError {
    case urlError(URLError)
    case responseError(Int)
    case decodingError(DecodingError)
    case genericError
    case noDataFound
    case dbError
    
    var localizedDescription: String {
        switch self {
        case .urlError(let error): return error.localizedDescription
        case .decodingError(let error): return error.localizedDescription
        case .responseError(let status): return "Bad response code: \(status)"
        case .genericError: return "An unknown error has been occured"
        case .noDataFound: return "No data found in this url"
        case .dbError: return "Error while fetching from core data"
        }
    }
}
