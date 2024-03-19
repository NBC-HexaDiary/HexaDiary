//
//  MapManager.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 3/20/24.
//

import Contacts
import MapKit

class MapManager {
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
}
