//
//  ReachabilityManager.swift
//  Glam
//
//  Created by Mahin Ibrahim on 09/05/2020.
//  Copyright © 2020 Mahi. All rights reserved.
//

import Foundation
import Combine

public func connectedToInternet() -> AnyPublisher<Bool, Never> {
    ReachabilityManager.shared.reach
}

private class ReachabilityManager {
    
    static let shared: ReachabilityManager = ReachabilityManager()
    
    fileprivate let reachability = try! Reachability()
    
    let reachSubject = PassthroughSubject<Bool, Never>()
    
    var reach: AnyPublisher<Bool, Never> {
        reachSubject.eraseToAnyPublisher()
    }
    
    private init() {
        
        reachability.whenReachable = { _ in
            DispatchQueue.main.async {
                self.reachSubject.send(true)
            }
        }
        
        reachability.whenUnreachable = { _ in
            DispatchQueue.main.async {
                self.reachSubject.send(false)
            }
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier. \(error.localizedDescription)")
        }
        
    }
    
}
