//
//  BuildingView.swift
//  EveryDiary
//
//  Created by t2023-m0099 on 2/26/24.
//
// 재사용성을 어떻게 높일 수 있을까?

import Foundation
import UIKit
#Preview{
    BuildingView()
}

class BuildingView: UIView {
    var buildings: [BuildingSize] = []
    let backgroundLayer = CALayer()
    let backBuildingLayer = CAShapeLayer()
    let buildingLayer = CAShapeLayer()
    let windowSize = CGSize(width: 10, height: 20)
    let windowSpacing: CGFloat = 20
    
    struct BuildingSize {
        let position: CGPoint
        let size: CGSize
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ rect: CGRect) {
        //backgroundLayer.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
        drawBackBuilding()
        drawBuilding()
        layoutSubviews()
        windowDateData()
    }
    
    // UIView에 맞춰 동적으로 크기 변경
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.addSublayer(backgroundLayer)
        backgroundLayer.frame = self.bounds
        backBuildingLayer.frame = self.bounds
        buildingLayer.frame = self.bounds
        
        buildings = [
            BuildingSize(position: CGPoint(x: 0, y: backgroundLayer.bounds.height),
                         size: CGSize(width: backgroundLayer.bounds.width * 0.14, height: backgroundLayer.bounds.height * 0.65)),
            
            BuildingSize(position: CGPoint(x: backgroundLayer.bounds.width * 0.1575, y: backgroundLayer.bounds.height),
                         size: CGSize(width: backgroundLayer.bounds.width * 0.2625, height: backgroundLayer.bounds.height * 0.65)),
            
            BuildingSize(position: CGPoint(x: backgroundLayer.bounds.width * 0.455, y: backgroundLayer.bounds.height),
                         size: CGSize(width: backgroundLayer.bounds.width * 0.21, height: backgroundLayer.bounds.height * 0.95)),
            
            BuildingSize(position: CGPoint(x: backgroundLayer.bounds.width * 0.68, y: backgroundLayer.bounds.height),
                         size: CGSize(width: (backgroundLayer.bounds.width - backgroundLayer.bounds.width * 0.68), height: backgroundLayer.bounds.height * 0.6))
        ]
        
        //windowDateData()
    }
    
    //MARK: 빌딩 그림 UIBezierPath
    func drawBuilding() {
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
    
    //MARK: 창문 관련 함수
    func drawWindows(at position: CGPoint) {
        let windowPath = UIBezierPath(rect: CGRect(origin: position, size: windowSize))
        let windowLayer = CAShapeLayer()
        windowLayer.path = windowPath.cgPath
        windowLayer.fillColor = UIColor.yellow.cgColor
        buildingLayer.addSublayer(windowLayer)
    }
    
    func drawWindowsInBuilding(_ building: BuildingSize) {
        let numberOfColumns = 2
        let numberOfRow = [4, 3]

        //각 창문의 위치를 계산
        for i in 0..<numberOfColumns {
            for j in 0..<numberOfRow[i] {
                let windowPosition = CGPoint (
                    x: building.position.x + (building.size.width / 6) + CGFloat(i) * (windowSize.width + windowSpacing),
                    y: self.bounds.height - CGFloat(j + 1) * (windowSize.height + windowSpacing)
                )
                drawWindows(at: windowPosition)
            }
        }
    }
    
    func windowDateData() {
        let date = Date()
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: date)!
        let numberDays = range.count
        
        let maxBuildingIndex = min(buildings.count - 1, 27)
        
        //드디어 창문 그린다
        if numberDays <= maxBuildingIndex + 1 {
            for i in 0..<numberDays {
                drawWindowsInBuilding(buildings[i])
            }
        } else {
            for i in 0...maxBuildingIndex {
                drawWindowsInBuilding(buildings[i])
            }
            for i in maxBuildingIndex + 1..<numberDays {
                let windowPosition = CGPoint(x: CGFloat(i - 28) * (windowSize.width + windowSpacing), y: buildings.last?.position.y ?? 0)
                drawWindows(at: windowPosition)
            }
        }
    }
}
