//
//  MapManager.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 3/20/24.
//

import UIKit
import CoreLocation
import Contacts
import MapKit

class MapManager: NSObject, CLLocationManagerDelegate {
    static let shared = MapManager()
    weak var presentingViewController: UIViewController?
    var locationManager = CLLocationManager()
    // 위치 정보 업데이트 콜백을 위한 속성
    var onLocationUpdate: ((CLLocationDegrees, CLLocationDegrees) -> Void)?
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkLocationAuthorization()
    }
    
    // 주어진 위도와 경도를 기반으로 장소 이름을 찾는 메서드
    func getPlaceName(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completion: @escaping (String) -> Void) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            guard let placemark = placemarks?.first else {
                print("장소 정보를 찾을 수 없습니다.")
                completion("Unknown Location")
                return
            }
            
            // 장소명이 있는 경우 우선 사용
            if let placeName = placemark.name {
                completion(placeName)
            }
            // 장소명이 없는 경우, 포맷된 주소 사용
            else if let addressDictionary = placemark.postalAddress {
                let formattedAddress = CNPostalAddressFormatter.string(from: addressDictionary, style: .mailingAddress)
                completion(formattedAddress)
            }
            // 둘 다 없는 경우, 알 수 없는 위치 처리
            else {
                completion("Unknown Location")
            }
        }
    }
    
    // Apple Maps에서 특정 위치를 여는 메서드
    func openAppleMaps(latitude: CLLocationDegrees, longitude: CLLocationDegrees, placeName: String? = nil) {
        // 주어진 위치에 대한 주소
        getPlaceName(latitude: latitude, longitude: longitude) { address in
            DispatchQueue.main.async {
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let placemark = MKPlacemark(coordinate: coordinate)
                let mapItem = MKMapItem(placemark: placemark)
                
                mapItem.name = address
                
                // 지도를 열 때 사용할 옵션 설정
                let options: [String: Any] = [
                    MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: coordinate),
                    MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                ]
                mapItem.openInMaps(launchOptions: options)
            }
        }
    }
    
    // Google Maps에서 특정 위치를 여는 메서드
    func openGoogleMapsForPlace(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        // 구글 맵스 앱 URL 스키마 정의
        let googleMapsAppURL = URL(string: "comgooglemaps://?q=\(latitude),\(longitude)&center=\(latitude),\(longitude)&zoom=14&map_action=pin")
        
        // 웹에서 구글 맵스 열기 위한 URL 정의
        let googleMapsWebURL = URL(string: "https://www.google.com/maps/search/?api=1&query=\(latitude),\(longitude)")
        
        // 앱이 설치되어 있는지 확인 후 앱으로 열기
        if let googleMapsAppURL = googleMapsAppURL, UIApplication.shared.canOpenURL(googleMapsAppURL) {
            UIApplication.shared.open(googleMapsAppURL, options: [:], completionHandler: nil)
        }
        // 앱이 설치되어 있지 않은 경우 웹 URL로 대체
        else if let googleMapsWebURL = googleMapsWebURL {
            UIApplication.shared.open(googleMapsWebURL, options: [:], completionHandler: nil)
        }
    }
    func getCurrentLocation(completion: @escaping(CLLocationDegrees, CLLocationDegrees) -> Void) {
        locationManager.requestWhenInUseAuthorization()     // 사용자에게 위치 정보 접근 권한 요청
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            
            // 현재 위치 가져오기
            if let currentLocation = locationManager.location {
                let latitude = currentLocation.coordinate.latitude
                let longitude = currentLocation.coordinate.longitude
                completion(latitude, longitude) // 콜백 함수 호출
            } else {
                print("현재 위치를 가져올 수 없습니다.")
            }
        } else {
            print("위치 서비스가 비활성화되어 있습니다.")
        }
    }
    
    // 앱에 대한 권한 설정이 변경되면 호출(iOS 14 이상)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
    // 앱에 대한 권한 설정이 변경되면 호출(iOS 14 미만)
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
    
    // 위치 서비스 권한 상태 확인 및 요청 메서드
    func checkLocationAuthorization() {
        guard CLLocationManager.locationServicesEnabled() else {
            // 시스템 설정으로 유도
            promptForLocationServiceAuthorization()
            return
        }
        let authorizationStatus: CLAuthorizationStatus
        
        // 앱의 권한 상태를 가져오는 코드(iOS 버전에 따라 분기처리)
        if #available(iOS 14.0, *) {
            authorizationStatus = locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
        // 권한 상태값에 따라 분기처리를 수행하는 메서드 실행
        switch authorizationStatus {
        // 권한 설정을 하지 않은 상태
        case .notDetermined:
            // 권한 요청 보냄
            locationManager.requestWhenInUseAuthorization()
        // 명시적으로 권한을 거부했거나, 위치서비스가 제한된 상태
        case .denied, .restricted:
            promptForLocationServiceAuthorization()
        // 앱을 사용 중일 때 허용, 사용하지 않을 때도 항상 허용
        case .authorizedWhenInUse, .authorizedAlways:
            // manager 인스턴스로 사용자의 위치 획득
            locationManager.startUpdatingLocation()
        @unknown default:
            fatalError("Unhandled authorization status.")
        }
    }
    // 시스템 설정으로 유도하는 커스텀 alert
    func promptForLocationServiceAuthorization() {
        guard let viewController = presentingViewController else { return }
        let requestLocationServiceAlert = UIAlertController(title: "위치 정보 이용", message: "위치 서비스를 사용할 수 없습니다. \n디바이스의 '설정 > 개인정보 보호'에서 위치 서비스를 켜주세요.", preferredStyle: .alert)
        let goSetting = UIAlertAction(title: "설정으로 이동", style: .destructive) { _ in
            if let appSetting = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(appSetting)
            }
        }
        let cancel = UIAlertAction(title: "취소", style: .default)
        requestLocationServiceAlert.addAction(cancel)
        requestLocationServiceAlert.addAction(goSetting)
        
        viewController.present(requestLocationServiceAlert, animated: true)
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.first else { return }
        let latitude = currentLocation.coordinate.latitude
        let longitude = currentLocation.coordinate.longitude
        
        // 위치 정보가 업데이트될 때 콜백 호출
        onLocationUpdate?(latitude, longitude)
        
        // 더 이상 위치 업데이트가 필요없으면 위치 업데이트 중지
        locationManager.stopUpdatingLocation()
    }
}
