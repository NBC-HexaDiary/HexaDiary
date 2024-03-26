//
//  PaginationManager.swift
//  EveryDiary
//
//  Created by Dahlia on 3/12/24.
//
import Firebase

class PaginationManager {
    private let db = Firestore.firestore()                  // Firestore 인스턴스에 대한 참조
    private var query: Query? = nil                         // Firestore 쿼리를 저장하는 변수
    private var lastDocumentSnapshot: DocumentSnapshot?     // 마지막 문서 스냅샷을 저장하는 변수
    private var listener: ListenerRegistration?             // 리스너 등록을 위한 변수
    var isDeleted: Bool = false                             // 삭제된 문서를 포함할지 여부를 결정하는 플래그
    
    // 호출될 때마다 collection.limit(to ##)만큼의 데이터를 불러오는 메서드
    func getNextPage(completion: @escaping ([DiaryEntry]?) -> Void) {
        guard let userID = DiaryManager.shared.getUserID() else {
            completion(nil)     // 유저 ID가 없는 경우 콜백을 nil과 함께 호출
            return
        }
        
        // 사용자 ID를 기반으로 일기가 저장된 컬렉션 경로를 구성
        var collection = db.collection("users")
            .document(userID)
            .collection("diaries")
            .order(by: "dateString", descending: true)      // 날짜 내림차순으로 정렬
            .whereField("isDeleted", isEqualTo: isDeleted)  // 삭제 여부에 따라 필터링
        
        // 마지막으로 조회한 문서가 있다면, 해당 문서의 다음부터 조회
        if let lastDocumentSnapshot = lastDocumentSnapshot {
            collection = collection.start(afterDocument: lastDocumentSnapshot)
        }
        
        // 최대 5개의 문서를 조회하는 쿼리 구성
        let query = collection.limit(to: 5)
        
        // 쿼리 실행 및 스냅샷 리스너 추가
        query.addSnapshotListener { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            // 오류처리
            if let error = error {
                print("Error fetching documents: \(error)")
                completion(nil)
                return
            }
            
            // 스냅샷이 nil인 경우 처리
            guard let snapshot = snapshot else {
                print("Snapshot is nil")
                completion(nil)
                return
            }
            
            // 문서 스냅샷을 DiaryEntry 객체로 변환
            let entries = snapshot.documents.compactMap { document -> DiaryEntry? in
                do {
                    let entry = try document.data(as: DiaryEntry.self)
                    return entry
                } catch {
                    print("Error decoding document: \(error)")
                    return nil
                }
            }
            
            // 마지막 문서 스냅샷 업데이트
            if let lastDocument = snapshot.documents.last {
                self.lastDocumentSnapshot = lastDocument
            }
            // 완료 콜백 호출
            completion(entries)
        }
    }
    
    func resetQuery() {
        query = nil                     // 쿼리를 nil로 초기화
        lastDocumentSnapshot = nil      // 마지막 문서 스냅샷을 nil로 초기화
    }
}
