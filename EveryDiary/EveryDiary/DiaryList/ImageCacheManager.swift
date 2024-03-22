//
//  ImageCacheManager.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 3/11/24.
//

import UIKit

class ImageCacheManager {
    static let shared = ImageCacheManager()
    private init() {}
    
    private let cache = NSCache<NSString, UIImage>()
    
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    func image(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let key = url.absoluteString
        
        // 캐시에서 이미지를 찾는다.
        if let cachedImage = image(forKey: key) {
            completion(cachedImage)
            return
        }        
        // 이미지가 캐시에 없으면 웹에서 이미지를 다운로드.
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let downloadedImage = UIImage(data: data), error == nil else {
                print("Failed to download image from \(url): \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            // 다운로드한 이미지를 캐시에 저장
            self.setImage(downloadedImage, forKey: key)
            DispatchQueue.main.async {
                completion(downloadedImage)
            }
        }.resume()
    }
}
