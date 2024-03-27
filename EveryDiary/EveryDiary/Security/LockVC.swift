//
//  LockVC.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/28/24.
//
import LocalAuthentication
import UIKit

import SnapKit

class LockVC: UIViewController {
    private let biometricsSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.onTintColor = .mainTheme
        return switchControl
    }()
    
    private let iconImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "lock")
        imageView.contentMode = .scaleAspectFit
        return imageView
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
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let biometricsAuth = BiometricsAuth()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .mainBackground
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(backgroundView)
        
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(biometricsSwitch)
        
        backgroundView.addSubview(stackView)
        
        backgroundView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.height.equalTo(50)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(25)
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
            checkBiometryAvailability()
        }
    }
    
    private func checkBiometryAvailability() {
        biometricsAuth.authenticateWithBiometrics { [weak self] success, error in
            guard let self = self else { return }
            if success {
                print("인증 성공")
            } else {
                print("인증 실패")
                if let error = error as? LAError, error.code == .biometryNotAvailable {
                    self.showPermissionDeniedAlert()
                } else {
                    print("페이스 아이디 권한이 비활성화되어 있습니다. 설정으로 이동하여 활성화해주세요.")
                    self.showPermissionDeniedAlert()
                }
            }
        }
    }
    
    private func showPermissionDeniedAlert() {
        let authorizationAlert = UIAlertController(title: "Face ID 권한 거부", message: "Face ID 권한을 사용하려면 설정에서 Face ID 권한을 허용해주세요", preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "설정으로 이동", style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .default, handler: nil)
        
        authorizationAlert.addAction(settingsAction)
        authorizationAlert.addAction(cancelAction)
        
        DispatchQueue.main.async { [weak self] in
            self?.present(authorizationAlert, animated: true, completion: nil)
        }
    }
}
