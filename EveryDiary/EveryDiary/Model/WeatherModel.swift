//
//  WeatherModel.swift
//  EveryDiary
//
//  Created by Dahlia on 2/27/24.
//
import Foundation

struct WeatherResponse: Decodable {
    let weather: [Weather]
    let main: Main
    let name: String
}

struct Main: Decodable {
    let temp: Double
}

struct Weather: Decodable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}
