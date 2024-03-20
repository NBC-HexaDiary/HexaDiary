//
//  FirebaseStorageManager.swift
//  EveryDiary
//
//  Created by Dahlia on 3/2/24.
//
import UIKit

import Firebase
import FirebaseStorage

class FirebaseStorageManager {
    static func uploadImage(image: [UIImage], pathRoot: String, assetIdentifier: String, captureTime: String? = nil, location: String? = nil, completion: @escaping ([URL]?) -> Void) {
        var uploadedURL: [URL] = []
        let dispatchGroup = DispatchGroup()

        for image in image {
            guard let imageData = image.jpegData(compressionQuality: 0.4) else {
                completion(nil)
                return
            }
            let metaData = StorageMetadata()
            metaData.contentType = "image/jpeg"
            
            // 촬영시간과 장소 메타데이터 추가
            var customMetadata = [String: String]()
            if let captureTime = captureTime {
                customMetadata["captureTime"] = captureTime
            }
            if let location = location {
                customMetadata["location"] = location
            }
            customMetadata["assetIdentifier"] = assetIdentifier
            metaData.customMetadata = customMetadata
            
            let imageName = "\(UUID().uuidString)_\(Date().timeIntervalSince1970)"
            let firebaseReference = Storage.storage().reference().child("\(pathRoot)/\(imageName)")
            dispatchGroup.enter()
            firebaseReference.putData(imageData, metadata: metaData) { metaData, error in
                firebaseReference.downloadURL { url, error in
                    if let downloadURL = url {
                        uploadedURL.append(downloadURL)
                        print("Image Uploaded")
                    }
                    dispatchGroup.leave()
                }

            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(uploadedURL)
        }
    }
    
    static func downloadImage(urlString: String, completion: @escaping (UIImage?, [String: String]?) -> Void) {
        let storageReference = Storage.storage().reference(forURL: urlString)
        let megaByte = Int64(1 * 2048 * 2048)
        
        storageReference.getData(maxSize: megaByte) { data, error in
            guard let imageData = data else {
                completion(nil, nil)
                return
            }
            
            // 이미지 데이터로부터 UIImage 생성
            let image = UIImage(data: imageData)
            
            // 메타데이터 가져오기
            storageReference.getMetadata { metadata, error in
                guard let metadata = metadata, error == nil else {
                    completion(image, nil)
                    return
                }
                print("storageReference.name: \(storageReference.name)")
                // 메타데이터의 customMetadata 추출
                let customMetadata = metadata.customMetadata
                completion(image, customMetadata)
            }
        }
    }
    
    static func deleteImage(urlString: String, completion: @escaping (Error?) -> Void) {
        let storageRef = Storage.storage().reference(forURL: urlString)
        
        storageRef.delete { error in
            completion(error)
        }
    }
}
