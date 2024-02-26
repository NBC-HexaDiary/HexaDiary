//
//  MotivationVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/21/24.
//

import UIKit
import SnapKit

#Preview{
    MotivationVC()
}

class MotivationVC: UIViewController {
    
    let buildings = BuildingView()

    private lazy var settingButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "세팅뷰 이동", style: .plain, target: self, action: #selector(tabSettingBTN))
        return button
    }()
    
    private lazy var writeDiaryButton : UIButton = {
        var config = UIButton.Configuration.plain()
        let button = UIButton(configuration: config)
        button.setTitle("일기작성뷰 이동", for: .normal)
        button.addTarget(self, action: #selector(tabWriteDiaryBTN), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        addSubviewsCalendarVC()
        autoLayoutCalendarVC()
    }
    
    @objc private func tabSettingBTN() {
        let settingVC = SettingVC()
        settingVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(settingVC, animated: true)
    }
    @objc private func tabWriteDiaryBTN() {
        let writeDiaryVC = WriteDiaryVC()
        writeDiaryVC.modalPresentationStyle = .automatic
        self.present(writeDiaryVC, animated: true)
    }
    
    private func addSubviewsCalendarVC() {
        view.addSubview(buildings)
        view.addSubview(writeDiaryButton)
        navigationItem.rightBarButtonItem = settingButton
    }
    
    private func autoLayoutCalendarVC() {
        writeDiaryButton.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
        }
        buildings.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalToSuperview()
        }
    }
}
