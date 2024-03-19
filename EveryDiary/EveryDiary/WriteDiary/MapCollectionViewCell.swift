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
    var captureTime: String?
    var location: String?
}
struct LocationInfo {
    var latitude: CLLocationDegrees
    var longitude: CLLocationDegrees
}

protocol MapCollectionViewCellDelegate: AnyObject {
    func mapViewCell(_ cell: MapCollectionViewCell, didTapAnnotationWithLatitude latitude: CLLocationDegrees, longitude: CLLocationDegrees)
}

class MapCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "MapCollectionViewCell"
    weak var delegate: MapCollectionViewCellDelegate?
    
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
}

extension MapCollectionViewCell: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }
        delegate?.mapViewCell(self, didTapAnnotationWithLatitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        print(annotation.coordinate.latitude)
        print(annotation.coordinate.longitude)
    }
}
