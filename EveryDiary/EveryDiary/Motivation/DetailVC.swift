//
//  DetailVC.swift
//  EveryDiary
//
//  Created by t2023-m0099 on 3/21/24.
//

import UIKit

import SnapKit

#Preview{
    DetailVC()
}

class DetailVC: UIViewController {
    private var firstLayer = CAShapeLayer()
    private var secondLayer = CAShapeLayer()
    private let windowLayer = CALayer()
    
    var selectedData = Set<Int>()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        autoLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        addSubView()
        drawCacheBackBuildingPath()
        drawCacheBuildingPath()
        drawWindows()
    }
    
    private func drawCacheBuildingPath() {
        let buildingPath: UIBezierPath
        if let cachedBuildingPath = BezierPathCache.shared.getBezierPath(forKey: "cachedBuildingPath") {
            buildingPath = cachedBuildingPath
        } else {
            print("drawCacheBuildingPath에서 drawBuilding")
            buildingPath = BuildingView().drawBuilding()
            BezierPathCache.shared.setBezierPath(buildingPath, forKey: "cachedBuildingPath")
        }
        secondLayer.path = buildingPath.cgPath
        secondLayer.fillColor = UIColor.black.cgColor
    }
    
    private func drawCacheBackBuildingPath() {
        let backBuildingPath: UIBezierPath
        if let cachedBackBuildingPath = BezierPathCache.shared.getBezierPath(forKey: "cachedBackBuildingPath") {
            backBuildingPath = cachedBackBuildingPath
        } else {
            print("drawCacheBackBuildingPath에서 drawBackBuilding")
            backBuildingPath = BuildingView().drawBackBuilding()
            BezierPathCache.shared.setBezierPath(backBuildingPath, forKey: "cachedBackBuildingPath")
        }
        firstLayer.path = backBuildingPath.cgPath
        firstLayer.fillColor = UIColor.darkGray.cgColor
    }
    
    private func drawWindows() {
        let building1 = BuildingSize(position: CGPoint(x: 0, y: view.layer.bounds.height * 0.78),
                         size: CGSize(width: view.layer.bounds.width * 0.07, height: view.layer.bounds.height * 0.22),
                         windowLayout: WindowLayout(columns: [[0, 1], [1, 1], [1], [1, 1], [1]]))
        
        let building2 = BuildingSize(position: CGPoint(x: view.layer.bounds.width * 0.21, y: view.layer.bounds.height * 0.77),
                                     size: CGSize(width: view.layer.bounds.width * 0.07, height: view.layer.bounds.height * 0.21),
                         windowLayout: WindowLayout(columns: [[0, 1, 1], [1, 0, 1],[1, 1], [0, 1]]))
            
        let building3 = BuildingSize(position: CGPoint(x: view.layer.bounds.width * 0.51, y: view.layer.bounds.height * 0.82),
                         size: CGSize(width: view.layer.bounds.width * 0.048, height: view.layer.bounds.height * 0.19),
                         windowLayout: WindowLayout(columns: [[1, 1, 0],[0, 1, 1], [1, 0, 1], [0, 1]]))
            
        let building4 = BuildingSize(position: CGPoint(x: view.layer.bounds.width * 0.73, y: view.layer.bounds.height * 0.83),
                                     size: CGSize(width: (view.layer.bounds.width - view.layer.bounds.width * 0.92), height: view.layer.bounds.height * 0.3),
                         windowLayout: WindowLayout(columns: [[1], [1], [1, 1, 1], [1, 1]]))
            
        let building5 = BuildingSize(position: CGPoint(x: 0, y: view.layer.bounds.height * 0.75),
                         size: CGSize(width: view.layer.bounds.width * 0.045, height: view.layer.bounds.height * 0.3),
                         windowLayout: WindowLayout(columns: [[0, 1, 1]]))
            
        let building6 = BuildingSize(position: CGPoint(x: view.layer.bounds.width * 0.94, y: view.layer.bounds.height * 0.75),
                         size: CGSize(width: view.layer.bounds.width * 0.045, height: view.layer.bounds.height * 0.3),
                         windowLayout: WindowLayout(columns: [[1]]))
        
        let buildings = [building1, building2, building3, building4, building5, building6]
        WindowDrawingHelper.drawBuildingWithWindows(buildings: buildings, onLayer: windowLayer, diaryDays: selectedData)
        view.layer.addSublayer(windowLayer)
    }
}

extension DetailVC {
    private func addSubView() {
        view.layer.addSublayer(firstLayer)
        view.layer.addSublayer(secondLayer)
    }
    
    private func autoLayout() {
        
        let layoutFrame = view.safeAreaLayoutGuide.layoutFrame
        firstLayer.frame = layoutFrame
        secondLayer.frame = layoutFrame
        windowLayer.frame = layoutFrame
   }
}
