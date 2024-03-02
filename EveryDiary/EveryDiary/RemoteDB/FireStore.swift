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
    private var listener: ListenerRegistration?
    
    deinit {
        listener?.remove()
    }
    
    // 로그인 상태 확인
    func isUserLoggedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }
    
    // 일기 추가 (비로그인)
    func addDiaryLocally(diary: DiaryEntry) {
        var localDiaries = UserDefaults.standard.array(forKey: "LocalDiaries") as? [Data] ?? []
        do {
            let data = try JSONEncoder().encode(diary)
            localDiaries.append(data)
            UserDefaults.standard.set(localDiaries, forKey: "LocalDiaries")
        } catch {
            print("Error encoding diary: \(error)")
        }
    }
    
    // 로그인 후 파이어스토어에 일기 추가
    func addDiariesFromLocalToFirestore() {
        guard let user = Auth.auth().currentUser else {
            return
        }
        let localDiaries = UserDefaults.standard.array(forKey: "LocalDiaries") as? [Data] ?? []
        
        for data in localDiaries {
            do {
                let diary = try JSONDecoder().decode(DiaryEntry.self, from: data)
                let userDiariesCollection = db.collection("users").document(user.uid).collection("diaries")
                _ = try userDiariesCollection.addDocument(from: diary)
            } catch {
                print("Error decoding or uploading diary: \(error)")
            }
        }
        
        // 업로드한 일기를 로컬에서 삭제
        UserDefaults.standard.removeObject(forKey: "LocalDiaries")
    }
    
    // 사용자 ID 가져오기
    private func getUserID() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    // 다이어리 추가
    func addDiary(diary: DiaryEntry, completion: @escaping (Error?) -> Void) {
        // 비로그인 상태에서 로컬에 추가
        if Auth.auth().currentUser == nil {
            addDiaryLocally(diary: diary)
            completion(nil)
            return
        }
        
        // 로그인된 상태에서는 파이어스토어에 바로 추가
        // WeatherService 인스턴스 생성
        let weatherService = WeatherService()
        
        // 날씨 정보 가져오기
        weatherService.getWeather { result in
            switch result {
            case .success(let weatherResponse):
                // 날씨 정보에서 날씨 설명 가져오기
                let weatherDescription = weatherResponse.weather.first?.description ?? "Unknown"
                
                // 다이어리에 날씨 정보 추가
                var diaryWithWeather = diary
                diaryWithWeather.weather = weatherDescription
                // 다른 날씨정보를 추가하려면 모델을 추가합시다
                
                // 사용자 ID 가져오기
                guard let userID = self.getUserID() else {
                    completion(NSError(domain: "Auth Error", code: 401, userInfo: nil))
                    // 로그인되지 않은 상태에서는 일기를 로컬에만 저장
                    self.addDiaryLocally(diary: diary)
                    completion(nil)
                    return
                }
                
                // 다이어리 추가
                var newDiaryWithUserID = diaryWithWeather
                newDiaryWithUserID.userID = userID
                let documentReference = self.db.collection("users").document(userID).collection("diaries").document()
                newDiaryWithUserID.id = documentReference.documentID
                do {
                    try documentReference.setData(from: newDiaryWithUserID) { error in
                        completion(error)
                    }
                } catch {
                    print("Error adding document: \(error)")
                    completion(error)
                }
                
            case .failure:
                // 날씨 정보를 가져오지 못할 경우 기본값으로 다이어리 추가
                // 사용자 ID 가져오기
                guard let userID = self.getUserID() else {
                    completion(NSError(domain: "Auth Error", code: 401, userInfo: nil))
                    // 로그인되지 않은 상태에서는 일기를 로컬에만 저장
                    self.addDiaryLocally(diary: diary)
                    completion(nil)
                    return
                }
                
                // 다이어리 추가
                var newDiaryWithUserID = diary
                newDiaryWithUserID.userID = userID
                let documentReference = self.db.collection("users").document(userID).collection("diaries").document()
                newDiaryWithUserID.id = documentReference.documentID
                do {
                    try documentReference.setData(from: newDiaryWithUserID) { error in
                        completion(error)
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
        guard let userID = getUserID() else {
            // 비로그인 상태에서는 로컬에 저장된 일기를 가져옴
            let localDiaries = UserDefaults.standard.array(forKey: "LocalDiaries") as? [Data] ?? []
            var diaries: [DiaryEntry] = []
            for data in localDiaries {
                do {
                    let diary = try JSONDecoder().decode(DiaryEntry.self, from: data)
                    diaries.append(diary)
                } catch {
                    print("Error decoding local diary: \(error)")
                }
            }
            completion(diaries, nil)
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
    
    // 다이어리 실시간 감지
    // 수정이 필요합니다 -> 사용 안함
    func observeDiariesRealTime(completion: @escaping ([DiaryEntry]?, Error?) -> Void) {
        guard let userID = getUserID() else {
            completion(nil, NSError(domain: "Auth Error", code: 401, userInfo: nil))
            return
        }
        listener = db.collection("users").document(userID).collection("diaries").order(by: "dateString").addSnapshotListener { querySnapshot, error in
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
    
    // 다이어리 삭제
    func deleteDiary(diaryID: String, completion: @escaping (Error?) -> Void) {
        guard let userID = getUserID() else {
            completion(NSError(domain: "Auth Error", code: 401, userInfo: nil))
            return
        }
        db.collection("users").document(userID).collection("diaries").document(diaryID).delete { error in
            if let error = error {
                print("Error deleting document: \(error)")
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    func deleteAllDiary() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is currently signed in.")
            return
        }
        let userDocRef = db.collection("users").document(userID)
        
        userDocRef.delete { error in
            if let error = error {
                print("Error deleting user document from Firestore: \(error.localizedDescription)")
            } else {
                print("User document successfully deleted from Firestore.")
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

// 날씨 데이터 추가하기
// addDiary에 추가했는데 혹시 모르니 일단 킵
//extension DiaryManager {
//    func addWeatherToDiary(diary: DiaryEntry, completion: @escaping (DiaryEntry) -> Void) {
//        // WeatherService 인스턴스 생성
//        let weatherService = WeatherService()
//
//        // 날씨 정보 가져오기
//        weatherService.getWeather { result in
//            switch result {
//            case .success(let weatherResponse):
//                // 날씨 정보에서 날씨 설명 가져오기
//                let weatherDescription = weatherResponse.weather.first?.description ?? "Unknown"
//
//                // 다이어리에 날씨 정보 추가
//                var diaryWithWeather = diary
//                diaryWithWeather.weather = weatherDescription
//
//                // 완성된 다이어리 반환
//                completion(diaryWithWeather)
//
//            case .failure:
//                // 날씨 정보를 가져오지 못할 경우 기존 다이어리 반환
//                completion(diary)
//            }
//        }
//    }
//}
