//
//  TapBarController.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/21/24.
//

import UIKit

class TabBarController: UITabBarController {
    let firstVC = UINavigationController.init(rootViewController: DiaryListVC())
    let secondVC = UINavigationController.init(rootViewController: MotivationVC())
    let thirdVC = UINavigationController.init(rootViewController: CalendarVC())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setTabBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    private func setTabBar() {
        self.viewControllers = [firstVC,secondVC,thirdVC]
        
        firstVC.tabBarItem = UITabBarItem(title: "나의 일기",image: UIImage(systemName:"pencil.tip"), tag: 1)
        secondVC.tabBarItem = UITabBarItem(title: "불 켜기",image: UIImage(systemName:"paperplane.fill"), tag: 2)
        thirdVC.tabBarItem = UITabBarItem(title: "캘린더",image: UIImage(systemName:"tray"), tag: 3)

    }
}
