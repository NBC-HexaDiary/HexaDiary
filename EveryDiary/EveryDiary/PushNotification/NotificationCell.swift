//
//  NotificationCell.swift
//  EveryDiary
//
//  Created by eunsung ko on 3/14/24.
//

import UIKit

import SnapKit

class NotificationCell: UITableViewCell {
    static let id = "NotificationCell"
    
    var switchValueChanged: ((Bool) -> Void)?
    
    private lazy var iconImageView : UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    private lazy var titleLabel : UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFProRounded-Regular", size: 20)
        label.textColor = .mainTheme
        return label
    }()
    
    private lazy var alarmSwtich : UISwitch = {
        let alarmSwitch = UISwitch()
        alarmSwitch.onTintColor = .mainTheme
        alarmSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        return alarmSwitch
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: NotificationCell.id)
        
        selectionStyle = .none
        contentView.layer.backgroundColor = UIColor(named: "mainCell")?.cgColor
        addSubViewNotificationCell()
        autoLayoutNotificationCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func addSubViewNotificationCell() {
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(alarmSwtich)
    }
    
    private func autoLayoutNotificationCell() {
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(25)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(alarmSwtich.snp.leading).inset(16)
            make.height.equalTo(30)
        }
        alarmSwtich.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }
    
    @objc func switchChanged(_ sender: UISwitch) {
        // 스위치 상태 변경을 바로 적용하지 않고, 권한 요청 과정을 거칩니다.
        // 권한 상태를 확인하고, 필요한 경우 권한을 요청합니다.
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .authorized {
                    // 권한이 이미 승인된 경우, 스위치 상태를 변경합니다.
                    self.switchValueChanged?(sender.isOn)
                } else if settings.authorizationStatus == .denied {
                    // 권한이 거부된 경우, 설정으로 유도합니다.
                    self.redirectToSettings()
                    // 스위치 상태를 원래대로 되돌립니다.
                    sender.setOn(false, animated: true)
                } else {
                    // 권한이 아직 요청되지 않은 경우, 권한을 요청합니다.
                    self.requestNotificationPermission { granted in
                        if granted {
                            // 권한 요청이 승인된 경우
                            self.switchValueChanged?(sender.isOn)
                        } else {
                            // 권한 요청이 거부된 경우
                            sender.setOn(false, animated: true)
                        }
                    }
                }
            }
        }
    }
    
    // NotificationVC 또는 NotificationCell 내부
    private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    private func redirectToSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }
        UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
    }
    
    func prepare(title: String, iconImage: String, switchStatus: Bool) {
        self.iconImageView.image = UIImage(named: iconImage)
        self.titleLabel.text = title
        self.alarmSwtich.isOn = switchStatus
    }
}
