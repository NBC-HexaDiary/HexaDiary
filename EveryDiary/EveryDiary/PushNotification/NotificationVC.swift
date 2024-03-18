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
    private var selectedTime: Date?
    private var selectedDaysString: String?
    
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
        tableView.backgroundColor = .mainBackground
        tableView.separatorStyle = .singleLine
        tableView.layer.cornerRadius = 20
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addSubviewsNotificationVC()
        autoLayoutNotificationVC()
        fetchAlarmData()
        refreshdata()
        printAllPendingNotifications()
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
    
    private func fetchAlarmData() {
        isSwitchOn = UserDefaults.standard.bool(forKey: "isSwitchOn")
        if let storedTime = UserDefaults.standard.object(forKey: "selectedTime") as? Date {
            self.selectedTime = storedTime
        }
        if let storedDays = UserDefaults.standard.array(forKey: "selectedDays") as? [Bool] {
            self.selectedDays = storedDays
        }
        if let savedSelectedDaysString = UserDefaults.standard.string(forKey: "selectedDaysString") {
            selectedDaysString = savedSelectedDaysString
        } else {
            selectedDaysString = "반복할 요일을 선택하세요"
        }
    }
    
    private func refreshdata() {
        var newDataSource = [AlertCellModel]()
        newDataSource.append(.switchItem(title: "알림", image: "alarm", switchStatus: isSwitchOn))
        
        if isSwitchOn {
            let timeLabel = selectedTime != nil ? DateFormatter.localizedString(from: selectedTime!, dateStyle: .none, timeStyle: .short) : "시간을 선택하세요"
            newDataSource.append(.dateItem(title: "시간", image: "clock", label: timeLabel, switchStatus: isSwitchOn, isExpanded: isDatePickerVisible))
            if isDatePickerVisible {
                newDataSource.append(.timePicker)
            }
            
            let dayLabel = selectedDaysString ?? "반복할 요일을 선택하세요"
            newDataSource.append(.dateItem(title: "반복", image: "repeat", label: dayLabel, switchStatus: isSwitchOn, isExpanded: isDatePickerVisible))
            if isDayPickerVisible {
                let daysOfWeek = ["일요일" ,"월요일", "화요일", "수요일", "목요일", "금요일", "토요일"]
                for (index, day) in daysOfWeek.enumerated() {
                    newDataSource.append(.dayItem(title: day, isSelected: selectedDays[index]))
                }
            }
        }
        print("Refreshing data with selectedDaysString: \(String(describing: selectedDaysString))")

        self.dataSource = newDataSource
        alertTableView.reloadData()
    }
}

extension NotificationVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.dataSource[indexPath.row] {
            
        case let .switchItem(title, image, isSwitchOn):
            let cell = tableView.dequeueReusableCell(withIdentifier: NotificationCell.id, for: indexPath) as! NotificationCell
            cell.prepare(title: title, iconImage: image, switchStatus: isSwitchOn)
            cell.switchValueChanged = { [weak self] isOn in
                self?.isSwitchOn = isOn
                UserDefaults.standard.set(isOn, forKey: "isSwitchOn")
                UserDefaults.standard.synchronize()
                if isOn == false {
                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    UserDefaults.standard.removeObject(forKey: "isSwitchOn")
                    UserDefaults.standard.removeObject(forKey: "selectedTime")
                    UserDefaults.standard.removeObject(forKey: "selectedDays")
                    UserDefaults.standard.removeObject(forKey: "selectedDaysString")
                    self?.printAllPendingNotifications()
                    print("모든 알림 제거 완료!")
                }
                self?.refreshdata()
            }
            return cell
        case let .dateItem(title, label, image, _, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: DateCell.id, for: indexPath) as! DateCell
            cell.prepare(title: title, iconImage: label, label: image)
            return cell
        case .timePicker:
            let cell = tableView.dequeueReusableCell(withIdentifier: TimePickerCell.id, for: indexPath) as! TimePickerCell
            cell.delegate = self
            return cell
        case let .dayItem(title, isSelected):
            let cell = tableView.dequeueReusableCell(withIdentifier: DayPickerCell.id, for: indexPath) as! DayPickerCell
            cell.delegate = self
            cell.prepare(title: title, isSelected: isSelected)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch dataSource[indexPath.row] {
        case .dateItem(let title, _, _, _, _):
            if title == "시간" {
                isDatePickerVisible.toggle()
                
                if !isDatePickerVisible {
                    updateAndRescheduleNotification()
                    printAllPendingNotifications()
                }
            } else if title == "반복" {
                isDayPickerVisible.toggle()
                
                if !isDayPickerVisible {
                    updateAndRescheduleNotification()
                    printAllPendingNotifications()
                }
            }
            refreshdata()
        case .dayItem(let title, _):
            if let dayIndex = ["일요일" ,"월요일", "화요일", "수요일", "목요일", "금요일", "토요일"].firstIndex(of: title) {
                selectedDays[dayIndex].toggle()
                refreshdata()
            }
        default:
            print("no action")
        }
    }
}

extension NotificationVC: TimePickerCellDelegate, DayPickerCellDelegate {
    func selectTime(_ cell: TimePickerCell, didPickTime date: Date) {
        print("선택된 시간: \(date)")
        self.selectedTime = date
        // 시간 업데이트 후 데이터 새로고침
        refreshdata()
    }
    
    func selectDay(_ cell: DayPickerCell, didPickDay day: String, isSelected: Bool) {
        print("선택된 요일: \(day), 선택 상태: \(isSelected)")
        if let dayIndex = ["일요일", "월요일", "화요일", "수요일", "목요일", "금요일", "토요일"].firstIndex(of: day) {
            selectedDays[dayIndex] = isSelected
        }
        // 선택된 요일 문자열 업데이트
        updateSelectedDaysString()
        // 데이터 새로고침
        refreshdata()
    }
    
    private func updateSelectedDaysString() {
        let daysOfWeek = ["일요일", "월요일", "화요일", "수요일", "목요일", "금요일", "토요일"]
        let selectedDayNames = selectedDays.enumerated().compactMap { index, isSelected -> String? in
            isSelected ? daysOfWeek[index] : nil
        }

        let weekdayCount = selectedDays[1...5].filter({ $0 }).count // 월요일부터 금요일까지 선택된 요일의 수
        let weekendCount = [selectedDays[0], selectedDays[6]].filter({ $0 }).count // 일요일과 토요일이 선택된 요일의 수
        
        // 모든 요일, 주중, 주말 또는 개별 요일을 기반으로 라벨 업데이트
        if selectedDayNames.count == 7 {
            selectedDaysString = "매일"
        } else if weekdayCount == 5 && weekendCount == 0 {
            selectedDaysString = "주중"
        } else if weekdayCount == 0 && weekendCount == 2 {
            selectedDaysString = "주말"
        } else {
            selectedDaysString = selectedDayNames.isEmpty ? "선택된 요일 없음" : selectedDayNames.joined(separator: ", ")
        }
    }
    
    
    func scheduleNotification() {
        guard let selectedTime = selectedTime else { return }
        
        UserDefaults.standard.set(selectedTime, forKey: "selectedTime")
        UserDefaults.standard.set(selectedDays, forKey: "selectedDays")
        UserDefaults.standard.set(selectedDaysString, forKey: "selectedDaysString")
        
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: "오늘의 여정을 기록해보세요", arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: "오늘 하루를 되돌아 보며, 얻은 경험들을 기록해보는 건 어떨까요?", arguments: nil)
        content.sound = UNNotificationSound.default
        
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        
        let daysofWeek = [1,2,3,4,5,6,7] // 1 = 일요일, 7 = 토요일
        for (index, isSelected) in selectedDays.enumerated() where isSelected {
            dateComponents.weekday = daysofWeek[index]
            
            let uniqueIdentifier = "\(daysofWeek[index])" // 각 요일별 고유한 identifier 생성
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: uniqueIdentifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if error != nil {
                    print("알람 스케쥴링 실패")
                } else {
                    print("알람 스케줄링 성공")
                }
            }
        }
    }
    
    func updateAndRescheduleNotification() {
        // 기존의 모든 알림 취소
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        scheduleNotification() // 새로운 설정으로 알림을 재스케줄링하는 메서드 호출
    }
    
    func printAllPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            for request in requests {
                // 각 알림 요청의 식별자
                print("알림 ID: \(request.identifier)")
                
                // 알림의 콘텐츠 세부 사항
                print("알림 제목: \(request.content.title)")
                print("알림 본문: \(request.content.body)")
                
                // 알림 예정 시간 및 요일 확인
                if let trigger = request.trigger as? UNCalendarNotificationTrigger, let nextTriggerDate = trigger.nextTriggerDate() {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    print("알림 예정 시간: \(dateFormatter.string(from: nextTriggerDate))")
                    
                    if let weekday = trigger.dateComponents.weekday {
                        // Calendar.current.weekdaySymbols는 요일을 문자열 배열로 반환합니다. 0은 일요일, 1은 월요일을 나타냅니다.
                        let weekdaySymbol = Calendar.current.weekdaySymbols[weekday - 1]
                        print("알림 예정 요일: \(weekdaySymbol)")
                    }
                }
                print("--------------------------------")
            }
            
            if requests.isEmpty {
                print("보류 중인 알림이 없습니다.")
            }
        }
    }
}
