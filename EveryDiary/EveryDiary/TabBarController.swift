//
//  TapBarController.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/21/24.
//

import UIKit

class TabBarController: UITabBarController {
    let firstVC = UINavigationController.init(rootViewController: MainVC())
    let secondVC = UINavigationController.init(rootViewController: MotivationVC())
    let thirdVC = UINavigationController.init(rootViewController: WriteDiaryVC())
    let fourthVC = UINavigationController.init(rootViewController: MapVC())
    let fifthVC = UINavigationController.init(rootViewController: SettingVC())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setTabBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    private func setTabBar() {
        self.viewControllers = [firstVC,secondVC,thirdVC,fourthVC,fifthVC]
        
        firstVC.tabBarItem = UITabBarItem(title: "",image: UIImage(systemName:"pencil.tip"), tag: 1)
        secondVC.tabBarItem = UITabBarItem(title: "",image: UIImage(systemName:"paperplane.fill"), tag: 2)
        thirdVC.tabBarItem = UITabBarItem(title: "",image: UIImage(systemName:"tray"), tag: 3)
        fourthVC.tabBarItem = UITabBarItem(title: "",image: UIImage(systemName:"sunset"), tag: 4)
        fifthVC.tabBarItem = UITabBarItem(title: "",image: UIImage(systemName:"sun.dust.fill"), tag: 5)
    }
}
