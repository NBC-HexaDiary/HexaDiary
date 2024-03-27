//
//  WeatherService.swift
//  EveryDiary
//
//  Created by Dahlia on 2/27/24.
//
import CoreLocation
import Foundation

enum NetworkError: Error {
    case badUrl
    case noData
    case decodingError
}

class WeatherService: NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    let apiKey = Bundle.main.apiKey
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    func getWeather(completion: @escaping (Result<WeatherResponse, NetworkError>) -> Void) {
        guard let location = locationManager.location else {
            return completion(.failure(.noData))
        }
        
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(apiKey)&lang=kr&units=metric"
        
        guard let url = URL(string: urlString) else {
            return completion(.failure(.badUrl))
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                return completion(.failure(.noData))
            }
            
            do {
                let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
                completion(.success(weatherResponse))
            } catch {
                completion(.failure(.decodingError))
            }
        }.resume()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}
