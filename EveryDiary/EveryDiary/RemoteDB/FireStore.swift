//
//  FireStore.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/23/24.
//
import Foundation

import Firebase
import FirebaseAuth
import FirebaseFirestore

class DiaryManager {
    static let shared = DiaryManager()
    let db = Firestore.firestore()
    var listener: ListenerRegistration?
    private let paginationManager = PaginationManager()
    
    deinit {
        listener?.remove()
    }
    
    //MARK: 사용자 ID 가져오기
    func getUserID() -> String? {
        if let currentUser = Auth.auth().currentUser {
            return currentUser.uid
        } else {
            if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
                return currentUser.uid
            } else {
                return nil
            }
        }
    }
    
    //MARK: 익명으로 사용자 인증하기
    func authenticateAnonymouslyIfNeeded(completion: @escaping (Error?) -> Void) {
        if Auth.auth().currentUser != nil {
            completion(nil)
        } else {
            Auth.auth().signInAnonymously { (authResult, error) in
                if let error = error {
                    print("Error signing in anonymously: \(error)")
                    completion(error)
                } else {
                    print("익명 인증 성공")
                    completion(nil)
                }
            }
        }
    }
    
    //MARK: 일기 추가
    func addDiary(diary: DiaryEntry, completion: @escaping (Error?) -> Void) {
        authenticateAnonymouslyIfNeeded { error in
            if let error = error {
                print("Error authenticating anonymously: \(error)")
                completion(error)
                return
            }
            guard let userID = self.getUserID() else {
                completion(NSError(domain: "Auth Error", code: 401, userInfo: nil))
                return
            }
            
            let weatherService = WeatherService()
            
            weatherService.getWeather { result in
                
                var weatherDescription = "Unknown"
                var weatherTemp = 0.0
                
                if case .success(let weatherResponse) = result {
                    weatherDescription = weatherResponse.weather.first?.description ?? "Unknown"
                    weatherTemp = weatherResponse.main.temp
                }
                
                var diaryWithWeather = diary
                
                diaryWithWeather.weatherDescription = weatherDescription
                diaryWithWeather.weatherTemp = weatherTemp
                
                let currentDate = Date()
                
                if !Calendar.current.isDate(diary.date, inSameDayAs: currentDate) {
                    diaryWithWeather.weatherDescription = "Unknown"
                    diaryWithWeather.weatherTemp = 0
                }
                
                var newDiaryWithUserID = diaryWithWeather
                newDiaryWithUserID.userID = userID
                let documentReference = DiaryManager.shared.db.collection("users").document(userID).collection("diaries").document()
                newDiaryWithUserID.id = documentReference.documentID
                
                do {
                    try documentReference.setData(from: newDiaryWithUserID) { error in
                        if let error = error {
                            print("Error adding document: \(error)")
                            completion(error)
                        } else {
                            self.fetchDiaries { (diaries, error) in
                                if let error = error {
                                    print("Error fetching diaries after adding a new diary: \(error)")
                                }
                            }
                            completion(nil)
                        }
                    }
                } catch {
                    print("Error adding document: \(error)")
                    completion(error)
                }
            }
        }
    }
    
    //MARK: 다이어리 조회
    func fetchDiaries(completion: @escaping ([DiaryEntry]?, Error?) -> Void) {
        guard let userID = getUserID() else {
            completion([], nil)
            return
        }
        
        listener = db.collection("users").document(userID).collection("diaries").order(by: "dateString", descending: true).addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Error listening for real-time updates: \(error)")
                completion([], error)
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
    
    //MARK: 다이어리 데이터 가져오기
    func getDiary(completion: @escaping ([DiaryEntry]?, Error?) -> Void) {
        guard let userID = getUserID() else {
            completion([], nil)
            return
        }
        
        db.collection("users").document(userID).collection("diaries").order(by: "dateString").getDocuments { (querySnapshot, error) in
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
    
    //MARK: 다이어리 삭제
    func deleteDiary(diaryID: String, imageURL: [String], completion: @escaping (Error?) -> Void) {
        guard let userID = getUserID() else {
            completion(NSError(domain: "Auth Error", code: 401, userInfo: nil))
            return
        }
        
        let dispatchGroup = DispatchGroup()
        
        for url in imageURL {
            dispatchGroup.enter()
            FirebaseStorageManager.deleteImage(urlString: url) { error in
                if let error = error {
                    print("Error deleting image from Firebase Storage: \(error)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.db.collection("users").document(userID).collection("diaries").document(diaryID).delete { error in
                if let error = error {
                    print("Error deleting document: \(error)")
                    completion(error)
                } else {
                    print("Diary document successfully deleted.")
                    completion(nil)
                }
            }
        }
    }
    
    //MARK: 회원탈퇴시 데이터 삭제
    func deleteUserData(for userID: String) {
        db.collection("users").document(userID).collection("diaries").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error deleting user's diaries: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    let diaryData = document.data()
                    if let imageURL = diaryData["imageURL"] as? String {
                        FirebaseStorageManager.deleteImage(urlString: imageURL) { error in
                            if let error = error {
                                print("Error deleting image: \(error.localizedDescription)")
                            }
                        }
                    }
                    document.reference.delete()
                }
                print("User's diaries successfully deleted.")
            }
        }
        
        db.collection("users").document(userID).delete { error in
            if let error = error {
                print("Error deleting user document: \(error)")
            } else {
                print("User document successfully deleted.")
            }
        }
    }
    
    //MARK: 다이어리 업데이트
    func updateDiary(diaryID: String, newDiary: DiaryEntry, completion: @escaping (Error?) -> Void) {
        guard let userID = getUserID() else {
            completion(NSError(domain: "Auth Error", code: 401, userInfo: nil))
            return
        }
        
        do {
            try db.collection("users").document(userID).collection("diaries").document(diaryID).setData(from: newDiary) { error in
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
