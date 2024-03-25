//
//  BezierPathCache.swift
//  EveryDiary
//
//  Created by t2023-m0099 on 3/25/24.
//

import UIKit

class BezierPathCache {
    static let shared = BezierPathCache()
    
    private let cache = NSCache<NSString, UIBezierPath>()
    
    private init() {}
    
    func getBezierPath(forKey key: String) -> UIBezierPath? {
        return cache.object(forKey: key as NSString)
    }
    
    func setBezierPath(_ bezierPath: UIBezierPath, forKey key: String) {
        cache.setObject(bezierPath, forKey: key as NSString)
    }
}
