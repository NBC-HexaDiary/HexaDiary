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

class MotivationVC: UIViewController, BuildingViewDelegate {
    private let buildings = BuildingView.shared
    
    private lazy var background : UIImageView = {
        let background = UIImageView(image: UIImage(named: "View.Background"))
        return background
    }()
    
    private lazy var settingButton : UIBarButtonItem = {
        let button = UIBarButtonItem(title: "세팅뷰 이동",image: UIImage(named: "setting"), target: self, action: #selector(tabSettingBTN))
        return button
    }()
    
    private lazy var writeDiaryButton : UIButton = {
        var config = UIButton.Configuration.plain()
        let button = UIButton(configuration: config)
        button.setImage(UIImage(named: "write"), for: .normal)
        button.addTarget(self, action: #selector(tabWriteDiaryBTN), for: .touchUpInside)
        return button
    }()
    
    private lazy var honorVCButton : UIBarButtonItem = {
        let honorVCButton = UIBarButtonItem(title: "", image: UIImage(named: "honor"), target: self, action: #selector(honorVCBTN))
        return honorVCButton
    }()
    
    private lazy var monthLabel: UILabel = {
        let monthLabel = UILabel()
        let currentMonth = Calendar.current.component(.month, from: Date())
        monthLabel.text = "\(currentMonth)월"
        monthLabel.font = UIFont(name: "SFProDisplay-Bold", size: 25)
        monthLabel.textColor = .white
        return monthLabel
    }()
    
    private lazy var countLabel: UILabel = {
        let countLabel = UILabel()
        countLabel.font = UIFont(name: "SFProDisplay-Regular", size: 16)
        countLabel.textColor = .white
        return countLabel
    }()
    
    private func updateCountLabel() {
        let diaryCount = buildings.diaryDays.count
        let date = Date()
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: date)
        if let numberOfDays = range?.count {
            countLabel.text = "\(numberOfDays)일 중 \(diaryCount)개 작성했어요."
        } else {
            print("error: diaryCount error")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        buildings.windowsInBuildingData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buildings.delegate = self
        updateCountLabel()
        addSubview()
        autoLayout()
    }
    
    func didUpdateDiaryCount(_ diaryCount: Int) {
        updateCountLabel()
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
    
    @objc private func honorVCBTN() {
        let honorVC = HonorVC()
        honorVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(honorVC, animated: true)
    }
    
    private func addSubview() {
        view.addSubview(background)
        view.addSubview(buildings)
        view.addSubview(writeDiaryButton)
        view.addSubview(monthLabel)
        view.addSubview(countLabel)
        setNavigationBar()
    }
    
    private func autoLayout() {
        background.snp.makeConstraints{ make in
            make.top.bottom.leading.trailing.equalToSuperview()
        }
        writeDiaryButton.snp.makeConstraints { make in
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).offset(-10)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-32)
        }
        buildings.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalTo(view.safeAreaLayoutGuide)
        }
        monthLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.centerX.equalToSuperview()
        }
        countLabel.snp.makeConstraints { make in
            make.top.equalTo(monthLabel.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }
    }
    
    private func setNavigationBar() {
        navigationItem.rightBarButtonItem = settingButton
        navigationItem.leftBarButtonItem = honorVCButton
        navigationController?.navigationBar.tintColor = .white
    }
}
