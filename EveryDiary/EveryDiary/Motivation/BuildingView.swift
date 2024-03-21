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

    let db = Firestore.firestore()
    var diaryDays: Set<Int> = []
    
    struct BuildingSize {
        let position: CGPoint
        let size: CGSize
        let windowLayout: WindowLayout
    }

    struct WindowLayout {
        let columns: [[Int]]
    }

    var buildings: [BuildingSize] = []

    let backgroundLayer = CALayer()
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
        self.layer.addSublayer(backgroundLayer)
        backgroundLayer.frame = self.bounds
        backBuildingLayer.frame = self.bounds
        buildingLayer.frame = self.bounds
        buildings = [
            BuildingSize(position: CGPoint(x: 0, y: backgroundLayer.bounds.height * 0.97),
                         size: CGSize(width: backgroundLayer.bounds.width * 0.07, height: backgroundLayer.bounds.height * 0.3), windowLayout: WindowLayout(columns: [[0, 1], [1, 1], [1], [1, 1], [1]])),
            
            BuildingSize(position: CGPoint(x: backgroundLayer.bounds.width * 0.21, y: backgroundLayer.bounds.height * 0.99),
                         size: CGSize(width: backgroundLayer.bounds.width * 0.07, height: backgroundLayer.bounds.height * 0.31), windowLayout: WindowLayout(columns: [[0, 1, 1], [1, 0, 1],[1, 1], [0, 1]])),
            
            BuildingSize(position: CGPoint(x: backgroundLayer.bounds.width * 0.51, y: backgroundLayer.bounds.height * 1.02),
                         size: CGSize(width: backgroundLayer.bounds.width * 0.048, height: backgroundLayer.bounds.height * 0.25), windowLayout: WindowLayout(columns: [[1, 1, 0],[0, 1, 1], [1, 0, 1], [0, 1]])),
            
            BuildingSize(position: CGPoint(x: backgroundLayer.bounds.width * 0.73, y: backgroundLayer.bounds.height * 1.03),
                         size: CGSize(width: (backgroundLayer.bounds.width - backgroundLayer.bounds.width * 0.92), height: backgroundLayer.bounds.height * 0.4), windowLayout: WindowLayout(columns: [[0], [1, 0, 1], [1, 1, 1], [1, 1]])),
            
            BuildingSize(position: CGPoint(x: 0, y: backgroundLayer.bounds.height * 0.9),
                         size: CGSize(width: backgroundLayer.bounds.width * 0.045, height: backgroundLayer.bounds.height * 0.3), windowLayout: WindowLayout(columns: [[0, 1, 1]])),
            
            BuildingSize(position: CGPoint(x: backgroundLayer.bounds.width * 0.94, y: backgroundLayer.bounds.height * 0.89), size: CGSize(width: backgroundLayer.bounds.width * 0.045, height: backgroundLayer.bounds.height * 0.3), windowLayout: WindowLayout(columns: [[1]]))
        ]
        setupBuildingLayers()
    }
    
    //MARK: - 빌딩 그림 UIBezierPath
    func drawBuilding() {
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
        buildingLayer.path = path.cgPath
        buildingLayer.fillColor = UIColor.black.cgColor
        backBuildingLayer.addSublayer(buildingLayer)
    }
    
    func drawBackBuilding() {
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
        backBuildingLayer.path = backPath.cgPath
        backBuildingLayer.fillColor = UIColor.darkGray.cgColor
        backgroundLayer.addSublayer(backBuildingLayer)
    }
    
    //MARK: - Image Caching
    func cacheWindowImageIfNeeded(windowIndex: Int, color: UIColor, windowSize: CGSize) {
        if MotivationImageCache.shared.getImage(forKey: "window_\(windowIndex)") != nil {
            return
        } else {
            let renderer = UIGraphicsImageRenderer(size: windowSize)
            let windowImage = renderer.image { context in
                color.setFill()
                context.fill(CGRect(origin: .zero, size: windowSize))
            }
            MotivationImageCache.shared.setImage(windowImage, forKey: "window_\(windowIndex)")
//            print("Image for window \(windowIndex) is cached successfully.")
        }
    }
    
    func setupBuildingLayers() {
        // 빌딩 레이어 설정
        let buildingLayer = CALayer()
        buildingLayer.frame = bounds
        if let cachedBuildingImage = MotivationImageCache.shared.getImage(forKey: "cachedBuildingImage") {
            buildingLayer.contents = cachedBuildingImage.cgImage
        } else {
            let buildingImage = drawBuildingImage()
            MotivationImageCache.shared.setImage(buildingImage, forKey: "cachedBuildingImage")
            buildingLayer.contents = buildingImage.cgImage
        }
        layer.addSublayer(buildingLayer)

        // 배경 빌딩 레이어 설정
        let backBuildingLayer = CALayer()
        backBuildingLayer.frame = bounds
        if let cachedBackBuildingImage = MotivationImageCache.shared.getImage(forKey: "cachedBackBuildingImage") {
            backBuildingLayer.contents = cachedBackBuildingImage.cgImage
        } else {
            let backBuildingImage = drawBackBuildingImage()
            MotivationImageCache.shared.setImage(backBuildingImage, forKey: "cachedBackBuildingImage")
            backBuildingLayer.contents = backBuildingImage.cgImage
        }
        layer.addSublayer(backBuildingLayer)
    }
    
    func drawBuildingImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        let image = renderer.image { context in
            drawBuilding()
        }
        return image
    }
    func drawBackBuildingImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        let image = renderer.image { context in
            drawBackBuilding()
        }
        return image
    }
    
    //MARK: - 창문 관련 함수
    func createWindowLayer(at position: CGPoint, color: UIColor, windowIndex: Int) -> CAShapeLayer {
        let windowPath = UIBezierPath(rect: CGRect(origin: position, size: windowSize))
        let windowLayer = CAShapeLayer()
        windowLayer.path = windowPath.cgPath
        windowLayer.fillColor = color.cgColor
        return windowLayer
    }
    
    func drawWindowInBuilding() {
        guard !buildings.isEmpty else { return }
        var windowOrder = 1
        for building in buildings {
            handleBuilding(building, &windowOrder)
        }
    }
    func handleBuilding(_ building: BuildingSize, _ windowOrder: inout Int) {
        for (i, row) in building.windowLayout.columns.enumerated() {
            handleFloor(i, row, building, &windowOrder)
        }
    }
    
    func handleFloor(_ floorIndex: Int, _ floorWindows: [Int], _ building: BuildingSize, _ windowOrder: inout Int) {
        for (windowIndex, windowColumns) in floorWindows.enumerated() {
            if windowColumns == 0 { continue }
            let windowWidth = building.size.width / CGFloat(windowColumns)
            let windowHeight = building.size.height / CGFloat(building.windowLayout.columns.count)
            let windowPosition = CGPoint(x: building.position.x + windowWidth * CGFloat(windowIndex), y: building.position.y - windowHeight * CGFloat(floorIndex+1))
            
            if !diaryDays.isEmpty && windowOrder <= diaryDays.count {
                cacheWindowImageIfNeeded(windowIndex: windowOrder, color: .yellow, windowSize: CGSize(width: windowWidth, height: windowHeight))
                let windowLayer = createWindowLayer(at: windowPosition, color: .yellow, windowIndex: windowOrder)
                buildingLayer.addSublayer(windowLayer)
                windowOrder += 1
            } else {
                cacheWindowImageIfNeeded(windowIndex: windowOrder, color: .darkGray, windowSize: CGSize(width: windowWidth, height: windowHeight))
                let windowLayer = createWindowLayer(at: windowPosition, color: .darkGray, windowIndex: windowOrder)
                buildingLayer.addSublayer(windowLayer)
            }
        }
    }
}
//MARK: - firebase
extension BuildingView {
    func updateWindowsWithDiaryCount(_ count: Int) {
        self.diaryDays = Set(1...count)
        drawWindowInBuilding()
    }
    
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
//                    print("Fetched diaries: \(diaries)")
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
//                    print("self.diaryDays: \(self.diaryDays)")
                    self.delegate?.didUpdateDiaryCount(self.diaryDays.count)
                    self.drawWindowInBuilding()
                }
            }
        }
    }
}
