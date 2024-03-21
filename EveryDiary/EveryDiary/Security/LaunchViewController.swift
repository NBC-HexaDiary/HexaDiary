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
        
        if shouldAttemptBiometricAuthentication() {
            authenticateWithBiometrics()
        } else {
            navigateToMainScreen()
        }
    }
    
    private func shouldAttemptBiometricAuthentication() -> Bool {
        return UserDefaults.standard.bool(forKey: "BiometricsEnabled")
    }
    
    private func navigateToMainScreen() {
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
                DispatchQueue.main.async {
                    self?.navigateToMainScreen()
                }
            } else {
                DispatchQueue.main.async {
                    print("인증 실패")
                }
            }
        }
    }
}
