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
    var imageURL: String?
    var userID: String?
}

extension DiaryEntry {
    var date: Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.date(from: dateString) ?? Date()
    }
    
    init(title: String, content: String, date: Date, emotion: String, weather: String, imageURL: String? = nil) {
        self.title = title
        self.content = content
        self.dateString = "\(date)"
        self.emotion = emotion
        self.weather = weather
        self.imageURL = imageURL
    }
}

enum CellModel {
    case profileItem(email: String, name: String, image: String?)
    case settingItem(title: String, iconImage: String, number:Int)
    case signOutItem(title: String, iconImage: String, number:Int)
}
