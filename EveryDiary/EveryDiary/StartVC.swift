//
//  StartVC.swift
//  EveryDiary
//
//  Created by Dahlia on 3/13/24.
//

import UIKit

import FirebaseAuth
import SnapKit
import Lottie

class StartVC: UIViewController {
    
    private lazy var animationView: LottieAnimationView = {
        let config = LottieConfiguration(renderingEngine: .automatic)
        let view = LottieAnimationView(name: "calendar", configuration: config)
        view.contentMode = .scaleAspectFill
        view.loopMode = .playOnce
        view.animationSpeed = 0.5
        view.play(fromFrame: 1, toFrame: 90)
        return view
    }()
    
    private lazy var startLabel : UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFProRounded-Regular", size: 25)
        label.textColor = .mainTheme
        let fullText = "하루의 이야기를 기록해보아요"
        let changeText = "이야기"
        let attributedString = NSMutableAttributedString(string: fullText)
        if let range = fullText.range(of: changeText) {
            let nsRange = NSRange(range, in: fullText)
            attributedString.addAttribute(.foregroundColor, value: UIColor(named: "storyText") ?? UIColor.black, range: nsRange)
            attributedString.addAttribute(.font, value: UIFont(name: "SFProRounded-Bold", size: 28) ?? UIFont.systemFont(ofSize: 28), range: nsRange)
        }
        label.attributedText = attributedString
        label.textAlignment = .center
        return label
    }()
    
    private lazy var startButton : UIButton = {
        let button = UIButton()
        button.setTitle("시작하기", for: .normal)
        button.layer.backgroundColor = UIColor(named: "loginBackground")?.cgColor
        button.setTitleColor(.mainCell, for: .normal)
        button.layer.cornerRadius = 10
        button.layer.shadowOpacity = 0.1
        button.layer.shadowColor = UIColor(named: "mainTheme")?.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 0)
        button.layer.shadowRadius = 3
        button.addTarget(self, action: #selector(startButtonTouchOutside), for: .touchUpInside)
        button.addTarget(self, action: #selector(startButtonTouchDown), for: .touchDown)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .mainCell

        addSubViewsStartVC()
        autoLayoutStartVC()
    }
    
    @objc private func startButtonTouchOutside() {
        startButton.layer.backgroundColor = UIColor(named: "loginBackground")?.cgColor
        DiaryManager.shared.authenticateAnonymouslyIfNeeded { error in
            if let error = error {
                print("Error authenticating anonymously: \(error)")
                return
            }
        }
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        showMainScreen()
    }
    
    @objc private func startButtonTouchDown() {
        startButton.layer.backgroundColor = UIColor(named: "subBackground")?.cgColor

    }
    
    private func addSubViewsStartVC() {
        if !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
            view.addSubview(startButton)
            view.addSubview(animationView)
            view.addSubview(startLabel)
        } else {
            showMainScreen()
        }
    }
    
    private func autoLayoutStartVC(){
        startButton.snp.makeConstraints { make in
            make.centerX.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.width.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.height.equalTo(50)
        }
        animationView.snp.makeConstraints { make in
            make.centerX.equalTo(view.safeAreaLayoutGuide)
            make.centerY.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.height.width.equalTo(300)
        }
        startLabel.snp.makeConstraints { make in
            make.centerX.equalTo(view.safeAreaLayoutGuide)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.height.equalTo(50)
            make.width.equalTo(view.safeAreaLayoutGuide).offset(-40)
        }
    }
    
    private func showMainScreen() {
        // Dismiss StartVC
        self.dismiss(animated: true, completion: nil)
    }
}
