//
//  SceneDelegate.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/21/24.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
            window = UIWindow(windowScene: windowScene)
            
            let mainVC = TabBarController() // 앱의 메인 화면
            var rootViewController: UIViewController
            
            // UserDefaults를 사용하여 최초 실행 여부를 확인합니다.
            if UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
                // 최초 실행이 아니라면 탭 바 컨트롤러를 보여줍니다.
                rootViewController = mainVC
            } else {
                // 최초 실행이라면 스타트 뷰 컨트롤러를 보여줍니다.
                let startVC = StartVC() // 최초 실행 시 보여줄 화면
                rootViewController = UINavigationController(rootViewController: startVC)
            }
            
            window?.rootViewController = rootViewController
            window?.makeKeyAndVisible()
//        guard let windowScene = (scene as? UIWindowScene) else { return }
//        window = UIWindow(windowScene: windowScene)
//        let mainVC = TabBarController()
//        let navigationController = UINavigationController(rootViewController: mainVC)
//        window?.rootViewController = navigationController
//        window?.makeKeyAndVisible()

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
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

