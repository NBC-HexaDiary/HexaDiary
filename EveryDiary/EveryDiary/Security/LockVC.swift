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
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        return switchControl
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "생체 인식 잠금"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
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
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(350)
            make.height.equalTo(80)
        }
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }

        biometricsSwitch.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)

        let isEnabled = UserDefaults.standard.bool(forKey: "BiometricsEnabled")
        biometricsSwitch.isOn = isEnabled
        
        // If biometrics is enabled, request Face ID authentication immediately
        if isEnabled {
            requestFaceIDAuthentication()
        }
    }

    @objc private func switchValueChanged(_ sender: UISwitch) {
        let isEnabled = sender.isOn
        UserDefaults.standard.set(isEnabled, forKey: "BiometricsEnabled")
        
        // If biometrics is enabled, request Face ID authentication
        if isEnabled {
            requestFaceIDAuthentication()
        }
    }
    
    private func requestFaceIDAuthentication() {
        biometricsAuth.authenticateWithBiometrics { [weak self] success in
            guard let self = self else { return }
            if success {
                print("인증 성공")
            } else {
                print("인증 실패")
            }
        }
    }
}
