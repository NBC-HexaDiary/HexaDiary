//
//  FireStore.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/23/24.
//

import Foundation

import Firebase
import FirebaseFirestore
//import FirebaseAuth

class DiaryManager {
    let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    deinit {
        listener?.remove()
    }
    
    //다이어리 추가
    func addDiary(diary: DiaryEntry, completion: @escaping (Error?) -> Void) {
        var newDiary = diary
//        guard let userID = Auth.auth().currentUser?.uid else {
//            completion(NSError(domain: "Auth Error", code: 401, userInfo: nil))
//            return
//        }
//        newDiary.userID = userID // 현재 사용자의 UID를 저장
//        let documentReference = db.collection("users").document(userID).collection("diaries").document() // 사용자의 UID를 기반으로 경로 설정
        let documentReference = db.collection("diaries").document() //나중에 로그인 구현되면 여긴 필요없어요
        newDiary.id = documentReference.documentID
        do {
            try documentReference.setData(from: newDiary) { error in
                completion(error)
            }
        } catch {
            print("Error adding document: \(error)")
            completion(error)
        }
    }
    
    //다이어리 조회
    func fetchDiaries(completion: @escaping ([DiaryEntry]?, Error?) -> Void) {
        db.collection("diaries").order(by: "dateString").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                completion(nil, error)
            } else {
                var diaries = [DiaryEntry]()
                for document in querySnapshot!.documents {
                    if let diary = try? document.data(as: DiaryEntry.self) {
                        diaries.append(diary)
                    }
                }
                completion(diaries, nil)
            }
        }
    }
    
    //다이어리 감지
    func observeDiariesRealTime(completion: @escaping ([DiaryEntry]?, Error?) -> Void) {
        listener = db.collection("diaries").addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Error listening for real-time updates: \(error)")
                completion(nil, error)
            } else {
                var diaries = [DiaryEntry]()
                for document in querySnapshot!.documents {
                    if let diary = try? document.data(as: DiaryEntry.self) {
                        diaries.append(diary)
                    }
                }
                completion(diaries, nil)
            }
        }
    }
    
    //다이어리 삭제
    func deleteDiary(diaryID: String, completion: @escaping (Error?) -> Void) {
        db.collection("diaries").document(diaryID).delete { error in
            if let error = error {
                print("Error deleting document: \(error)")
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    //다이어리 업데이트
    func updateDiary(diaryID: String, newDiary: DiaryEntry, completion: @escaping (Error?) -> Void) {
        do {
            try db.collection("diaries").document(diaryID).setData(from: newDiary) { error in
                if let error = error {
                    print("Error updating document: \(error)")
                    completion(error)
                } else {
                    completion(nil)
                }
            }
        } catch {
            print("Error updating document: \(error)")
            completion(error)
        }
    }
}
