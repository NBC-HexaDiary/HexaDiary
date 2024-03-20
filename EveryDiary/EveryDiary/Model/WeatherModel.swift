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
}

struct Main: Decodable {
    let temp: Double
}

struct Weather: Decodable {
    let description: String
}
