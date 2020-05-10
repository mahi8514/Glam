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
