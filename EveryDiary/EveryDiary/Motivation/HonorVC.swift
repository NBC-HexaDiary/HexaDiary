//
//  HonorVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/23/24.
//

import UIKit
import SnapKit

#Preview{
    HonorVC()
}

class HonorVC: UIViewController, BuildingViewDelegate {
    func didUpdateDiaryCount(_ diaryCount: Int) {
    }
    
    let buildings = BuildingView()
    
    private lazy var backgroundImage: UIImageView = {
        let backgroundImage = UIImageView()
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        backgroundImage.image = UIImage(named: "honorBackground")
        return backgroundImage
    }()
    
    private lazy var honorSV: UIScrollView = {
        let honorSV = UIScrollView()
        honorSV.translatesAutoresizingMaskIntoConstraints = false
        honorSV.backgroundColor = .clear
        honorSV.showsVerticalScrollIndicator = false
        return honorSV
    }()
    
    private lazy var honorView: UIView = {
        let honorView = UIView()
        honorView.backgroundColor = .clear
        return honorView
    }()
    
    private lazy var testlabel: UILabel = {
        let testlabel = UILabel()
        testlabel.text = "scrollTest"
        testlabel.textColor = .black
        return testlabel
    }()
    
    private lazy var cityButton: UIButton = {
        let cityButton = UIButton()
        return cityButton
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        addSubView()
        autoLayout()
    }
}
extension HonorVC {
    private func addSubView() {
        view.addSubview(backgroundImage)
        view.addSubview(honorSV)
        honorSV.addSubview(honorView)
        honorView.addSubview(testlabel)
    }
    
    private func autoLayout() {
        backgroundImage.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
        honorSV.snp.makeConstraints{ make in
            make.top.bottom.leading.trailing.equalToSuperview()
        }
        honorView.snp.makeConstraints{ make in
            make.top.bottom.leading.trailing.equalTo(honorSV)
            make.width.equalTo(honorSV.snp.width)
            make.height.equalTo(honorSV.snp.height).multipliedBy(4)
        }
        testlabel.snp.makeConstraints{ make in
            make.centerX.equalTo(honorView)
            make.top.equalTo(honorView).offset(20)
        }
    }
}
