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
    static func uploadImage(image: [UIImage], pathRoot: String, completion: @escaping ([URL]?) -> Void) {
        var uploadedURL: [URL] = []
        let dispatchGroup = DispatchGroup()
        for image in image {
            guard let imageData = image.jpegData(compressionQuality: 0.4) else {
                completion(nil)
                return
            }
            let metaData = StorageMetadata()
            metaData.contentType = "image/jpeg"
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
    
    static func downloadImage(urlString: String, completion: @escaping (UIImage?) -> Void) {
        let storageReference = Storage.storage().reference(forURL: urlString)
        let megaByte = Int64(1 * 1024 * 1024)
        
        storageReference.getData(maxSize: megaByte) { data, error in
            guard let imageData = data else {
                completion(nil)
                return
            }
            completion(UIImage(data: imageData))
        }
    }
    
    static func deleteImage(urlString: String, completion: @escaping (Error?) -> Void) {
        let storageRef = Storage.storage().reference(forURL: urlString)
        
        storageRef.delete { error in
            completion(error)
        }
    }
}
