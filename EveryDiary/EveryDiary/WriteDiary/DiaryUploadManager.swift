//
//  DiaryUploadManager.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 3/26/24.
//

import UIKit

//MARK: 일기, 이미지 데이터의 업로드 & 업데이트 프로세스 관리
// DiaryManager(DiaryEntry CRUD)와 FirebaseStorageManager(Image Upload, Delete, Download, URL제공)를 사용해 일기데이터를 생성, 업데이트하는 역할
class DiaryUploadManager {
    static let shared = DiaryUploadManager()
    private var retentionList = [UIViewController]()
    
    func retain(_ vc: UIViewController) {
        retentionList.append(vc)
    }
    func release(_ vc: UIViewController) {
        retentionList = retentionList.filter { $0 !== vc }
    }
    
    func uploadDairy(diaryEntry: DiaryEntry, imagesLocationInfo: [ImageLocationInfo], completion: @escaping (Bool) -> Void) {
        // 이미지 업로드 후 URL 배열 반환
        uploadImages(imagesLocationInfo) { imageURLs in
            guard !imageURLs.isEmpty else {
                completion(false)
                return
            }
            // 이미지 URL을 포함한 일기 엔트리의 생성 및 업로드
            var newDiaryEntry = diaryEntry
            newDiaryEntry.imageURL = imageURLs
            DiaryManager.shared.addDiary(diary: newDiaryEntry) { error in
                if let error = error {
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    func updateDiary(diaryID: String, diaryEntry: DiaryEntry, imagesLocationInfo: [ImageLocationInfo], existingImageURLs: [String], completion: @escaping (Bool) -> Void) {
        // 1단계: 기존 이미지 삭제
        deleteExistingImgaes(urls: existingImageURLs) {
            // 2단계: 새 이미지 업로드
            if !imagesLocationInfo.isEmpty {
                self.uploadImages(imagesLocationInfo) { newImageURLs in
                    // 3단계: 다이어리 엔트리 업데이트
                    // 업로드 된 이미지 URL을 포함하여 다이어리 엔트리 업데이트
                    var updatedDiaryEntry = diaryEntry
                    updatedDiaryEntry.imageURL = newImageURLs
                    self.updateDiaryEntry(diaryID: diaryID, updatedDiaryEntry: updatedDiaryEntry, completion: completion)
                }
            } else {
                // 3단계: 다이어리 엔트리 업데이트(no Image)
                var updatedDiaryEntry = diaryEntry
                updatedDiaryEntry.imageURL = nil
                self.updateDiaryEntry(diaryID: diaryID, updatedDiaryEntry: updatedDiaryEntry, completion: completion)
            }
        }
    }
    private func updateDiaryEntry(diaryID: String, updatedDiaryEntry: DiaryEntry, completion: @escaping (Bool) -> Void) {
        DiaryManager.shared.updateDiary(diaryID: diaryID, newDiary: updatedDiaryEntry) { error in
            if let error = error {
                print("Error updating diary entry in Firestore: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Diary entry successfully updated in Firestore.")
                completion(true)
            }
        }
    }
    private func uploadImages(_ imagesLocationInfo: [ImageLocationInfo], completion: @escaping ([String]) -> Void) {
        let dispatchGroup = DispatchGroup()
        var uploadedImageURLs = Array(repeating: String?.none, count: imagesLocationInfo.count) // URL 배열을 nil로 초기화
        
        // 이미지와 메타데이터 업로드
        print("before enter")
        for (index ,imageLocationInfo) in imagesLocationInfo.enumerated() {
            guard let assetIdentifier = imageLocationInfo.assetIdentifier else { continue }
            
            dispatchGroup.enter()
            print("dispatchGroup entered")
            // 촬영 시간과 위치 정보를 포함하여 업로드
            FirebaseStorageManager.uploadImage(
                image: [imageLocationInfo.image],
                pathRoot: "diary_images",
                assetIdentifier: assetIdentifier,
                captureTime: imageLocationInfo.captureTime,
                location: imageLocationInfo.location
            ) { urls in
                defer { dispatchGroup.leave() }
                print("Image Uploaded")
                if let url = urls?.first?.absoluteString {
                    uploadedImageURLs[index] = url              // 원본 배열의 순서에 따라 URL 저장
                    return
                }
            }
        }
        dispatchGroup.notify(queue: .main) {
            print("dispatchGroup notify")
            let orderedUploadImageURLs = uploadedImageURLs.compactMap { $0 }     // nil 값을 제거하고 URL 순서대로 정렬
            print("completion 콜백 호출 전: \(orderedUploadImageURLs)")
            completion(orderedUploadImageURLs)     // 순서대로 정렬된 URL 배열로 완료 콜백 호출
        }
    }
    private func deleteExistingImgaes(urls: [String], completion: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()
        
        for urlString in urls {
            dispatchGroup.enter()
            FirebaseStorageManager.deleteImage(urlString: urlString) { _ in
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            completion()
        }
    }
}
