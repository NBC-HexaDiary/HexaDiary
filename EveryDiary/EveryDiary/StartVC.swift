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
        
        addSubViewsStartVC()
        constraintsStartVC()
    }
    
    private lazy var backgroundImage : UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "View.Background2")
        return image
    }()
    
    lazy var startButton : UIButton = {
        var config = UIButton.Configuration.plain()
        let button = UIButton(configuration: config)
        button.setTitle("일기쓰기", for: .normal)
        button.backgroundColor = .clear
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
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
    
    private func addSubViewsStartVC() {
        if !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
            view.addSubview(startButton)
        } else {
            showMainScreen()
        }
        view.addSubview(backgroundImage)
        view.sendSubviewToBack(backgroundImage)
    }
    
    private func constraintsStartVC(){
        startButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        backgroundImage.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
    }
    
    func showMainScreen() {
        DispatchQueue.main.async { [weak self] in
            guard let navigationController = self?.navigationController else { return }
            let diaryListVC = TabBarController()
            diaryListVC.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(diaryListVC, animated: true)
            
            // Dismiss StartVC
            self?.dismiss(animated: true, completion: nil)
        }
    }
}
