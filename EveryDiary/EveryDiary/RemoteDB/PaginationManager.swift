//
//  PaginationManager.swift
//  EveryDiary
//
//  Created by Dahlia on 3/12/24.
//

import Foundation
import FirebaseFirestore

class PaginationManager<T: Decodable> {
    private var query: Query
    private var pageSize: Int
    private var lastDocumentSnapshot: DocumentSnapshot?
    private var isFetching: Bool = false
    private var documents: [T] = []
    
    var onDataFetched: (([T]) -> Void)?
    
    init(query: Query, pageSize: Int) {
        self.query = query
        self.pageSize = pageSize
    }
    
    func fetchNextPage() {
        guard !isFetching else { return }
        isFetching = true
        
        var newQuery = query.limit(to: pageSize)
        
        if let lastDocumentSnapshot = lastDocumentSnapshot {
            newQuery = newQuery.start(afterDocument: lastDocumentSnapshot)
        }
        
        newQuery.getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            self.isFetching = false
            
            if let error = error {
                print("Error fetching documents: \(error)")
                return
            }
            
            guard let snapshot = snapshot else { return }
            
            if snapshot.documents.isEmpty {
                print("No more documents")
                return
            }
            
            self.lastDocumentSnapshot = snapshot.documents.last
            
            let newItems: [T] = snapshot.documents.compactMap { document in
                if let item = try? document.data(as: T.self) {
                    return item
                } else {
                    print("Failed to parse document \(document.documentID) as \(T.self)")
                    return nil
                }
            }
            
            self.documents.append(contentsOf: newItems)
            self.onDataFetched?(self.documents)
        }
    }
}
