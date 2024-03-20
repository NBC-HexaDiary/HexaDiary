//
//  LaunchViewController.swift
//  EveryDiary
//
//  Created by Dahlia on 2/29/24.
//

import UIKit

import LocalAuthentication

class LaunchViewController: UIViewController {
    
    let biometricsAuth = BiometricsAuth()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .mainTheme
        
        // 최초 실행 시 또는 생체인식 잠금이 활성화되어 있는 경우에만 생체인증을 시도합니다.
        if shouldAttemptBiometricAuthentication() {
            authenticateWithBiometrics()
        } else {
            // 생체인식 잠금이 비활성화되어 있거나, 이전에 로그인된 사용자의 경우 메인 화면으로 이동합니다.
            navigateToMainScreen()
        }
    }
    
    private func shouldAttemptBiometricAuthentication() -> Bool {
        // UserDefaults에서 생체인식 잠금 스위치의 상태를 읽어옵니다.
        return UserDefaults.standard.bool(forKey: "BiometricsEnabled")
    }
    
    private func navigateToMainScreen() {
        // 탭 바 컨트롤러를 생성하여 메인 화면으로 이동합니다.
        let mainVC = TabBarController()
        mainVC.modalPresentationStyle = .fullScreen
        self.present(mainVC, animated: true)
        
        if let navigationController = mainVC.navigationController {
            navigationController.popToRootViewController(animated: false)
        }
    }
    
    private func authenticateWithBiometrics() {
        biometricsAuth.authenticateWithBiometrics { [weak self] success in
            if success {
                // 생체 인증 성공 시 메인 화면으로 이동합니다.
                DispatchQueue.main.async {
                    self?.navigateToMainScreen()
                }
            } else {
                // 생체 인증 실패 시 알림을 표시하거나 다른 로그인 방법을 제공할 수 있습니다.
                DispatchQueue.main.async {
                    print("인증 실패")
                }
            }
        }
    }
}
