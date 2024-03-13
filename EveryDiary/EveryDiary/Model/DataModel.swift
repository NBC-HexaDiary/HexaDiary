//
//  DataModel.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/23/24.
//
import Foundation

struct DiaryEntry: Codable {
    var id: String?
    var title: String
    var content: String
    var dateString: String
    var emotion: String
    var weather: String
    var weatherDescription: String?
    var imageURL: String?
    var userID: String?
    var isDeleted: Bool = false
    var deleteDate: Date?
}

extension DiaryEntry {
    var date: Date {
        return DateFormatter.yyyyMMddHHmmss.date(from: dateString) ?? Date()
    }
    
    init(title: String, content: String, date: Date, emotion: String, weather: String, imageURL: String? = nil) {
        self.title = title
        self.content = content
        self.dateString = DateFormatter.yyyyMMddHHmmss.string(from: date)
        self.emotion = emotion
        self.weather = weather
        self.imageURL = imageURL
    }
}

enum CellModel {
    case profileItem(email: String, name: String, image: String?, isLoggedIn: Bool)
    case settingItem(title: String, iconImage: String, number:Int)
    case signOutItem(title: String, iconImage: String, number:Int, isLoggedIn: Bool)
}

extension DateFormatter {
    static func createFormatter(dateFormat: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale(identifier: "ko-KR")
        formatter.timeZone = .current
        return formatter
    }
    
    static let yyyyMMddHHmmss: DateFormatter = createFormatter(dateFormat: "yyyy-MM-dd HH:mm:ss Z")
    static let yyyyMMdd: DateFormatter = createFormatter(dateFormat: "yyyy-MM-dd")
    static let yyyyMM: DateFormatter = createFormatter(dateFormat: "yyyy.MM")
    static let yyyyMMddE: DateFormatter = createFormatter(dateFormat: "yyyy. MM. dd(E)")
}
