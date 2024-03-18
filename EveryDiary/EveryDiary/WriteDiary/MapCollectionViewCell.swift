//
//  MapCollectionViewCell.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 3/15/24.
//

import MapKit
import UIKit

struct ImageLocationInfo {
    var image: UIImage
    var locationInfo: LocationInfo?
    var assetIdentifier: String?
}
struct LocationInfo {
    var latitude: CLLocationDegrees
    var longitude: CLLocationDegrees
}

class MapCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "MapCollectionViewCell"
    
    var mapView: MKMapView = {
        let view = MKMapView()
        view.mapType = .mutedStandard
        view.isZoomEnabled = false
        view.isScrollEnabled = false
        view.isUserInteractionEnabled = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupMapView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupMapView() {
        addSubview(mapView)
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    func configureMapWith(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        mapView.addAnnotation(annotation)
        
        // 지도 중심으로 핀 위치 이동
        let region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 300, longitudinalMeters: 300)
        mapView.setRegion(region, animated: false)
    }
}
