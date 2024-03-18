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
    
    lazy var alarmSwtich : UISwitch = {
        let alarmSwitch = UISwitch()
        alarmSwitch.onTintColor = .mainTheme
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
    
    func prepare(title: String, iconImage: String, switchStatus: Bool) {
        self.iconImageView.image = UIImage(named: iconImage)
        self.titleLabel.text = title
        self.alarmSwtich.isOn = switchStatus
    }
}
