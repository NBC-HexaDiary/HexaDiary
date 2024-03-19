//
//  ImagePickerManager.swift
//  EveryDiary
//
//  Created by t2023-m0026 on 3/19/24.
//

import Photos
import PhotosUI
import UIKit

// 이미지 선택 완료 시 처리를 위한 프로토콜 정의
protocol ImagePickerDelegate: AnyObject {
    func didPickImages(_ imagesLocationInfo: [ImageLocationInfo], retainedIdentifiers: [String])
}

class ImagePickerManager: NSObject, PHPickerViewControllerDelegate {
    weak var delegate: ImagePickerDelegate?
    
    // 이미 선택했던 사진들을 구분하는 assetIdentifier를 저장하기 위한 변수 선언. showsDiary에서 업데이트
    var selectedPhotoIdentifiers: [String] = []
    
    // PHPicker를 호출하는 메서드
    func presentImagePicker(from viewController: UIViewController, selectedPhotoIdentifiers: [String]) {
        self.selectedPhotoIdentifiers = selectedPhotoIdentifiers
        
        // PHPicker의 설정
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 3        // 최대 선택 가능한 이미지 수
        configuration.selection = .ordered      // 선택 순서를 유지
        configuration.filter = .images          // 이미지만 첨부가능
        configuration.preselectedAssetIdentifiers = selectedPhotoIdentifiers    // 이전에 선택된 항목을 사전에 선택
        
        // PHPickerViewController 인스턴스 생성 및 표시
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        viewController.present(picker, animated: true)
    }
    
    // 이미지 선택이 완료되었을 때 호출되는 메서드
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)  // 선택완료(picker 닫기)
        
        // 새로 선택한 이미지와 메타데이터를 담는 배열
        var newImagesLocationInfo: [ImageLocationInfo] = []
        // 새로운 결과의 식별자 배열
        let newResultsIdentifiers = results.compactMap { $0.assetIdentifier }
        
        let group = DispatchGroup() // 모든 비동기작업을 추적하기 위한 DispatchGroup
        
        // 선택한 각 사진들에 대하여
        for result in results {
            // 새로 선택된 이미지의 assetIdentifier 저장
            guard let assetIdentifier = result.assetIdentifier else { continue }
            let itemProvider = result.itemProvider
            group.enter()   // 비동기 작업 시작
            
            // itemProver를 통해 선택한 이미지에 대한 로딩 시작
            if itemProvider.canLoadObject(ofClass: UIImage.self) {  // itemProvider가 UIImage 객체를 로드할 수 있는지 확인
                itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                    defer { group.leave() } // 작업 완료 알림
                    guard let image = image as? UIImage else { return }
                    
                    // 선택한 이미지의 PHAsset을 조회하여 위치 정보와 촬영 시간을 추출
                    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
                    
                    if let asset = assets.firstObject {
                        let captureTime = asset.creationDate?.description
                        let location = asset.location
                        let locationInfo = location.map {LocationInfo(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)}
                        let locationString = location.map { "\($0.coordinate.latitude), \($0.coordinate.longitude)" }
                        
                        // 위치 정보가 있을 경우에만 locationInfo생성
                        let imageLocationInfo = ImageLocationInfo(
                            image: image,
                            locationInfo: locationInfo,
                            assetIdentifier: assetIdentifier,
                            captureTime: captureTime,
                            location: locationString
                        )
                        
                        DispatchQueue.main.async {
                            newImagesLocationInfo.append(imageLocationInfo)
                        }
                    }
                }
            } else {
                group.leave()
            }
        }
        // 모든 선택 작업이 완료되면, delegate으로 결과 전달
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            // identifiers 저장
            self.selectedPhotoIdentifiers = newResultsIdentifiers
            // 새로운 선택결과를 delegate 메서드로 전달
            self.delegate?.didPickImages(newImagesLocationInfo, retainedIdentifiers: newResultsIdentifiers)
        }
    }
}

extension ImagePickerManager {
    // 사진 라이브러리 접근권한 요청 메서드
    func requestPhotoLibraryAccess(from viewController: UIViewController) {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    // 접근권한이 있는 상태라면 PHPickerViewController 호출
                    self?.presentImagePicker(from: viewController, selectedPhotoIdentifiers: self?.selectedPhotoIdentifiers ?? [])
                case .denied, .restricted, .notDetermined:
                    // 접근권한이 없는 경우, 설정으로 유도하는 UIAlert 표시
                    self?.showSettingsAlert(from: viewController)
                @unknown default:
                    print("Unknown case of PHPhotoLibrary authorization")
                }
            }
        }
    }
    
    // 접근 권한이 없을 경우 설정 화면으로 유도하는 AlertController
    private func showSettingsAlert(from viewController: UIViewController) {
        let alert = UIAlertController(title: "사진을 첨부할 수 없습니다.", message: "사진을 추가하기 위해 사진 접근 권한을 수정해주세요.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "설정", style: .default) { _ in
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(settingsURL)
        })
        viewController.present(alert, animated: true)
    }
}
