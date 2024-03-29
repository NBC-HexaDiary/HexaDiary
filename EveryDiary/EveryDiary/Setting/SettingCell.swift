//
//  SettingCell.swift
//  EveryDiary
//
//  Created by t2023-m0044 on 2/28/24.
//

import UIKit

import SnapKit

class SettingCell: UITableViewCell {
    static let id = "SettingCell"

    private lazy var iconImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var titleLabel : UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFProRounded-Regular", size: 20)
        label.textColor = .mainTheme
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: SettingCell.id)
        
        selectionStyle = .none
        contentView.layer.cornerRadius = 10
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowColor = UIColor(named: "mainTheme")?.cgColor
        contentView.layer.shadowRadius = 3
        contentView.layer.shadowOffset = CGSize(width: 0, height: 0)
        contentView.layer.backgroundColor = UIColor(named: "mainCell")?.cgColor
        addSubViewSettingCell()
        autoLayoutSettingCell()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubViewSettingCell() {
        addSubview(titleLabel)
        addSubview(iconImageView)
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
            make.trailing.equalToSuperview().inset(8)
            make.height.equalTo(30)
        }
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            contentView.layer.backgroundColor = UIColor(named: "subTheme")?.cgColor
        } else {
            contentView.layer.backgroundColor = UIColor(named: "mainCell")?.cgColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 7, left: 4, bottom: 7, right: 4))
    }
    
    func prepare(title: String, iconImage: String) {
        self.titleLabel.text = title
        self.iconImageView.image = UIImage(named: iconImage)
    }
}
