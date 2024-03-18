//
//  NotificationVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/28/24.
//

import UIKit
import UserNotifications

import SnapKit

class NotificationVC: UIViewController {
    
    private var isSwitchOn = false
    private var isDatePickerVisible = false
    private var isDayPickerVisible = false
    private var selectedDays: [Bool] = Array(repeating: false, count: 7)
    
    private var dataSource = [AlertCellModel]()
    
    private lazy var alertTableView : UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(NotificationCell.self, forCellReuseIdentifier: NotificationCell.id)
        tableView.register(DateCell.self, forCellReuseIdentifier: DateCell.id)
        tableView.register(TimePickerCell.self, forCellReuseIdentifier: TimePickerCell.id)
        tableView.register(DayPickerCell.self, forCellReuseIdentifier: DayPickerCell.id)
        tableView.isScrollEnabled = false
        tableView.backgroundColor = .mainCell
        tableView.separatorStyle = .singleLine
        tableView.layer.cornerRadius = 20
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviewsNotificationVC()
        autoLayoutNotificationVC()
        refreshdata()
        
    }
    
    private func addSubviewsNotificationVC() {
        view.backgroundColor = .mainBackground
        view.addSubview(alertTableView)
    }
    
    private func autoLayoutNotificationVC() {
        alertTableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(10)        }
    }
    
    private func setNavigationBar() {
        navigationItem.title = "알림"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "알림", style: .plain, target: nil, action: nil)
    }
    
    private func refreshdata() {
        var newDataSource = [AlertCellModel]()
        newDataSource.append(.switchItem(title: "알림", image: "alarm", switchStatus: isSwitchOn))
        
        if isSwitchOn {
            newDataSource.append(.dateItem(title: "시간", image: "clock", label: "시간을 선택하세요", switchStatus: isSwitchOn, isExpanded: isDatePickerVisible))
            if isDatePickerVisible {
                newDataSource.append(.timePicker)
            }
            
            newDataSource.append(.dateItem(title: "반복", image: "repeat", label: "반복할 요일을 선택하세요", switchStatus: isSwitchOn, isExpanded: isDatePickerVisible))
            if isDayPickerVisible {
                let daysOfWeek = ["월요일", "화요일", "수요일", "목요일", "금요일", "토요일", "일요일"]
                for (index, day) in daysOfWeek.enumerated() {
                    newDataSource.append(.dayItem(title: day, isSelected: selectedDays[index]))
                }
            }
        }
        
        self.dataSource = newDataSource
        alertTableView.reloadData()
    }
    
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("승인 성공")
            } else {
                print("승인 실패")
            }
        }
    }
    
    private func redirectToSettings() {
        let alert = UIAlertController(title: "알림", message: "알림 기능을 이용하시려면 알림 권한을 허용해 주세요", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default, handler: { _ in
            if let settingURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingURL, options: [:], completionHandler: nil)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
}

extension NotificationVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("\(dataSource)")
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.dataSource[indexPath.row] {
            
        case let .switchItem(title, image, isSwitchOn):
            let cell = tableView.dequeueReusableCell(withIdentifier: NotificationCell.id, for: indexPath) as! NotificationCell
            cell.prepare(title: title, iconImage: image, switchStatus: isSwitchOn)
            cell.switchValueChanged = { [weak self] isOn in
                self?.isSwitchOn = isOn
                self?.refreshdata()
            }
            return cell
        case let .dateItem(title, label, image, _, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: DateCell.id, for: indexPath) as! DateCell
            cell.prepare(title: title, iconImage: label, label: image)
            return cell
        case .timePicker:
            let cell = tableView.dequeueReusableCell(withIdentifier: TimePickerCell.id, for: indexPath) as! TimePickerCell
            return cell
        case let .dayItem(title, isSelected):
            let cell = tableView.dequeueReusableCell(withIdentifier: DayPickerCell.id, for: indexPath) as! DayPickerCell
            cell.prepare(title: title, isSelected: isSelected)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch dataSource[indexPath.row] {
        case .dateItem(let title, _, _, _, _):
            if title == "시간" {
                isDatePickerVisible.toggle()
            } else if title == "반복" {
                isDayPickerVisible.toggle()
            }
            refreshdata()
        case .dayItem(let title, _):
            if let dayIndex = ["월요일", "화요일", "수요일", "목요일", "금요일", "토요일", "일요일"].firstIndex(of: title) {
                selectedDays[dayIndex].toggle()
                refreshdata()
            }
        default:
            print("no action")
        }
    }
}

