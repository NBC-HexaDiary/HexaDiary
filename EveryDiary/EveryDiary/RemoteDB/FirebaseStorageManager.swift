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
    static func uploadImage(image: UIImage, pathRoot: String, completion: @escaping (URL?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.4) else { return }
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpeg"
        
        let imageName = UUID().uuidString + String(Date().timeIntervalSince1970)
        
        let firebaseReference = Storage.storage().reference().child("\(imageName)")
        firebaseReference.putData(imageData, metadata: metaData) { metaData, error in
            firebaseReference.downloadURL { url, _ in
                completion(url)
            }
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
}

//extension WriteDiaryVC {
//    func uploadImageToFirebase(image: UIImage) {
//        FirebaseStorageManager.uploadImage(image: image, pathRoot: "diary_images") { [weak self] imageUrl in
//            guard let imageUrl = imageUrl else {
//                print("Failed to upload image to Firebase Storage")
//                return
//            }
//            // 이미지 업로드 성공 시 처리할 로직 추가 (예: imageUrl을 이용하여 Firestore에 이미지 URL을 저장)
//            print("Image uploaded successfully. Image URL: \(imageUrl)")
//            
//            // DiaryEntry를 Firestore에 추가하기 위해 필요한 정보들을 모두 갖춘 상태인지 확인해야 합니다.
//            guard let title = self?.titleTextField.text,
//                  let content = self?.contentTextView.text,
//                  let selectedDate = self?.selectedDate,
//                  let selectedEmotion = self?.selectedEmotion,
//                  let selectedWeather = self?.selectedWeather else {
//                print("Failed to get necessary information to create DiaryEntry")
//                return
//            }
//            
//            // DiaryEntry 생성
//            let newDiaryEntry = DiaryEntry(title: title, content: content, date: selectedDate, emotion: selectedEmotion, weather: selectedWeather, imageURL: imageUrl.absoluteString)
//            
//            // DiaryManager를 사용해 Firestore에 저장
//            self?.diaryManager.addDiary(diary: newDiaryEntry) { error in
//                if let error = error {
//                    // 에러 처리
//                    print("Error saving diary to Firestore: \(error.localizedDescription)")
//                } else {
//                    // 에러가 없다면, 화면 닫기
//                    self?.dismiss(animated: true, completion: nil)
//                }
//            }
//        }
//    }
//}
