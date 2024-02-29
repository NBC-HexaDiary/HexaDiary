//
//  CalendarVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/23/24.
//

import UIKit

import SnapKit

class CalendarVC: UIViewController {
    
    private lazy var settingButton : UIBarButtonItem = {
        let button = UIBarButtonItem(title: "세팅뷰 이동",image: UIImage(named: "setting"), target: self, action: #selector(tabSettingBTN))
        return button
    }()
    
    private lazy var calendarLabel : UILabel = {
        let label = UILabel()
        label.text = "캘린더"
        label.font = UIFont(name: "SFProDisplay-Bold", size: 33)
        label.textColor = UIColor(named: "mainTheme")
        return label
    }()
    
    private lazy var writeDiaryButton : UIButton = {
        var config = UIButton.Configuration.plain()
        let button = UIButton(configuration: config)
        button.setImage(UIImage(named: "write"), for: .normal)
        button.addTarget(self, action: #selector(tabWriteDiaryBTN), for: .touchUpInside)
        return button
    }()
    
    private lazy var calendarView : UICalendarView = {
        var view = UICalendarView()
        view.wantsDateDecorations = true
        return view
    }()
    
    private let safeArea: UIView = {
        let vc = UIView()
        vc.backgroundColor = .black
        return vc
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "mainBackground")
        addSubviewsCalendarVC()
        autoLayoutCalendarVC()
        configurateViews()
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
        navigationController?.navigationBar.tintColor = UIColor(named: "mainTheme")
    }
    
    private func addSubviewsCalendarVC() {
        view.addSubview(writeDiaryButton)
        view.addSubview(calendarView)
        view.addSubview(calendarLabel)
    }
    
    private func autoLayoutCalendarVC() {
        writeDiaryButton.snp.makeConstraints { make in
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).offset(-10)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-32)
        }
        calendarView.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).offset(-10)
            make.top.equalTo(calendarLabel.snp.bottom).offset(10)
        }
        calendarLabel.snp.makeConstraints { make in
            make.top.equalTo(view).offset(50)
            make.left.equalTo(view).offset(16)
            make.size.equalTo(CGSize(width:100, height: 50))
        }
    }
    
    private func configurateViews() {
        customCalendar()
        setDateComponents()
        setNavigationBar()
        dateSelectCalendar()
    }
    
    private func customCalendar() {
        calendarView.tintColor = .mainTheme
        calendarView.backgroundColor = .mainCell
        calendarView.calendar = Calendar(identifier: .gregorian)
        calendarView.locale = Locale(identifier: "ko-KR")
        calendarView.fontDesign = .rounded
        calendarView.layer.cornerRadius = 10
        calendarView.delegate = self
    }
    
    private func dateSelectCalendar() {
        let dataSelection = UICalendarSelectionSingleDate(delegate: self)
        calendarView.selectionBehavior = dataSelection
    }
    
    private func setDateComponents() {
        let fromDateComponents = DateComponents(
            calendar: calendarView.calendar,
            year: 2024,
            month: 1,
            day: 1
        )
        guard let fromDate = fromDateComponents.date else {
            fatalError("Invalid date components: \(fromDateComponents)")
        }
        let calendarViewDateRange = DateInterval(start: fromDate, end: .distantFuture)
        calendarView.availableDateRange = calendarViewDateRange
    }
}

extension CalendarVC: UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        let vc = CalendarListVC()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        guard let day = dateComponents.day else {
            return nil
        }
        if day.isMultiple(of: 2) {
            return .default(color: .subBackground, size: .medium)
        } else {
            return .default(color: .mainTheme, size: .medium)
        }
        
    }
    func dateSelection(_ selection: UICalendarSelectionSingleDate, canSelectDate dateComponents: DateComponents?) -> Bool {
        guard let day = dateComponents?.day else { return false }
        if day % 2 == 0 {
            return false
        } else {
            return true
        }
    }
}

