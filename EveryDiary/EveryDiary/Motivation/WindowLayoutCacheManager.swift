//
//  WindowLayoutCacheManager.swift
//  EveryDiary
//
//  Created by t2023-m0099 on 3/27/24.
//

import UIKit

class MotivationImageCache {
    static let shared = MotivationImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    
    func getImage(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}
