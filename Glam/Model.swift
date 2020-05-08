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
    let image: String
    let path: String
}
