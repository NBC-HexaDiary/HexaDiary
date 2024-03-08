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
        customTabBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    private func setTabBar() {
        self.viewControllers = [firstVC,secondVC,thirdVC]
        
        firstVC.tabBarItem = UITabBarItem(title: "나의 일기",image: UIImage(named: "diary"), tag: 1)
        secondVC.tabBarItem = UITabBarItem(title: "여정",image: UIImage(named: "building"), tag: 2)
        thirdVC.tabBarItem = UITabBarItem(title: "캘린더",image: UIImage(named: "calendar"), tag: 3)
    }
    
    private func customTabBar() {
        let tabBar: UITabBar = self.tabBar
        tabBar.tintColor = .mainTheme
        tabBar.unselectedItemTintColor = .subText
        tabBar.backgroundColor = .mainCell
        tabBar.layer.borderColor = UIColor(named: "mainTheme")?.cgColor
        tabBar.layer.borderWidth = 0.2
    }
}
