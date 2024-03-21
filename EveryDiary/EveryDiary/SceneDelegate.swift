//
//  SceneDelegate.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/21/24.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    var blurEffectView: UIVisualEffectView?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
       
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        let mainVC = TabBarController()
        window?.rootViewController = mainVC
        window?.makeKeyAndVisible()
        
        if UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
            window?.rootViewController = mainVC
        } else {
            let startVC = StartVC()
            startVC.modalPresentationStyle = .fullScreen
            window?.rootViewController?.present(startVC, animated: true, completion: nil)
        }
        
        //강제로 다크모드 해제
        window?.overrideUserInterfaceStyle = .light
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        removeBlurEffect()
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        addBlurEffect()
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        let biometricsEnabled = UserDefaults.standard.bool(forKey: "BiometricsEnabled")
        
        if biometricsEnabled {
            
            BiometricsAuth().authenticateWithBiometrics { success in
                DispatchQueue.main.async {
                    if success {
                        print("성공")
                    } else {
                        print("login 실패")
                    }
                }
            }
        }
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        
    }
}

//MARK: - Blur Effect 메서드
extension SceneDelegate {
    private func addBlurEffect() {
        guard let window = window else { return }
        
        let blurEffect = UIBlurEffect(style: .light)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView?.frame = window.bounds
        blurEffectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        window.addSubview(blurEffectView!)
    }

    private func removeBlurEffect() {
        blurEffectView?.removeFromSuperview()
        blurEffectView = nil
    }
}
