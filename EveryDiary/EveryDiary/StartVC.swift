//
//  StartVC.swift
//  EveryDiary
//
//  Created by Dahlia on 3/13/24.
//

import UIKit
import FirebaseAuth

#Preview {
    StartVC()
}
class StartVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .mainTheme
        if !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
            view.addSubview(startButton)
        } else {
            showMainScreen()
        }
        startButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
    
    lazy var startButton : UIButton = {
        var config = UIButton.Configuration.plain()
        let button = UIButton(configuration: config)
        button.setTitle("시작하기", for: .normal)
        button.backgroundColor = .searchText
        button.setTitleColor(.white, for: .normal) // 폰트 색상 변경
        button.layer.cornerRadius = 8 // 각을 둥글게 만드는 부분
        button.addTarget(self, action: #selector(tabStartButton), for: .touchUpInside)
        return button
    }()
    
    @objc private func tabStartButton() {
        DiaryManager.shared.authenticateAnonymouslyIfNeeded { error in
            if let error = error {
                print("Error authenticating anonymously: \(error)")
                return
            }
        }
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        showMainScreen()
    }
        
    func showMainScreen() {
        DispatchQueue.main.async { [weak self] in
            guard let navigationController = self?.navigationController else { return }
            let diaryListVC = DiaryListVC()
            diaryListVC.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(diaryListVC, animated: true)
        }
    }
}