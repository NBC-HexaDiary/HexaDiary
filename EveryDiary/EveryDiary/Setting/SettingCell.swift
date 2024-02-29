//
//  SettingCell.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/28/24.
//

import UIKit

import SnapKit

class SettingCell: UITableViewCell {
    
    lazy var iconImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.borderColor = UIColor(named: "mainTheme")?.cgColor
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy var titleLabel : UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFProRounded-Regular", size: 20)
        label.textColor = .mainTheme
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var rightArrowImage : UIImageView = {
        let arrowView = UIImageView()
        arrowView.image = UIImage(systemName: "chevron.right")
        arrowView.tintColor = .mainTheme
        return arrowView
    }()
    
    
//    override func layoutSubviews() {
//        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 0, left: 5, bottom: 5, right: 0))
//    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: "SettingCell")
        
        selectionStyle = .none
        contentView.layer.cornerRadius = 10
        addSubViewSettingCell()
        autoLayoutSettingCell()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubViewSettingCell() {
        addSubview(titleLabel)
        addSubview(iconImageView)
        addSubview(rightArrowImage)
    }
    
    private func autoLayoutSettingCell() {
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(rightArrowImage.snp.leading).inset(8)
            make.height.equalTo(30)
        }
        rightArrowImage.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            contentView.layer.borderWidth = 2
            contentView.layer.borderColor = UIColor(named: "mainTheme")?.cgColor
        } else {
            contentView.layer.borderWidth = 1
            contentView.layer.borderColor = UIColor(named: "subBackground")?.cgColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 16, left: 4, bottom: 16, right: 4))
    }

}
