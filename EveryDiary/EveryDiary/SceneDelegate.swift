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
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        let biometricsEnabled = UserDefaults.standard.bool(forKey: "BiometricsEnabled")
        
        if biometricsEnabled {
            self.addBlurEffect()
            
            BiometricsAuth().authenticateWithBiometrics { [weak self] success in
                DispatchQueue.main.async {
                    if success {
                        self?.removeBlurEffect()
                    } else {
                        print("login 실패")
                    }
                }
            }
        }
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}

//MARK: - Blur Effect 메서드
extension SceneDelegate {
    private func addBlurEffect() {
        guard let window = window else { return }
        
        let blurEffect = UIBlurEffect(style: .dark)
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
