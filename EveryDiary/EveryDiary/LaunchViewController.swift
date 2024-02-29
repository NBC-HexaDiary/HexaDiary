//
//  LaunchViewController.swift
//  EveryDiary
//
//  Created by Dahlia on 2/29/24.
//

import UIKit

import LocalAuthentication

class LaunchViewController: UIViewController {
    let auth = BiometricsAuth()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        auth.delegate = self
        auth.execute()
    }
    
    func showNextScreen() {
        DispatchQueue.main.async { [weak self] in
            guard let navigationController = self?.navigationController else { return }
            let diaryListVC = DiaryListVC()
            diaryListVC.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(diaryListVC, animated: true)
        }
    }
}

extension LaunchViewController: AuthenticateStateDelegate {
    func didUpdateState(_ state: BiometricsAuth.AuthenticationState) {
        if case .loggedIn = state {
            print("로그인 성공")
            showNextScreen()
        }
    }
}
