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
    // Singleton 패턴을 사용하여 공유 인스턴스 생성
    static let shared = BuildingView()
    weak var delegate: BuildingViewDelegate?
    // 이미지 캐시 관련 변수
    var cachedBuildingImage: UIImage?
    var cachedBackBuildingImage: UIImage?
    var windowImageCache = [Int: UIImage]()
    // Firestore 관련 변수
    let db = Firestore.firestore()
    var diaryDays: Set<Int> = []
    
    var listener: ListenerRegistration?
    
    // 빌딩 구조체 정의
    struct BuildingSize {
        let position: CGPoint
        let size: CGSize
        let windowLayout: WindowLayout
    }
    // 창문 레이아웃 구조체 정의
    struct WindowLayout {
        let columns: [[Int]]
    }
    // 빌딩 배열
    var buildings: [BuildingSize] = []
    // 레이어 정의
    let backgroundLayer = CALayer()
    let backBuildingLayer = CAShapeLayer()
    let buildingLayer = CAShapeLayer()
    // 창문 크기 및 간격 설정
    let windowSize = CGSize(width: 10, height: 22)
    let windowSpacing: CGFloat = 15
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
    }
    // UIView에 맞춰 동적으로 크기 변경
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.addSublayer(backgroundLayer)
        backgroundLayer.frame = self.bounds
        backBuildingLayer.frame = self.bounds
        buildingLayer.frame = self.bounds
        //backBuilding 위치와 크기
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
        print("검은 빌딩 그림")
        let path = UIBezierPath()
        
        // black 첫 번째 건물
        path.move(to: CGPoint(x: 0, y: backgroundLayer.bounds.height))
        path.addLine(to: CGPoint(x: 0, y: backgroundLayer.bounds.height * 0.65))
        path.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.0875, y: backgroundLayer.bounds.height * 0.65))
        path.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.0875, y: backgroundLayer.bounds.height * 0.7))
        path.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.14, y: backgroundLayer.bounds.height * 0.7))
        path.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.14, y: backgroundLayer.bounds.height))
        
        // black 두 번째 건물
        path.move(to: CGPoint(x: backgroundLayer.bounds.width * 0.1575, y: backgroundLayer.bounds.height))
        path.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.1575, y: backgroundLayer.bounds.height * 0.75))
        path.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.245, y: backgroundLayer.bounds.height * 0.65))
        path.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.38, y: backgroundLayer.bounds.height * 0.65))
        path.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.38, y: backgroundLayer.bounds.height * 0.7))
        path.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.42, y: backgroundLayer.bounds.height * 0.7))
        path.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.42, y: backgroundLayer.bounds.height))
        
        // black 세 번째 건물
        path.move(to: CGPoint(x: backgroundLayer.bounds.width * 0.455, y: backgroundLayer.bounds.height))
        path.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.455, y: backgroundLayer.bounds.height * 0.8))
        path.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.525, y: backgroundLayer.bounds.height * 0.8))
        path.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.525, y: backgroundLayer.bounds.height * 0.75))
        path.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.665, y: backgroundLayer.bounds.height * 0.75))
        path.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.665, y: backgroundLayer.bounds.height))
        
        // black 네 번째 건물
        path.move(to: CGPoint(x: backgroundLayer.bounds.width * 0.68, y: backgroundLayer.bounds.height))
        path.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.68, y: backgroundLayer.bounds.height * 0.6))
        path.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.9, y: backgroundLayer.bounds.height * 0.6))
        path.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.9, y: backgroundLayer.bounds.height * 0.65))
        path.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.98, y: backgroundLayer.bounds.height * 0.65))
        path.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.98, y: backgroundLayer.bounds.height * 0.8))
        path.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.98, y: backgroundLayer.bounds.height))
        path.close()
        buildingLayer.path = path.cgPath
        buildingLayer.fillColor = UIColor.black.cgColor
        backBuildingLayer.addSublayer(buildingLayer)
    }
    
    func drawBackBuilding() {
        print("회색 빌딩 그림")
        let backPath = UIBezierPath()
        // gray 첫 번째 건물
        backPath.move(to: CGPoint(x: backgroundLayer.bounds.width * 0.01, y: backgroundLayer.bounds.height))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.01, y: backgroundLayer.bounds.height * 0.55))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.04, y: backgroundLayer.bounds.height * 0.55))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.04, y: backgroundLayer.bounds.height * 0.5))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.15, y: backgroundLayer.bounds.height * 0.5))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.15, y: backgroundLayer.bounds.height))
        
        // gray 두 번째 건물
        backPath.move(to: CGPoint(x: backgroundLayer.bounds.width * 0.18, y: backgroundLayer.bounds.height))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.18, y: backgroundLayer.bounds.height * 0.55))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.3, y: backgroundLayer.bounds.height * 0.55))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.35, y: backgroundLayer.bounds.height * 0.6))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.35, y: backgroundLayer.bounds.height))
        
        // gray 세 번째 건물
        backPath.move(to: CGPoint(x: backgroundLayer.bounds.width * 0.355, y: backgroundLayer.bounds.height))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.355, y: backgroundLayer.bounds.height * 0.63))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.45, y: backgroundLayer.bounds.height * 0.63))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.45, y: backgroundLayer.bounds.height * 0.66))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.5, y: backgroundLayer.bounds.height * 0.66))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.5, y: backgroundLayer.bounds.height))
        
        // gray 네 번째 건물
        backPath.move(to: CGPoint(x: backgroundLayer.bounds.width * 0.5, y: backgroundLayer.bounds.height))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.5, y: backgroundLayer.bounds.height * 0.85))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.671, y: backgroundLayer.bounds.height * 0.85))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.671, y: backgroundLayer.bounds.height * 0.65))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.8, y: backgroundLayer.bounds.height * 0.55))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.8, y: backgroundLayer.bounds.height))
        
        // gray 다섯 번째 건물
        backPath.move(to: CGPoint(x: backgroundLayer.bounds.width * 0.8, y: backgroundLayer.bounds.height))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.8, y: backgroundLayer.bounds.height * 0.55))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.94, y: backgroundLayer.bounds.height * 0.55))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.94, y: backgroundLayer.bounds.height * 0.5))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width * 0.94, y: backgroundLayer.bounds.height * 0.48))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width, y: backgroundLayer.bounds.height * 0.48))
        backPath.addLine(to: CGPoint(x: backgroundLayer.bounds.width, y: backgroundLayer.bounds.height))
        
        backPath.close()
        backBuildingLayer.path = backPath.cgPath
        backBuildingLayer.fillColor = UIColor.darkGray.cgColor
        backgroundLayer.addSublayer(backBuildingLayer)
    }
    
    //MARK: - Image Caching
    //창문 이미지로 랜더링하여 반환
    func cacheWindowImageIfNeeded(windowIndex: Int, color: UIColor, windowSize: CGSize) {
        if MotivationImageCache.shared.getImage(forKey: "window_\(windowIndex)") != nil {
            print("Image for window \(windowIndex) is cached.")
            return
        } else {
            let renderer = UIGraphicsImageRenderer(size: windowSize)
            let windowImage = renderer.image { context in
                color.setFill()
                context.fill(CGRect(origin: .zero, size: windowSize))
            }
            MotivationImageCache.shared.setImage(windowImage, forKey: "window_\(windowIndex)")
            print("Image for window \(windowIndex) is cached successfully.")
        }
    }
    
    //검은 빌딩 이미지로 랜더링하여 반환
    func drawBuildingImage() -> UIImage {
        print("검은 빌딩 이미지 그리기")
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: self.bounds.width, height: self.bounds.height))
        let image = renderer.image { context in
            drawBuilding()
        }
        return image
    }
    //회색 빌딩 이미지로 랜더링하여 반환
    func drawBackBuildingImage() -> UIImage {
        print("회색 빌딩 이미지 그리기")
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: self.bounds.width, height: self.bounds.height))
        let image = renderer.image { context in
            drawBackBuilding()
        }
        return image
    }
    
    func setupBuildingLayers() {
        // 이미지 캐싱
        if cachedBuildingImage == nil {
            cachedBuildingImage = drawBuildingImage()
            print("Building image cached successfully")
        }
        
        if cachedBackBuildingImage == nil {
            cachedBackBuildingImage = drawBackBuildingImage()
            print("Back building image cached successfully")
        }
        // 빌딩 레이어 설정
        let buildingLayer = CALayer()
        buildingLayer.frame = self.bounds
        buildingLayer.contents = cachedBuildingImage?.cgImage
        self.layer.addSublayer(buildingLayer)
        
        // 배경 빌딩 레이어 설정
        let backBuildingLayer = CALayer()
        backBuildingLayer.frame = self.bounds
        backBuildingLayer.contents = cachedBackBuildingImage?.cgImage
        self.layer.addSublayer(backBuildingLayer)
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
    //inout 키워드를 사용하면 변수처럼 함수 내부에서 매개변수의 값을 변경할 수 있음
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
                print("Window \(windowOrder): 데이터 있음")
                windowOrder += 1
            } else {
                cacheWindowImageIfNeeded(windowIndex: windowOrder, color: .darkGray, windowSize: CGSize(width: windowWidth, height: windowHeight))
                let windowLayer = createWindowLayer(at: windowPosition, color: .darkGray, windowIndex: windowOrder)
                buildingLayer.addSublayer(windowLayer)
                print("Window \(windowOrder): 데이터 없음")
            }
        }
    }
}
//MARK: - firebase
extension BuildingView {
    //특정 월에 대한 일기 데이터를 Firestore 데이터베이스에서 가져오는 함수
    func fetchDiariesForCurrentMonth(year: Int, month: Int, completion: @escaping ([DiaryEntry]?, Error?) -> Void) {
        
        guard let userID = DiaryManager.shared.getUserID() else {
            completion([], nil)
            return
        }
        
        let startOfMonth = "\(year)-\(String(format: "%02d", month))-01 00:00:00 +0000"
        let endOfMonth = month == 12 ? "\(year + 1)-01-01 23:59:59 +0000" : "\(year)-\(String(format: "%02d", month + 1))-01 23:59:59 +0000"
        //dateString에서 현재 월 데이터만 가져오기
        db.collection("users").document(userID).collection("diaries").whereField("dateString", isGreaterThanOrEqualTo: startOfMonth).whereField("dateString", isLessThan: endOfMonth).addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                completion(nil, error)
            } else {
                //DiaryEntry 형식으로 변환하고 가져온 데이터는 배열에 추가
                var diaries = [DiaryEntry]()
                for document in querySnapshot!.documents {
                    if let diary = try? document.data(as: DiaryEntry.self) {
                        diaries.append(diary)
                    }
                }
                DispatchQueue.main.async { // 메인 스레드에서 로그를 출력합니다.
                    print("Fetched diaries: \(diaries)")
                }
                completion(diaries, nil)
            }
        }
    }
    
    //현재 월의 일기 데이터를 가져오고 그 데이터를 바탕으로 건물 창문을 업데이트하는 함수
    func windowsInBuildingData() {
        //현재 년도 + 월 가져오기
        let currentYear = Calendar.current.component(.year, from: Date())
        let currentMonth = Calendar.current.component(.month, from: Date())
        //현재 월의 일기 데이터를 가져오기
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
                    self.drawWindowInBuilding()
                }
            }
        }
    }
}
