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
    private let buildingView = BuildingView()
    
    var selectedData = Set<Int>()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemIndigo
        addSubView()
        drawCacheBackBuildingPath()
        drawCacheBuildingPath()
        autoLayout()
    }
    
    private func drawCacheBuildingPath() {
        let buildingPath: UIBezierPath
        if let cachedBuildingPath = BezierPathCache.shared.getBezierPath(forKey: "cachedBuildingPath") {
            buildingPath = cachedBuildingPath
        } else {
            print("drawCacheBuildingPath에서 drawBuilding")
            buildingPath = buildingView.drawBuilding()
            buildingView.cacheBuildingPath(buildingPath)
        }
        buildingView.buildingLayer.path = buildingPath.cgPath
        buildingView.buildingLayer.fillColor = UIColor.black.cgColor
    }
    
    private func drawCacheBackBuildingPath() {
        let backBuildingPath: UIBezierPath
        if let cachedBackBuildingPath = BezierPathCache.shared.getBezierPath(forKey: "cachedBackBuildingPath") {
            backBuildingPath = cachedBackBuildingPath
        } else {
            print("drawCacheBackBuildingPath에서 drawBackBuilding")
            backBuildingPath = buildingView.drawBackBuilding()
            buildingView.cacheBackBuildingPath(backBuildingPath)
        }
        buildingView.backBuildingLayer.path = backBuildingPath.cgPath
        buildingView.backBuildingLayer.fillColor = UIColor.darkGray.cgColor
    }
}

extension DetailVC {
    private func addSubView() {
        view.addSubview(buildingView)
        view.layer.addSublayer(buildingView.backBuildingLayer)
        view.layer.addSublayer(buildingView.buildingLayer)
    }
    
    private func autoLayout() {
        buildingView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
}
