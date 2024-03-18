//
//  PaginationManager.swift
//  EveryDiary
//
//  Created by Dahlia on 3/12/24.
//
import Firebase

class PaginationManager {
    private let db = Firestore.firestore()
    private var query: Query? = nil
    private var lastDocumentSnapshot: DocumentSnapshot?
    private var listener: ListenerRegistration?
    
    func getNextPage(completion: @escaping ([DiaryEntry]?) -> Void) {
        guard let userID = DiaryManager.shared.getUserID() else {
            completion(nil)
            return
        }
        
        var collection = db.collection("users")
            .document(userID)
            .collection("diaries")
            .order(by: "dateString", descending: true)
            .whereField("isDeleted", isEqualTo: false) // isDeleted가 false인 문서만 가져오기

        
        if let lastDocumentSnapshot = lastDocumentSnapshot {
            // 이전 페이지의 마지막 문서 다음부터 쿼리
            collection = collection.start(afterDocument: lastDocumentSnapshot)
        }
        
        // 페이지 크기에 따라 쿼리 제한
        let query = collection.limit(to: 5)
        
        // 쿼리 실행
        query.addSnapshotListener { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching documents: \(error)")
                completion(nil)
                return
            }
            
            guard let snapshot = snapshot else {
                print("Snapshot is nil")
                completion(nil)
                return
            }
            
            // 가져온 문서를 DiaryEntry로 변환
            let entries = snapshot.documents.compactMap { document -> DiaryEntry? in
                do {
                    let entry = try document.data(as: DiaryEntry.self)
                    return entry
                } catch {
                    print("Error decoding document: \(error)")
                    return nil
                }
            }
            
            // 마지막 문서 기록
            if let lastDocument = snapshot.documents.last {
                self.lastDocumentSnapshot = lastDocument
            }
            
            completion(entries)
        }
    }
}
