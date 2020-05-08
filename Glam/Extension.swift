//
//  Extension.swift
//  Glam
//
//  Created by Mahin Ibrahim on 08/05/2020.
//  Copyright © 2020 Mahi. All rights reserved.
//

import Foundation

extension Reachability {
    var isConnected: Bool { connection != .unavailable }
}
