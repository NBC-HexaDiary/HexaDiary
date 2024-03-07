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
    
    deinit {
        listener?.remove()
    }
    
    // 사용자 ID 가져오기
    func getUserID() -> String? {
        if let currentUser = Auth.auth().currentUser {
            // 현재 사용자가 로그인되어 있는 경우
            return currentUser.uid
        } else {
            // 익명으로 로그인한 경우
            if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
                return currentUser.uid
            } else {
                return nil
            }
        }
    }
    
    // 익명으로 사용자 인증하기
    func authenticateAnonymouslyIfNeeded(completion: @escaping (Error?) -> Void) {
        // 이미 사용자가 로그인되어 있는지 확인
        if Auth.auth().currentUser != nil {
            // 이미 로그인된 상태이므로 추가 인증이 필요하지 않음
            completion(nil)
        } else {
            // 익명으로 로그인
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
    
    // 익명 사용자를 영구 계정으로 전환
    func convertAnonymousUserToPermanentAccount(idToken: String, accessToken: String, completion: @escaping (Error?) -> Void) {
        // 현재 사용자 확인
        guard let user = Auth.auth().currentUser else {
            // 사용자가 인증되어 있지 않음
            let error = NSError(domain: "Auth Error", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not authenticated."])
            completion(error)
            return
        }
        
        // 익명 사용자를 영구 계정으로 전환
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        user.link(with: credential) { result, error in
            if let error = error {
                // 전환 실패
                completion(error)
            } else {
                // 전환 성공
                completion(nil)
            }
        }
    }
    
    // 일기 추가
    func addDiary(diary: DiaryEntry, completion: @escaping (Error?) -> Void) {
        // 익명으로 사용자 인증하기
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
            
            // 날씨 정보 가져오기
            weatherService.getWeather { result in
                
                // 날씨 정보 가져오기에 실패하더라도 일기는 추가됩니다.
                // 날씨 정보를 가져올 수 없는 경우에 대비하여 기본값을 "Unknown"으로 설정
                var weatherDescription = "Unknown"
                
                if case .success(let weatherResponse) = result {
                    // 날씨 정보에서 날씨 설명 가져오기
                    weatherDescription = weatherResponse.weather.first?.description ?? "Unknown"
                }
                
                // 다이어리에 날씨 정보 추가
                var diaryWithWeather = diary
                
                diaryWithWeather.weather = weatherDescription
                
                // 다이어리 추가
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
                            // 일기가 추가된 후에는 일기 리스트를 업데이트합니다.
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
    
    // 다이어리 조회
    func fetchDiaries(completion: @escaping ([DiaryEntry]?, Error?) -> Void) {
        // 사용자가 로그인되어 있는지 확인
        guard let userID = getUserID() else {
            completion([], nil)
            return
        }
        
        listener = db.collection("users").document(userID).collection("diaries").order(by: "dateString").addSnapshotListener { querySnapshot, error in
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
        // Firestore에서 일기를 가져오는 코드
        //        db.collection("users").document(userID).collection("diaries").order(by: "dateString").getDocuments { (querySnapshot, error) in
        //            if let error = error {
        //                print("Error getting documents: \(error)")
        //                completion(nil, error)
        //            } else {
        //                var diaries = [DiaryEntry]()
        //                for document in querySnapshot!.documents {
        //                    if let diary = try? document.data(as: DiaryEntry.self) {
        //                        diaries.append(diary)
        //                    }
        //                }
        //                completion(diaries, nil) // 조회된 일기들을 completion handler로 반환
        //            }
        //        }
    }
    
    // 다이어리 실시간 감지
    // 수정이 필요합니다 -> 사용 안함 -> 조회에서 사용하는걸로..
    //    func observeDiariesRealTime(completion: @escaping ([DiaryEntry]?, Error?) -> Void) {
    //        guard let userID = getUserID() else {
    //            completion(nil, NSError(domain: "Auth Error", code: 401, userInfo: nil))
    //            return
    //        }
    //        listener = db.collection("users").document(userID).collection("diaries").order(by: "dateString").addSnapshotListener { querySnapshot, error in
    //            if let error = error {
    //                print("Error listening for real-time updates: \(error)")
    //                completion(nil, error)
    //            } else {
    //                var diaries = [DiaryEntry]()
    //                for document in querySnapshot!.documents {
    //                    if let diary = try? document.data(as: DiaryEntry.self) {
    //                        diaries.append(diary)
    //                    }
    //                }
    //                completion(diaries, nil)
    //            }
    //        }
    //    }
    
    // 다이어리 삭제
    func deleteDiary(diaryID: String, imageURL: String?, completion: @escaping (Error?) -> Void) {
        guard let userID = getUserID() else {
            completion(NSError(domain: "Auth Error", code: 401, userInfo: nil))
            return
        }
        
        // Firebase Firestore에서 일기 삭제
        db.collection("users").document(userID).collection("diaries").document(diaryID).delete { error in
            if let error = error {
                print("Error deleting document: \(error)")
                completion(error)
            } else {
                // 일기 삭제에 성공하면 이미지를 Firebase Storage에서 삭제
                if let imageURL = imageURL {
                    FirebaseStorageManager.deleteImage(urlString: imageURL) { error in
                        if let error = error {
                            print("Error deleting image from Firebase Storage: \(error)")
                        }
                        // 이미지 삭제 성공 또는 실패에 관계없이 일기 삭제 완료 메시지를 반환
                        completion(nil)
                    }
                } else {
                    // 이미지 URL이 없으면 이미지를 삭제할 필요가 없으므로 완료 메시지를 반환
                    completion(nil)
                }
            }
        }
    }
    
    func deleteUserData(for userID: String) {
        // 사용자의 일기 삭제
        db.collection("users").document(userID).collection("diaries").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error deleting user's diaries: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    let diaryData = document.data()
                    if let imageURL = diaryData["imageURL"] as? String {
                        // 이미지 URL이 있다면 이미지 삭제
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
        
        // 사용자 문서 삭제
        db.collection("users").document(userID).delete { error in
            if let error = error {
                print("Error deleting user document: \(error)")
            } else {
                print("User document successfully deleted.")
            }
        }
    }
    
    // 다이어리 업데이트
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
//익명 사용자를 영구 계정으로 전환
//DiaryManager.shared.convertAnonymousUserToPermanentAccount(idToken: idToken, accessToken: user.accessToken.tokenString) { error in
//    if let error = error {
//        print("Error converting anonymous user to permanent account: \(error.localizedDescription)")
//    } else {
//        print("Anonymous user converted to permanent account successfully")
//    }
//}
