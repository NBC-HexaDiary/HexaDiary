//
//  MainVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/21/24.
//

import UIKit
import SnapKit

class DiaryListVC: UIViewController {

    
    private lazy var settingButton : UIBarButtonItem = {
        let button = UIBarButtonItem(title: "세팅뷰 이동",image: UIImage(named: "setting"), target: self, action: #selector(tabSettingBTN))
        return button
    }()
    
    private lazy var themeLabel : UILabel = {
        let label = UILabel()
        label.text = "하루일기"
        label.font = UIFont(name: "SFProDisplay-Bold", size: 33)
        label.textColor = UIColor(named: "main")
        return label
    }()
    
    private lazy var writeDiaryButton : UIButton = {
        var config = UIButton.Configuration.plain()
        let button = UIButton(configuration: config)
        button.setImage(UIImage(named: "write"), for: .normal)
        button.addTarget(self, action: #selector(tabWriteDiaryBTN), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "Background")
        addSubviewsCalendarVC()
        autoLayoutCalendarVC()
        setNavigationBar()
        

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
    private func setNavigationBar() {
        navigationItem.rightBarButtonItem = settingButton
        navigationController?.navigationBar.tintColor = UIColor(named: "main")
    }
    
    private func addSubviewsCalendarVC() {
        view.addSubview(writeDiaryButton)
        view.addSubview(themeLabel)
    }
    
    private func autoLayoutCalendarVC() {
        writeDiaryButton.snp.makeConstraints { make in
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).offset(-10)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-32)
        }
        themeLabel.snp.makeConstraints { make in
            make.top.equalTo(view).offset(50)
            make.left.equalTo(view).offset(16)
            make.size.equalTo(CGSize(width:120, height: 50))
        }
    }
}
