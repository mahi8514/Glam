//
//  GlamService.swift
//  Glam
//
//  Created by Mahin Ibrahim on 09/05/2020.
//  Copyright © 2020 Mahi. All rights reserved.
//

import Foundation
import Moya

enum GlamService {
    case categories
}

extension GlamService: TargetType {
    var baseURL: URL {
        return "https://pastebin.com/raw".url!
    }
    
    var path: String {
        switch self {
        case .categories: return "/HpSAiSBf"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .categories: return .get
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .categories: return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        nil
    }
    
    
}
