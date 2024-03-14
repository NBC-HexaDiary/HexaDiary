//
//  NotificationCenter.swift
//  EveryDiary
//
//  Created by Dahlia on 3/8/24.
//

import Foundation
import UserNotifications

extension UNUserNotificationCenter {
    func addNotificationRequest() {
        let content = UNMutableNotificationContent()
        content.title = "일기써라"
        content.body = "빨리써라"
        content.sound = .default
        content.badge = 1
        
        var dateComponents = DateComponents()
        dateComponents.hour = 21
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "notification", content: content, trigger: trigger)
        
        self.add(request) { error in
            if let error = error {
                print("알림 요청에 실패하였습니다: \(error.localizedDescription)")
            } else {
                print("알림이 성공적으로 추가되었습니다.")
            }
        }
    }
}
