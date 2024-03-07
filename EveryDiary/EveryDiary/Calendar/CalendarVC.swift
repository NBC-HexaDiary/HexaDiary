//
//  CalendarVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/23/24.
//

import UIKit

import SnapKit

class CalendarVC: UIViewController {
    
    private var diaries: [DiaryEntry] = []
    
    private lazy var settingButton : UIBarButtonItem = {
        let settingButton = UIBarButtonItem(title: "세팅뷰 이동",image: UIImage(named: "setting"), target: self, action: #selector(tabSettingBTN))
        return settingButton
    }()
    
    private lazy var calendarLabel : UILabel = {
        let calendarLabel = UILabel()
        calendarLabel.text = "캘린더"
        calendarLabel.font = UIFont(name: "SFProDisplay-Bold", size: 33)
        calendarLabel.textColor = UIColor(named: "mainTheme")
        return calendarLabel
    }()
    
    private lazy var writeDiaryButton : UIButton = {
        var config = UIButton.Configuration.plain()
        let writeDiaryButton = UIButton(configuration: config)
        writeDiaryButton.layer.shadowRadius = 3
        writeDiaryButton.layer.borderColor = UIColor(named: "mainCell")?.cgColor
        writeDiaryButton.layer.shadowOpacity = 0.3
        writeDiaryButton.layer.shadowOffset = CGSize(width: 0, height: 0)
        writeDiaryButton.setImage(UIImage(named: "write"), for: .normal)
        writeDiaryButton.addTarget(self, action: #selector(tabWriteDiaryBTN), for: .touchUpInside)
        return writeDiaryButton
    }()
    
    private lazy var calendarView : UICalendarView = {
        var calendarView = UICalendarView()
        calendarView.wantsDateDecorations = true
        return calendarView
    }()
    
    private let safeArea: UIView = {
        let safeAreaView = UIView()
        safeAreaView.backgroundColor = .black
        return safeAreaView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "mainBackground")
        addSubviewsCalendarVC()
        autoLayoutCalendarVC()
        configurateViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        dateSelectCalendar()
        loadDiaries()
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
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "캘린더", style: .plain, target: nil, action: nil)
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
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.top.equalTo(calendarLabel.snp.bottom).offset(20)
        }
        calendarLabel.snp.makeConstraints { make in
            make.top.equalTo(view).offset(50)
            make.left.equalTo(view).offset(16)
            make.size.equalTo(CGSize(width:100, height: 50))
        }
    }
    
    private func loadDiaries() {
        DiaryManager.shared.fetchDiaries { [weak self] (diaries, error) in
            guard let self = self, let diaries = diaries, error == nil else {
                print("일기데이터 로드 실패: \(String(describing: error))")
                return
            }
            
            // 로드된 일기 데이터의 개수를 출력
            print("로드된 일기 개수: \(diaries.count)")
            
            // 로드된 각 일기의 상세 정보를 출력
            diaries.forEach { diary in
                print("제목: \(diary.title), 날짜: \(diary.dateString), 내용: \(diary.content), 나알짜: \(diary.date)")
            }

            self.diaries = diaries
            let updateDateComponents = Set(diaries.compactMap { diary -> DateComponents? in
                // dateString을 Date 객체로 변환합니다.
                guard let diaryDate = DateFormatter.yyyyMMddHHmmss.date(from: diary.dateString) else {
                    return nil
                }
                
                // 변환된 Date 객체로부터 DateComponents를 추출합니다.
                let calendar = Calendar.current
                return calendar.dateComponents([.year, .month, .day], from: diaryDate)
            })
            self.calendarView.reloadDecorations(forDateComponents: Array(updateDateComponents), animated: true)
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
        calendarView.layer.shadowRadius = 3
        calendarView.layer.shadowColor = UIColor(named: "mainTheme")?.cgColor
        calendarView.layer.shadowOpacity = 0.1
        calendarView.layer.shadowOffset = CGSize(width: 0, height: 0)
        calendarView.calendar = .current
        calendarView.locale = .current
        calendarView.timeZone = .current
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
   
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        guard let date = Calendar.current.date(from: dateComponents) else {
            return nil
        }
        let hasDiary = diaries.contains { diary in
            guard let diaryDate = DateFormatter.yyyyMMddHHmmss.date(from: diary.dateString) else { return false }
            let isSameDay = Calendar.current.isDate(diaryDate, inSameDayAs: date)
            return isSameDay
        }
        return hasDiary ? .default(color: .mainTheme, size: .medium) : nil
    }
    
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard let dateComponents = dateComponents,
              let date = Calendar.current.date(from: dateComponents) else {
            return
        }
        
        // 선택된 날짜에 해당하는 일기들을 필터링합니다.
        let selectedDiaries = diaries.filter { diary in
            guard let diaryDate = DateFormatter.yyyyMMddHHmmss.date(from: diary.dateString) else { return false }
            return Calendar.current.isDate(diaryDate, inSameDayAs: date)
        }
        
        // CalendarListVC로 이동하고 선택된 일기들을 전달합니다.
        if !selectedDiaries.isEmpty {
            let calendarListVC = CalendarListVC()
            calendarListVC.selectedDiaries = selectedDiaries // CalendarListVC에 selectedDiaries 프로퍼티 추가 필요
            calendarListVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(calendarListVC, animated: true)
        }
    }
}

extension DateFormatter {
    static let yyyyMMddHHmmss: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        formatter.timeZone = .current
        return formatter
    }()
}
