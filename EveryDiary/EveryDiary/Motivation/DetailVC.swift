//
//  DetailVC.swift
//  EveryDiary
//
//  Created by t2023-m0099 on 3/17/24.
//

import UIKit
#Preview{
    DetailVC()
}

class DetailVC: UIViewController {
    private let buildingView = BuildingView()
    var daysSet: Set<Int>?
    
    private lazy var buildindsimages: UIImageView = {
        let buildindsimages = UIImageView()
        return buildindsimages
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addsubView()
        autoLayout()
        buildingView.drawWindowInBuilding()
        print("\(String(describing: daysSet))")
    }
}

extension DetailVC {
    private func addsubView() {
        view.addSubview(buildingView)
    }
    
    private func autoLayout() {
        buildingView.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalTo(view.safeAreaLayoutGuide)
        }
    }
}
