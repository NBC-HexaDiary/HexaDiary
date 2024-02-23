//
//  MainVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/21/24.
//

import UIKit

class DiaryListVC: UIViewController {

    
    private lazy var settingButton : UIButton = {
        var config = UIButton.Configuration.plain()
        let button = UIButton(configuration: config)
        button.setTitle("세팅뷰 이동", for: .normal)
        button.addTarget(self, action: #selector(tabSettingBTN), for: .touchUpInside)
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
        addSubviewsCalendarVC()
        autoLayoutCalendarVC()
        
        view.backgroundColor = .systemOrange
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
        view.addSubview(settingButton)
        view.addSubview(writeDiaryButton)
    }
    
    private func autoLayoutCalendarVC() {
        settingButton.translatesAutoresizingMaskIntoConstraints = false
        writeDiaryButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            settingButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            settingButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            settingButton.widthAnchor.constraint(equalToConstant: 200),
            settingButton.heightAnchor.constraint(equalToConstant: 50),
            
            writeDiaryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            writeDiaryButton.topAnchor.constraint(equalTo: settingButton.bottomAnchor, constant: 20),
            writeDiaryButton.widthAnchor.constraint(equalToConstant: 200),
            writeDiaryButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}
