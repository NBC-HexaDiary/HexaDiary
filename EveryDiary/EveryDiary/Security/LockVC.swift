//
//  LockVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/28/24.
//

import UIKit

import SnapKit

#Preview{
    LockVC()
}

class LockVC: UIViewController {
    private let biometricsSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.onTintColor = .mainTheme
        return switchControl
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "생체 인식 잠금"
        label.font = UIFont(name: "SFProRounded-Regular", size: 20)
        label.textColor = .mainTheme
        return label
    }()
    
    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        return view
    }()
    
    private let biometricsAuth = BiometricsAuth()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .mainBackground
        
        view.addSubview(backgroundView)
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(biometricsSwitch)
        
        backgroundView.addSubview(stackView)
        
        backgroundView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.width.equalTo(350)
            make.height.equalTo(55)
        }
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }

        biometricsSwitch.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)

        let isEnabled = UserDefaults.standard.bool(forKey: "BiometricsEnabled")
        biometricsSwitch.isOn = isEnabled
    }

    @objc private func switchValueChanged(_ sender: UISwitch) {
        let isEnabled = sender.isOn
        UserDefaults.standard.set(isEnabled, forKey: "BiometricsEnabled")
        
        if isEnabled {
            requestFaceIDAuthentication()
        }
    }
    
    private func requestFaceIDAuthentication() {
        biometricsAuth.authenticateWithBiometrics { [weak self] success in
            guard self != nil else { return }
            if success {
                print("인증 성공")
            } else {
                print("인증 실패")
            }
        }
    }
}
