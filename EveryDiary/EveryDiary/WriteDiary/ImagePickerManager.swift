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
    func timeAndLocationChoiceAlert(time: String, address: String, completion: @escaping (Bool) -> Void)
}

class ImagePickerManager: NSObject, PHPickerViewControllerDelegate {
    weak var delegate: ImagePickerDelegate?
    weak var presentingViewController: UIViewController?
    
    // 이미 선택했던 사진들을 구분하는 assetIdentifier를 저장하기 위한 변수 선언. showsDiary에서 업데이트
    var selectedPhotoIdentifiers: [String] = []
    
    // PHPicker를 호출하는 메서드
    func presentImagePicker(from viewController: UIViewController, selectedPhotoIdentifiers: [String]) {
        self.selectedPhotoIdentifiers = selectedPhotoIdentifiers
        self.presentingViewController = viewController
        
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
                        var locationInfo: LocationInfo?
                        if let location = location {
                            locationInfo = LocationInfo(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                        } else {
                            locationInfo = nil
                        }
                        let locationString = location.map { "\($0.coordinate.latitude), \($0.coordinate.longitude)" }
                        
                        // 위치 정보가 있을 경우에만 locationInfo생성
                        let imageLocationInfo = ImageLocationInfo(
                            image: image,
                            locationInfo: locationInfo,
                            assetIdentifier: assetIdentifier,
                            captureTime: captureTime,
                            location: locationString
                        )
                        print("imageLocationInfo: \(imageLocationInfo)")
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
            print("group.notify")
            guard let self = self, let firstImageLocationInfo = newImagesLocationInfo.first else { return }
            // identifiers 저장
            self.selectedPhotoIdentifiers = newResultsIdentifiers
            // 위치 정보 유무에 따라 다음 단계 처리
            if let firstImageLocationInfo = newImagesLocationInfo.first, let location = firstImageLocationInfo.locationInfo {
                // 위치 정보가 있다면
                let mapManger = MapManager()
                mapManger.getPlaceName(latitude: location.latitude, longitude: location.longitude) { address in
                    let time = firstImageLocationInfo.captureTime ?? self.formattedDateString(for: Date())
                    // 위치 정보가 있는 경우에만 timeAndLocationChoiceAlert 호출
                    // 선택 사진의 시간과 위치 정보를 사용할 것인지 확인하는 메서드
                    self.delegate?.timeAndLocationChoiceAlert(time: time, address: address) { useMetadata in }
                    // 새로운 선택결과를 delegate 메서드로 전달
                    self.delegate?.didPickImages(newImagesLocationInfo, retainedIdentifiers: newResultsIdentifiers)
                }
            } else {
                // 위치 정보가 없는 경우 didPickImages만 호출
                self.delegate?.didPickImages(newImagesLocationInfo, retainedIdentifiers: newResultsIdentifiers)
                if let presentingViewController = self.presentingViewController {
                    let alert = UIAlertController(title: "위치정보 없음", message: "사진의 위치정보가 없습니다. 사용자의 현재 위치로 대체됩니다.", preferredStyle: .alert)
                    presentingViewController.present(alert, animated: true, completion: nil)
                    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { _ in alert.dismiss(animated: true, completion: nil)})
                }
            }
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
        let requestPhotoServiceAlert = UIAlertController(title: "사진을 첨부할 수 없습니다.", message: "사진을 추가하기 위해 사진 접근 권한을 수정해주세요.", preferredStyle: .alert)
        requestPhotoServiceAlert.addAction(UIAlertAction(title: "취소", style: .cancel))
        requestPhotoServiceAlert.addAction(UIAlertAction(title: "설정", style: .default) { _ in
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(settingsURL)
        })
        viewController.present(requestPhotoServiceAlert, animated: true)
    }
    // Firestore 날짜저장 형식
    func formattedDateString(for date: Date) -> String {
        return DateFormatter.yyyyMMddHHmmss.string(from: date)
    }
}
