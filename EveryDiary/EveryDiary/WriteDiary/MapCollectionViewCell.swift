//
//  MapCollectionViewCell.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 3/15/24.
//

import MapKit

protocol MapCollectionViewCellDelegate: AnyObject {
    func mapViewCell(_ cell: MapCollectionViewCell, didTapAnnotationWithLatitude latitude: CLLocationDegrees, longitude: CLLocationDegrees)
}

class MapCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "MapCollectionViewCell"
    weak var delegate: MapCollectionViewCellDelegate?
    var currentLocationInfo: String?
    
    var mapView: MKMapView = {
        let view = MKMapView()
        view.mapType = .standard
        view.isZoomEnabled = true
        view.isScrollEnabled = false
        view.isUserInteractionEnabled = true
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupMapView()
        setupShadow()
        mapView.delegate = self
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
    private func setupShadow() {
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.1
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowRadius = 8.0
        self.layer.masksToBounds = false
    }
    // 사진 정보를 맵에 보여줄 때 사용될 메서드
    func configureMapWith(locationsInfo: [LocationInfo]) {
        var annotations = [MKPointAnnotation]()
        
        for location in locationsInfo {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            mapView.addAnnotation(annotation)
            annotations.append(annotation)
        }
        
        // 모든 annotation이 보이도록 지도의 영역 조절
        mapView.showAnnotations(annotations, animated: false)
    }
    // DataModel에 저장될 사용자의 현재 위치를 맵에 보여줄 때 사용될 메서드
    func configureMapCellWithCurrentLocation() {
        guard let currentLocationInfo = currentLocationInfo else {
            print("현재 위치 정보가 없습니다.")
            return
        }
        
        let components = currentLocationInfo.split(separator: ", ")
        guard components.count == 2,
              let latitude = CLLocationDegrees(components[0]),
              let longitude = CLLocationDegrees(components[1]) else {
            print("잘못된 위치 정보 형식입니다.")
            return
        }
        let locationInfo = LocationInfo(latitude: latitude, longitude: longitude)
        configureMapWith(locationsInfo: [locationInfo])
    }
    
    func configureWithPrefetchedData(_ mapViewData: MapViewData) {
        mapView.removeAnnotations(mapView.annotations) // 기존 애너테이션 제거
        mapView.addAnnotations(mapViewData.annotation) // 새로운 애너테이션 추가

        // 맵 뷰를 첫 번째 애너테이션의 위치로 이동
        if let firstAnnotation = mapViewData.annotation.first {
            let region = MKCoordinateRegion(center: firstAnnotation.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(region, animated: false)
        }
    }
}

extension MapCollectionViewCell: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }
        delegate?.mapViewCell(self, didTapAnnotationWithLatitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        print(annotation.coordinate.latitude)
        print(annotation.coordinate.longitude)
    }
}
