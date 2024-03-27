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
    func willStartImageLoading()    // 로딩 인디케이터를 불러오기 위한 메서드
    func didFinishImageLoading()    // 로딩 인디케이터를 제거하기 위한 메서드
}

class ImagePickerManager: NSObject, PHPickerViewControllerDelegate {
    weak var delegate: ImagePickerDelegate?
    weak var presentingViewController: UIViewController?
     
    // 이미 선택했던 사진들을 구분하는 assetIdentifier를 저장하기 위한 변수 선언. showsDiary에서 업데이트
    var selectedPhotoIdentifiers: [String] = []
    
    // PHPicker를 호출하는 메서드
    func presentImagePicker(from viewController: UIViewController) {
        self.presentingViewController = viewController
        let configuration = createPickerConfiguration(with: self.selectedPhotoIdentifiers)
        // PHPickerViewController 인스턴스 생성 및 표시
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        viewController.present(picker, animated: true)
    }
    // PHPicker 설정
    private func createPickerConfiguration(with identifiers: [String]) -> PHPickerConfiguration {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 3        // 최대 선택 가능한 이미지 수
        configuration.selection = .ordered      // 선택 순서를 유지
        configuration.filter = .images          // 이미지만 첨부가능
        configuration.preselectedAssetIdentifiers = identifiers
        return configuration
    }
    
    // PHPickerViewControllerDelegate 메서드
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)          // 선택완료(picker 닫기)
        processPickedImages(results: results)   // 이미지 처리 시작
    }
    
    private func processPickedImages(results: [PHPickerResult]) {
        self.delegate?.willStartImageLoading()                                  // 이미지 불러오기 시작 알림
        var newImagesLocationInfo: [Int: ImageLocationInfo] = [:]               // 새로 선택한 이미지와 메타데이터의 순서를 담는 딕셔너리
        let newResultsIdentifiers = results.compactMap { $0.assetIdentifier }   // 새로운 결과의 식별자 배열
        
        // 모든 비동기작업을 추적하기 위한 DispatchGroup
        let group = DispatchGroup()
        print("PHPicker가 선택한 identifier: \(newResultsIdentifiers)")
        
        // 선택한 각 사진들에 대하여
        for (index, result) in results.enumerated() {
            // 새로 선택된 이미지의 assetIdentifier 저장
            guard let assetIdentifier = result.assetIdentifier else { continue }
            group.enter()   // 비동기 작업 시작
            
            loadImageAndMetadata(from: result, with: assetIdentifier) { imageLocationInfo in
                if let info = imageLocationInfo {
                    newImagesLocationInfo[index] = (info)
                }
                group.leave()
            }
        }
        // 모든 선택 작업이 완료되면, delegate으로 결과 전달
        group.notify(queue: .main) { [weak self] in
            // 임시 딕셔너리를 배열로 다시 변환하고 원래의 순서대로 정렬
            let orderedImagesLocationInfo = newImagesLocationInfo.sorted(by: { $0.key < $1.key}).map { $0.value }
            self?.handleImageSelectionCompleted(with: orderedImagesLocationInfo, identifiers: newResultsIdentifiers)
            self?.delegate?.didFinishImageLoading()     // 이미지 불러오기 완료 알림
        }
    }
    private func loadImageAndMetadata(from result: PHPickerResult, with identifier: String, completion: @escaping (ImageLocationInfo?) -> Void) {
        // itemProver를 통해 선택한 이미지에 대한 로딩 시작
        result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
            guard let image = object as? UIImage else {
                completion(nil)
                return
            }
            
            // 선택한 이미지의 PHAsset을 조회하여 위치 정보와 촬영 시간을 추출
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            guard let asset = assets.firstObject else {
                completion(nil)
                return
            }
            
            let captureTime = asset.creationDate?.description
            let locationInfo = asset.location.flatMap { LocationInfo(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)}
            let locationString = asset.location.map { "\($0.coordinate.latitude), \($0.coordinate.longitude)" }
            
            // 위치 정보가 있을 경우에만 locationInfo생성
            let imageLocationInfo = ImageLocationInfo(
                image: image,
                locationInfo: locationInfo,
                assetIdentifier: identifier,
                captureTime: captureTime,
                location: locationString
            )
            completion(imageLocationInfo)
        }
    }
    private func handleImageSelectionCompleted(with imagesLocationInfo: [ImageLocationInfo], identifiers: [String]) {
        // 선택된 이미지 식별자 업데이트
        self.selectedPhotoIdentifiers = identifiers
        
        // 위치정보를 가진 첫번째 이미지를 선택
        if let firstImageWithLocation = imagesLocationInfo.first(where: { $0.locationInfo != nil }) {
            // 위치 정보가 있다면
            print("위치정보 있음")
            let mapManger = MapManager()
            if let locationInfo = firstImageWithLocation.locationInfo {
                mapManger.getPlaceName(latitude: locationInfo.latitude, longitude: locationInfo.longitude) { address in
                    let time = firstImageWithLocation.captureTime ?? self.formattedDateString(for: Date())
                    // 위치 정보가 있는 경우에만 timeAndLocationChoiceAlert 호출
                    // 선택 사진의 시간과 위치 정보를 사용할 것인지 확인하는 메서드
                    self.delegate?.timeAndLocationChoiceAlert(time: time, address: address) { useMetadata in
                        print("결과전달: \(imagesLocationInfo), \(identifiers)")
                        // 새로운 선택결과를 delegate 메서드로 전달
                        self.delegate?.didPickImages(imagesLocationInfo, retainedIdentifiers: identifiers)
                    }
                }
            }
        } else {
            // 위치 정보가 없는 경우
            print("위치정보 없음")
            print("결과전달: \(imagesLocationInfo), \(identifiers)")
            // 위치 정보가 없는 경우 didPickImages만 호출
            self.delegate?.didPickImages(imagesLocationInfo, retainedIdentifiers: identifiers)
            guard let viewController = presentingViewController else {
                print("PresentingViewController is nil")
                return
            }
            TemporaryAlert.presentTemporaryMessage(with: "위치정보 없음.", message: "사진의 위치정보가 없습니다.\n사용자의 현재 위치로 대체됩니다.", interval: 2.0, for: viewController)
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
                    self?.presentImagePicker(from: viewController)
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
        let requestPhotoServiceAlert = UIAlertController(title: "'EveryDiary'가 사용자의 사진에 접근하려고 합니다.", message: "여러분의 일기에 사진을 추가하기 위해 사진 라이브러리에 접근하도록 권한을 허용해주세요.", preferredStyle: .alert)
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
    func updateSelectedPhotoIdentifier(_ identifiers: [String]) {
        self.selectedPhotoIdentifiers = identifiers
    }
}
