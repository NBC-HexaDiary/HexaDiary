//
//  BuildingView.swift
//  EveryDiary
//
//  Created by t2023-m0099 on 2/26/24.
//

import UIKit

import SnapKit
import Firebase
import FirebaseFirestore

protocol BuildingViewDelegate: AnyObject {
    func didUpdateDiaryCount(_ diaryCount: Int)
}

class BuildingView: UIView {
    static let shared = BuildingView()
    weak var delegate: BuildingViewDelegate?

    var buildings: [BuildingSize] = []
    
    let db = Firestore.firestore()
    var diaryDays: Set<Int> = []
    
    let backBuildingLayer = CAShapeLayer()
    let buildingLayer = CAShapeLayer()
    
    let windowSize = CGSize(width: 10, height: 22)
    let windowSpacing: CGFloat = 15
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backBuildingLayer.frame = self.bounds
        buildingLayer.frame = self.bounds
        buildings = [
            BuildingSize(position: CGPoint(x: 0, y: layer.bounds.height * 0.97),
                         size: CGSize(width: layer.bounds.width * 0.07, height: layer.bounds.height * 0.3), windowLayout: WindowLayout(columns: [[0, 1], [1, 1], [1], [1, 1], [1]])),
            
            BuildingSize(position: CGPoint(x: layer.bounds.width * 0.21, y: layer.bounds.height * 0.99),
                         size: CGSize(width: layer.bounds.width * 0.07, height: layer.bounds.height * 0.31), windowLayout: WindowLayout(columns: [[0, 1, 1], [1, 0, 1],[1, 1], [0, 1]])),
            
            BuildingSize(position: CGPoint(x: layer.bounds.width * 0.51, y: layer.bounds.height * 1.02),
                         size: CGSize(width: layer.bounds.width * 0.048, height: layer.bounds.height * 0.25), windowLayout: WindowLayout(columns: [[1, 1, 0],[0, 1, 1], [1, 0, 1], [0, 1]])),
            
            BuildingSize(position: CGPoint(x: layer.bounds.width * 0.73, y: layer.bounds.height * 1.03),
                         size: CGSize(width: (layer.bounds.width - layer.bounds.width * 0.92), height: layer.bounds.height * 0.4), windowLayout: WindowLayout(columns: [[1], [1], [1, 1, 1], [1, 1]])),
            
            BuildingSize(position: CGPoint(x: 0, y: layer.bounds.height * 0.9),
                         size: CGSize(width: layer.bounds.width * 0.045, height: layer.bounds.height * 0.3), windowLayout: WindowLayout(columns: [[0, 1, 1]])),
            
            BuildingSize(position: CGPoint(x: layer.bounds.width * 0.94, y: layer.bounds.height * 0.89), size: CGSize(width: layer.bounds.width * 0.045, height: layer.bounds.height * 0.3), windowLayout: WindowLayout(columns: [[1]]))
        ]
        drawCacheBackBuildingPath()
        drawCacheBuildingPath()
    }
    
    //MARK: - 빌딩 그림 UIBezierPath
    func drawBuilding() -> UIBezierPath {
        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: 0, y: buildingLayer.bounds.height))
        path.addLine(to: CGPoint(x: 0, y: buildingLayer.bounds.height * 0.65))
        path.addLine(to: CGPoint(x: buildingLayer.bounds.width * 0.0875, y: buildingLayer.bounds.height * 0.65))
        path.addLine(to: CGPoint(x: buildingLayer.bounds.width * 0.0875, y: buildingLayer.bounds.height * 0.7))
        path.addLine(to: CGPoint(x: buildingLayer.bounds.width * 0.14, y: buildingLayer.bounds.height * 0.7))
        path.addLine(to: CGPoint(x: buildingLayer.bounds.width * 0.14, y: buildingLayer.bounds.height))
        
        path.move(to: CGPoint(x: buildingLayer.bounds.width * 0.1575, y: buildingLayer.bounds.height))
        path.addLine(to: CGPoint(x: buildingLayer.bounds.width * 0.1575, y: buildingLayer.bounds.height * 0.75))
        path.addLine(to: CGPoint(x: buildingLayer.bounds.width * 0.245, y: buildingLayer.bounds.height * 0.65))
        path.addLine(to: CGPoint(x: buildingLayer.bounds.width * 0.38, y: buildingLayer.bounds.height * 0.65))
        path.addLine(to: CGPoint(x: buildingLayer.bounds.width * 0.38, y: buildingLayer.bounds.height * 0.7))
        path.addLine(to: CGPoint(x: buildingLayer.bounds.width * 0.42, y: buildingLayer.bounds.height * 0.7))
        path.addLine(to: CGPoint(x: buildingLayer.bounds.width * 0.42, y: buildingLayer.bounds.height))
        
        path.move(to: CGPoint(x: buildingLayer.bounds.width * 0.455, y: buildingLayer.bounds.height))
        path.addLine(to: CGPoint(x: buildingLayer.bounds.width * 0.455, y: buildingLayer.bounds.height * 0.8))
        path.addLine(to: CGPoint(x: buildingLayer.bounds.width * 0.525, y: buildingLayer.bounds.height * 0.8))
        path.addLine(to: CGPoint(x: buildingLayer.bounds.width * 0.525, y: buildingLayer.bounds.height * 0.75))
        path.addLine(to: CGPoint(x: buildingLayer.bounds.width * 0.665, y: buildingLayer.bounds.height * 0.75))
        path.addLine(to: CGPoint(x: buildingLayer.bounds.width * 0.665, y: buildingLayer.bounds.height))
        
        path.move(to: CGPoint(x: buildingLayer.bounds.width * 0.68, y: buildingLayer.bounds.height))
        path.addLine(to: CGPoint(x: buildingLayer.bounds.width * 0.68, y: buildingLayer.bounds.height * 0.6))
        path.addLine(to: CGPoint(x: buildingLayer.bounds.width * 0.9, y: buildingLayer.bounds.height * 0.6))
        path.addLine(to: CGPoint(x: buildingLayer.bounds.width * 0.9, y: buildingLayer.bounds.height * 0.65))
        path.addLine(to: CGPoint(x: buildingLayer.bounds.width * 0.98, y: buildingLayer.bounds.height * 0.65))
        path.addLine(to: CGPoint(x: buildingLayer.bounds.width * 0.98, y: buildingLayer.bounds.height * 0.8))
        path.addLine(to: CGPoint(x: buildingLayer.bounds.width * 0.98, y: buildingLayer.bounds.height))
        path.close()
        return path
    }
    
    func drawBackBuilding() -> UIBezierPath {
        let backPath = UIBezierPath()
        
        backPath.move(to: CGPoint(x: backBuildingLayer.bounds.width * 0.01, y: backBuildingLayer.bounds.height))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.01, y: backBuildingLayer.bounds.height * 0.55))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.04, y: backBuildingLayer.bounds.height * 0.55))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.04, y: backBuildingLayer.bounds.height * 0.5))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.15, y: backBuildingLayer.bounds.height * 0.5))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.15, y: backBuildingLayer.bounds.height))
        
        backPath.move(to: CGPoint(x: backBuildingLayer.bounds.width * 0.18, y: backBuildingLayer.bounds.height))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.18, y: backBuildingLayer.bounds.height * 0.55))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.3, y: backBuildingLayer.bounds.height * 0.55))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.35, y: backBuildingLayer.bounds.height * 0.6))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.35, y: backBuildingLayer.bounds.height))
        
        backPath.move(to: CGPoint(x: backBuildingLayer.bounds.width * 0.355, y: backBuildingLayer.bounds.height))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.355, y: backBuildingLayer.bounds.height * 0.63))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.45, y: backBuildingLayer.bounds.height * 0.63))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.45, y: backBuildingLayer.bounds.height * 0.66))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.5, y: backBuildingLayer.bounds.height * 0.66))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.5, y: backBuildingLayer.bounds.height))
        
        backPath.move(to: CGPoint(x: backBuildingLayer.bounds.width * 0.5, y: backBuildingLayer.bounds.height))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.5, y: backBuildingLayer.bounds.height * 0.85))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.671, y: backBuildingLayer.bounds.height * 0.85))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.671, y: backBuildingLayer.bounds.height * 0.65))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.8, y: backBuildingLayer.bounds.height * 0.55))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.8, y: backBuildingLayer.bounds.height))
        
        backPath.move(to: CGPoint(x: backBuildingLayer.bounds.width * 0.8, y: backBuildingLayer.bounds.height))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.8, y: backBuildingLayer.bounds.height * 0.55))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.94, y: backBuildingLayer.bounds.height * 0.55))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.94, y: backBuildingLayer.bounds.height * 0.5))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width * 0.94, y: backBuildingLayer.bounds.height * 0.48))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width, y: backBuildingLayer.bounds.height * 0.48))
        backPath.addLine(to: CGPoint(x: backBuildingLayer.bounds.width, y: backBuildingLayer.bounds.height))
        
        backPath.close()
        return backPath
    }
    
    //MARK: - Image Caching
    func cacheBuildingPath(_ path: UIBezierPath) {
        BezierPathCache.shared.setBezierPath(path, forKey: "cachedBuildingPath")
    }
    
    func cacheBackBuildingPath(_ backPath: UIBezierPath) {
        BezierPathCache.shared.setBezierPath(backPath, forKey: "cachedBackBuildingPath")
    }
    
    private func drawCacheBuildingPath() {
        let buildingPath: UIBezierPath
        if let cachedBuildingPath = BezierPathCache.shared.getBezierPath(forKey: "cachedBuildingPath") {
            buildingPath = cachedBuildingPath
        } else {
            print("drawCacheBuildingPath에서 drawBuilding")
            buildingPath = drawBuilding()
            cacheBuildingPath(buildingPath)
        }
        buildingLayer.path = buildingPath.cgPath
        buildingLayer.fillColor = UIColor.black.cgColor
        layer.addSublayer(buildingLayer)
    }
    
    private func drawCacheBackBuildingPath() {
        let backBuildingPath: UIBezierPath
        if let cachedBackBuildingPath = BezierPathCache.shared.getBezierPath(forKey: "cachedBackBuildingPath") {
            backBuildingPath = cachedBackBuildingPath
        } else {
            print("drawCacheBackBuildingPath에서 drawBackBuilding")
            backBuildingPath = drawBackBuilding()
            cacheBackBuildingPath(backBuildingPath)
        }
        backBuildingLayer.path = backBuildingPath.cgPath
        backBuildingLayer.fillColor = UIColor.darkGray.cgColor
        layer.addSublayer(backBuildingLayer)
    }
}


//MARK: - firebase
extension BuildingView {
    func fetchDiariesForCurrentMonth(year: Int, month: Int, completion: @escaping ([DiaryEntry]?, Error?) -> Void) {
        
        guard let userID = DiaryManager.shared.getUserID() else {
            completion([], nil)
            return
        }
        
        let startOfMonth = "\(year)-\(String(format: "%02d", month))-01 00:00:00 +0000"
        let endOfMonth = month == 12 ? "\(year + 1)-01-01 23:59:59 +0000" : "\(year)-\(String(format: "%02d", month + 1))-01 23:59:59 +0000"
        
        DiaryManager.shared.db.collection("users").document(userID).collection("diaries").whereField("dateString", isGreaterThanOrEqualTo: startOfMonth).whereField("dateString", isLessThan: endOfMonth).addSnapshotListener { (querySnapshot, error) in
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
                diaries = diaries.filter { !$0.isDeleted }
                DispatchQueue.main.async {
                    print("Fetched diaries: \(diaries)")
                }
                completion(diaries, nil)
            }
        }
    }
    
    func windowsInBuildingData() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let currentMonth = Calendar.current.component(.month, from: Date())
        
        fetchDiariesForCurrentMonth(year: currentYear, month: currentMonth) { (diaries, error) in
            if let error = error {
                print("Error fetching diaries: \(error)")
                return
            }
            
            if let diaries = diaries {
                let diaryDays = diaries.compactMap { diaryEntry -> Int? in
                    if let date = DateFormatter.yyyyMMddHHmmss.date(from: diaryEntry.dateString) {
                        let day = Calendar.current.component(.day, from: date)
                        return day
                    } else {
                        return nil
                    }
                }
                DispatchQueue.main.async {
                    self.diaryDays = Set(diaryDays)
                    print("self.diaryDays: \(self.diaryDays)")
                    self.delegate?.didUpdateDiaryCount(self.diaryDays.count)
                    WindowDrawingHelper.drawBuildingWithWindows(buildings: self.buildings, onLayer: self.buildingLayer, diaryDays: self.diaryDays)
                }
            }
        }
    }
}
