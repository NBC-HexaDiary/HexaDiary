//
//  PaginationManager.swift
//  EveryDiary
//
//  Created by Dahlia on 3/12/24.
//
import Firebase

class PaginationManager {
    // Firebase Firestore 데이터베이스 참조
    private let db = Firestore.firestore()
    
    // 페이지당 가져올 항목 수
    private let pageSize = 5
    
    // 마지막으로 로드된 문서의 snapshot
    private var lastDocumentSnapshot: DocumentSnapshot?
    
    func getPage(){
        guard let userID = DiaryManager.shared.getUserID() else {
            return
        }
        // Construct query for first 25 cities, ordered by population
        let first = db.collection("users").document(userID).collection("diaries").order(by: "dateString", descending: true).limit(to: pageSize)

        first.getDocuments { [self] (snapshot, error) in
          guard let snapshot = snapshot else {
            print("Error retreving cities: \(error.debugDescription)")
            return
          }

          guard let lastSnapshot = snapshot.documents.last else {
            // The collection is empty.
            return
          }

          // Construct a new query starting after this document,
          // retrieving the next 25 cities.
            let next = db.collection("users").document(userID).collection("diaries").order(by: "dateString", descending: true).start(afterDocument: lastSnapshot)

          // Use the query for pagination.
          // ...
        }
    }
    
    // 다음 페이지를 가져오는 함수
//    func getNextPage(completion: @escaping ([DiaryEntry]?, Error?) -> Void) {
//        // 가져올 쿼리
//        guard let userID = DiaryManager.shared.getUserID() else {
//            completion([], nil)
//            return
//        }
//        var query = db.collection("users").document(userID).collection("diaries").order(by: "dateString", descending: true).limit(to: pageSize)
//        
//        // 마지막으로 로드된 문서 이후의 문서부터 가져오도록 설정
//        if let lastDocumentSnapshot = lastDocumentSnapshot {
//            query = query.start(afterDocument: lastDocumentSnapshot)
//        }
//        
//        // Firestore에서 데이터 가져오기
//        query.getDocuments { [weak self] (snapshot, error) in
//            guard let self = self else { return }
//            
//            if let error = error {
//                completion(nil, error)
//                return
//            }
//            
//            // 가져온 문서를 DiaryEntry로 변환
//            let entries = snapshot?.documents.compactMap { document -> DiaryEntry? in
//                do {
//                    let entry = try document.data(as: DiaryEntry.self)
//                    return entry
//                } catch {
//                    print("Error decoding document: \(error)")
//                    return nil
//                }
//            }
//            
//            // 마지막으로 로드된 문서 업데이트
//            self.lastDocumentSnapshot = snapshot?.documents.last
//            
//            completion(entries, nil)
//        }
//    }
    
    // 새로운 데이터를 가져오기 시작할 때 호출
    func resetPagination() {
        lastDocumentSnapshot = nil
    }
}
