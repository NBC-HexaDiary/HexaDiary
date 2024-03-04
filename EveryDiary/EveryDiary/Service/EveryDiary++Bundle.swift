//
//  EveryDiary++Bundle.swift
//  EveryDiary
//
//  Created by Dahlia on 2/28/24.
//
import Foundation

extension Bundle {
    var apiKey: String {
        guard let file = self.path(forResource: "Api", ofType: "plist") else { return "" }
        guard let resource = NSDictionary(contentsOfFile: file) else { return "" }
        guard let key = resource["OPENWEATHERMAP_KEY"] as? String else { fatalError("Api.plsit에 OPENWEATHERMAP_KEY 설정을 해주세요")}
        return key
    }
}
